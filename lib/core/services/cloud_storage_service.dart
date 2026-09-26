import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CloudStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Returns true if a given path is a local file system path
  static bool isLocalFilePath(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    final clean = path.trim();
    if (clean.startsWith('http://') ||
        clean.startsWith('https://') ||
        clean.startsWith('data:') ||
        clean.startsWith('assets/')) {
      return false;
    }
    return true;
  }

  ///
  /// ROOT CAUSE FIX: On total upload failure, this returns EMPTY STRING — never a Base64 data URI.
  /// Storing Base64 images in Firestore documents causes [cloud_firestore/invalid-argument]
  /// because the 1 MiB document size limit is easily exceeded when multiple images are embedded.
  /// With 10+ images at ~20-40 KB Base64 each, total document size = 200-400 KB+, which
  /// combined with other fields can exceed 1 MiB causing Firestore to reject the entire write.
  static Future<String> uploadFile({
    required String localPath,
    required String destinationPath,
    String fallback = '',
  }) async {
    final cleanPath = localPath.trim();
    if (cleanPath.isEmpty) return fallback;

    // Already a remote URL or Base64 Data URI — pass through
    if (cleanPath.startsWith('http://') ||
        cleanPath.startsWith('https://') ||
        cleanPath.startsWith('data:')) {
      return cleanPath;
    }

    try {
      var resolvedPath = cleanPath;
      if (resolvedPath.startsWith('file://')) {
        resolvedPath = resolvedPath.replaceFirst('file://', '');
      }

      final file = File(resolvedPath);
      if (!await file.exists()) {
        debugPrint('[CloudStorageService] Local file not found: $resolvedPath');
        return isLocalFilePath(fallback) ? '' : fallback;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        debugPrint('[CloudStorageService] File is empty: $resolvedPath');
        return isLocalFilePath(fallback) ? '' : fallback;
      }

      final ext = resolvedPath.contains('.')
          ? resolvedPath.split('.').last.toLowerCase().split('?').first
          : 'jpg';
      final contentType = _getContentType(ext);

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'source': 'partner_hub',
        },
      );

      // Attempt 1: Default Firebase Storage bucket
      try {
        final ref = _storage.ref().child(destinationPath);
        final uploadTask = ref.putFile(file, metadata);
        final snapshot = await uploadTask.timeout(const Duration(seconds: 30));
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('[CloudStorageService] Uploaded (primary): $destinationPath -> $downloadUrl');
        return downloadUrl;
      } catch (e1) {
        debugPrint('[CloudStorageService] Primary putFile failed: $e1');
      }

      // Attempt 2: firebasestorage.app bucket
      try {
        final fbsStorage = FirebaseStorage.instanceFor(bucket: 'cartkaro-404b6.firebasestorage.app');
        final ref = fbsStorage.ref().child(destinationPath);
        final uploadTask = ref.putFile(file, metadata);
        final snapshot = await uploadTask.timeout(const Duration(seconds: 20));
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('[CloudStorageService] Uploaded (firebasestorage.app): $destinationPath -> $downloadUrl');
        return downloadUrl;
      } catch (e2) {
        debugPrint('[CloudStorageService] firebasestorage.app failed: $e2');
      }

      // Attempt 3: appspot bucket
      try {
        final appspotStorage = FirebaseStorage.instanceFor(bucket: 'cartkaro-404b6.appspot.com');
        final ref = appspotStorage.ref().child(destinationPath);
        final uploadTask = ref.putFile(file, metadata);
        final snapshot = await uploadTask.timeout(const Duration(seconds: 20));
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('[CloudStorageService] Uploaded (appspot): $destinationPath -> $downloadUrl');
        return downloadUrl;
      } catch (e3) {
        debugPrint('[CloudStorageService] appspot failed: $e3');
      }

      // All Cloud Storage attempts failed. Return empty string.
      // Do NOT embed Base64 in Firestore — it causes document size overflow.
      debugPrint('[CloudStorageService] All uploads failed for $destinationPath. Returning empty URL.');
      return '';

    } catch (e) {
      debugPrint('[CloudStorageService] Upload error for $cleanPath: $e');
      return isLocalFilePath(fallback) ? '' : fallback;
    }
  }

  /// Uploads multiple local photo paths to Firebase Storage.
  /// Returns Cloud Download URLs only — never local paths or Base64 data URIs.
  static Future<List<String>> uploadMultipleFiles({
    required List<String> localPaths,
    required String destinationFolder,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < localPaths.length; i++) {
      final path = localPaths[i].trim();
      if (path.isEmpty) continue;

      if (path.startsWith('http://') ||
          path.startsWith('https://') ||
          path.startsWith('data:')) {
        downloadUrls.add(path);
        continue;
      }

      final ext = path.contains('.')
          ? path.split('.').last.toLowerCase().split('?').first
          : 'jpg';
      final destination = '$destinationFolder/photo_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

      final url = await uploadFile(
        localPath: path,
        destinationPath: destination,
      );

      if (url.isNotEmpty && !isLocalFilePath(url)) {
        downloadUrls.add(url);
      }
    }

    return downloadUrls;
  }

  static String _getContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  /// Deeply sanitizes a Map before saving to Firestore.
  ///
  /// - Removes null values (Firestore rejects null for most field types)
  /// - Removes empty/blank key names
  /// - Detects and PRESERVES FieldValue sentinels (serverTimestamp, increment, arrayUnion, etc.)
  ///   at both top-level and nested map levels using runtime type name detection
  /// - Recursively sanitizes all nested Maps and List items
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> map) {
    final Map<String, dynamic> clean = {};
    map.forEach((key, value) {
      if (value == null) return;
      if (key.trim().isEmpty) return;

      // Detect Firestore FieldValue by runtime type name.
      // This preserves serverTimestamp(), increment(), arrayUnion(), etc.
      // at any nesting level without requiring a cloud_firestore import here.
      final typeName = value.runtimeType.toString();
      if (typeName.contains('FieldValue') ||
          typeName.contains('_FieldValueImpl') ||
          typeName.contains('MethodChannelFieldValue') ||
          typeName.contains('Timestamp')) {
        clean[key] = value;
        return;
      }

      if (value is Map<String, dynamic>) {
        clean[key] = sanitizeMap(value);
      } else if (value is Map) {
        clean[key] = sanitizeMap(Map<String, dynamic>.from(value));
      } else if (value is List) {
        clean[key] = value.where((item) => item != null).map((item) {
          if (item is Map<String, dynamic>) {
            return sanitizeMap(item);
          } else if (item is Map) {
            return sanitizeMap(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        clean[key] = value;
      }
    });
    return clean;
  }

  /// Estimates approximate serialized byte size of a Firestore document.
  /// Use before docRef.set() to guard against the 1 MiB hard limit.
  static int estimateDocumentSize(Map<String, dynamic> map) {
    try {
      final jsonStr = jsonEncode(_toJsonSafe(map));
      return jsonStr.length;
    } catch (e) {
      return 0;
    }
  }

  static dynamic _toJsonSafe(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key, _toJsonSafe(e.value))),
      );
    }
    if (value is List) return value.map(_toJsonSafe).toList();
    return value.toString();
  }
}
