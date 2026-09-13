import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Device-specific biometric kind for standard OS presentation
enum BiometricDeviceKind {
  faceId,       // iOS Face ID
  touchId,      // iOS Touch ID
  fingerprint,  // Android Fingerprint
  faceUnlock,   // Android Face Unlock
  generic,      // Other platform / standard biometric
  none,
}

/// Rich device biometric metadata for UI rendering
class DeviceBiometricInfo {
  final BiometricDeviceKind kind;
  final String label;          // e.g. "Face ID", "Touch ID", "Fingerprint"
  final String buttonText;     // e.g. "Unlock with Face ID", "Unlock with Fingerprint"
  final String promptReason;   // Localized OS reason string
  final IconData icon;         // Face or Fingerprint icon
  final bool isSupported;      // Hardware capability
  final bool isEnrolled;       // Enrolled in OS settings
  final bool isEnabledByUser;  // User opted-in preference

  const DeviceBiometricInfo({
    required this.kind,
    required this.label,
    required this.buttonText,
    required this.promptReason,
    required this.icon,
    required this.isSupported,
    required this.isEnrolled,
    required this.isEnabledByUser,
  });
}

/// Service that manages device-local PIN security and biometric authentication.
/// PIN is NEVER stored in plain text — always SHA-256 hashed with a unique salt.
class AuthService {
  static const String _pinKey = 'ck_pin_hash_v1';
  static const String _biometricEnabledKey = 'ck_biometric_enabled_v1';
  static const String _salt = 'cartkaro_partner_hub_secure_2024';

  static final LocalAuthentication _localAuth = LocalAuthentication();

  // ─── PIN Hashing ────────────────────────────────────────────────

  static String _hashPin(String pin) {
    final saltedPin = '$_salt:$pin';
    final bytes = utf8.encode(saltedPin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ─── PIN Storage & Cloud Sync ───────────────────────────────────

  /// Save a new 4-digit PIN (stored as SHA-256 hash locally and synced to Firestore).
  static Future<void> savePin(
    String pin, {
    String? uid,
    bool? isBiometricEnabled,
  }) async {
    final hashed = _hashPin(pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, hashed);

    // Sync to Firestore under partners/{uid} so PIN survives app reinstallation
    final targetUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (targetUid != null && targetUid.isNotEmpty) {
      try {
        final Map<String, dynamic> updateData = {
          'pinHash': hashed,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (isBiometricEnabled != null) {
          updateData['isBiometricEnabled'] = isBiometricEnabled;
          await prefs.setBool(_biometricEnabledKey, isBiometricEnabled);
        }
        final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
        if (phone != null && phone.isNotEmpty) {
          updateData['phoneNumber'] = phone;
        }

        await FirebaseFirestore.instance
            .collection('partners')
            .doc(targetUid)
            .set(updateData, SetOptions(merge: true));
      } catch (e) {
        debugPrint('⚠️ Error syncing PIN to Firestore: $e');
      }
    }
  }

  /// Syncs user PIN & biometric preferences from Firestore down to this device.
  /// Returns true if a valid PIN hash was recovered from cloud.
  static Future<bool> syncFromCloud(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (!doc.exists || doc.data() == null) {
        return false;
      }

      final data = doc.data()!;
      final cloudPinHash = data['pinHash'] as String?;
      final cloudBioEnabled = data['isBiometricEnabled'] as bool?;

      if (cloudPinHash != null && cloudPinHash.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_pinKey, cloudPinHash);
        if (cloudBioEnabled != null) {
          await prefs.setBool(_biometricEnabledKey, cloudBioEnabled);
        }
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing partner security profile from cloud: $e');
    }
    return false;
  }

  /// Verify entered PIN against stored hash. Returns true if correct.
  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  /// Check if a PIN has been set on this device.
  static Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  /// Remove the stored PIN (used on logout or app reset).
  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_businessIdKey);
    await prefs.remove(_ownerNameKey);
    await prefs.remove(_businessTypeKey);
  }

  // ─── Business Session Caching ──────────────────────────────────
  static const String _businessIdKey = 'ck_active_business_id';
  static const String _ownerNameKey = 'ck_owner_name';
  static const String _businessTypeKey = 'ck_business_type';

  static Future<void> saveActiveBusinessId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_businessIdKey, id);
  }

  static Future<String?> getActiveBusinessId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_businessIdKey);
  }

  static Future<void> saveOwnerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownerNameKey, name);
  }

  static Future<String?> getOwnerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ownerNameKey);
  }

  static Future<void> saveBusinessType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_businessTypeKey, type);
  }

  static Future<String?> getBusinessType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_businessTypeKey);
  }

  // ─── User Preference: Biometric Opt-in ─────────────────────────

  /// Check if the user has enabled biometric sign-in (defaults to true).
  static Future<bool> isBiometricEnabledByUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? true;
  }

  /// Save the user's preference for biometric sign-in (locally and in Firestore).
  static Future<void> setBiometricEnabled(bool enabled, {String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);

    final targetUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (targetUid != null && targetUid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('partners').doc(targetUid).set({
          'isBiometricEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('⚠️ Error saving biometric preference to Firestore: $e');
      }
    }
  }

  // ─── Device-Specific Biometric Detection ───────────────────────

  /// Accurately detects user device and hardware to adapt UI standard (Face ID vs Fingerprint)
  static Future<DeviceBiometricInfo> getDeviceBiometricInfo() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      final isEnrolled = available.isNotEmpty;
      final isEnabledByUser = await isBiometricEnabledByUser();

      final bool hasFace = available.contains(BiometricType.face);
      final bool hasFingerprint = available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.strong);

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS device: iPhone X+ has Face ID; iPhone SE / iPads have Touch ID
        if (hasFace || (!hasFingerprint && (isSupported || canCheck))) {
          return DeviceBiometricInfo(
            kind: BiometricDeviceKind.faceId,
            label: 'Face ID',
            buttonText: 'Unlock with Face ID',
            promptReason: 'Scan Face ID to access CartKaro Partner Hub',
            icon: Icons.face_rounded,
            isSupported: isSupported || canCheck,
            isEnrolled: isEnrolled,
            isEnabledByUser: isEnabledByUser,
          );
        } else {
          return DeviceBiometricInfo(
            kind: BiometricDeviceKind.touchId,
            label: 'Touch ID',
            buttonText: 'Unlock with Touch ID',
            promptReason: 'Scan Touch ID to access CartKaro Partner Hub',
            icon: Icons.fingerprint_rounded,
            isSupported: isSupported || canCheck,
            isEnrolled: isEnrolled,
            isEnabledByUser: isEnabledByUser,
          );
        }
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android device: Pixel/Samsung with Fingerprint or Face Unlock
        if (hasFace && !hasFingerprint) {
          return DeviceBiometricInfo(
            kind: BiometricDeviceKind.faceUnlock,
            label: 'Face Unlock',
            buttonText: 'Unlock with Face',
            promptReason: 'Scan face to access CartKaro Partner Hub',
            icon: Icons.face_rounded,
            isSupported: isSupported || canCheck,
            isEnrolled: isEnrolled,
            isEnabledByUser: isEnabledByUser,
          );
        } else {
          return DeviceBiometricInfo(
            kind: BiometricDeviceKind.fingerprint,
            label: 'Fingerprint',
            buttonText: 'Unlock with Fingerprint',
            promptReason: 'Scan fingerprint to access CartKaro Partner Hub',
            icon: Icons.fingerprint_rounded,
            isSupported: isSupported || canCheck,
            isEnrolled: isEnrolled,
            isEnabledByUser: isEnabledByUser,
          );
        }
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        return DeviceBiometricInfo(
          kind: BiometricDeviceKind.touchId,
          label: 'Touch ID',
          buttonText: 'Unlock with Touch ID',
          promptReason: 'Use Touch ID to access CartKaro Partner Hub',
          icon: Icons.fingerprint_rounded,
          isSupported: isSupported || canCheck,
          isEnrolled: isEnrolled,
          isEnabledByUser: isEnabledByUser,
        );
      } else {
        return DeviceBiometricInfo(
          kind: BiometricDeviceKind.generic,
          label: 'Biometric',
          buttonText: 'Unlock with Biometric',
          promptReason: 'Verify identity to access CartKaro Partner Hub',
          icon: Icons.fingerprint_rounded,
          isSupported: isSupported || canCheck,
          isEnrolled: isEnrolled,
          isEnabledByUser: isEnabledByUser,
        );
      }
    } catch (_) {
      final isIos = defaultTargetPlatform == TargetPlatform.iOS;
      return DeviceBiometricInfo(
        kind: isIos ? BiometricDeviceKind.faceId : BiometricDeviceKind.fingerprint,
        label: isIos ? 'Face ID' : 'Fingerprint',
        buttonText: isIos ? 'Unlock with Face ID' : 'Unlock with Fingerprint',
        promptReason: 'Authenticate to access CartKaro Partner Hub',
        icon: isIos ? Icons.face_rounded : Icons.fingerprint_rounded,
        isSupported: true,
        isEnrolled: false,
        isEnabledByUser: true,
      );
    }
  }

  // ─── Legacy compatibility helpers ──────────────────────────────

  static Future<bool> isBiometricSupported() async {
    final info = await getDeviceBiometricInfo();
    return info.isSupported;
  }

  static Future<bool> isBiometricEnrolled() async {
    final info = await getDeviceBiometricInfo();
    return info.isEnrolled;
  }

  static Future<bool> isBiometricAvailable() async => true;

  static Future<BiometricType?> getAvailableBiometric() async {
    try {
      final list = await _localAuth.getAvailableBiometrics();
      if (list.contains(BiometricType.face)) return BiometricType.face;
      if (list.contains(BiometricType.fingerprint)) return BiometricType.fingerprint;
      if (list.contains(BiometricType.strong)) return BiometricType.strong;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Biometric Execution ────────────────────────────────────────

  /// Prompt the user for biometric authentication with structured result.
  static Future<BiometricAuthResult> authenticateWithBiometricsDetailed({String? customReason}) async {
    try {
      final info = await getDeviceBiometricInfo();
      final reason = customReason ?? info.promptReason;

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return BiometricAuthResult(success: authenticated);
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') {
        return const BiometricAuthResult(
          success: false,
          isNotEnrolled: true,
          errorMessage: 'No biometric enrolled on this device. Please set up in Settings.',
        );
      } else if (e.code == 'PasscodeNotSet') {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'Device passcode or screen lock is not set.',
        );
      } else if (e.code == 'NotAvailable') {
        return const BiometricAuthResult(
          success: false,
          isNotAvailable: true,
          errorMessage: 'Biometric hardware is not available on this device.',
        );
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'Biometric locked due to too many attempts. Please use your PIN.',
        );
      }
      return BiometricAuthResult(
        success: false,
        errorMessage: e.message ?? 'Biometric authentication cancelled.',
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Biometric authentication error: $e',
      );
    }
  }

  /// Simple boolean wrapper
  static Future<bool> authenticateWithBiometric({String? customReason}) async {
    final result = await authenticateWithBiometricsDetailed(customReason: customReason);
    return result.success;
  }
}

class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final bool isNotEnrolled;
  final bool isNotAvailable;

  const BiometricAuthResult({
    required this.success,
    this.errorMessage,
    this.isNotEnrolled = false,
    this.isNotAvailable = false,
  });
}
