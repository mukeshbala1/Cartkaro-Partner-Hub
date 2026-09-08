// ============================================================
// CartKaro Partner Hub — Medical / Pharmacy Registration Screen
// File: medical_registration_screen.dart
// Theme: Single Brand Navy Blue (#152744) - No Green
// Features: Real GPS, Real Image/File Picker, No Jelly Effect
// FIXES: Submit→Step9 fixed, 24-48hr loading, Account match,
//        IFSC validation, GPS locationSettings fix
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dashboard/screens/dashboard_layout.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────
// THEME CONSTANTS (Green removed, unified Blue theme)
// ─────────────────────────────────────────
const Color kNavyBlue       = Color(0xFF152744);
const Color kNavyBlueDark   = Color(0xFF0D1B30);
const Color kNavyBlueLight  = Color(0xFF1E3A5F);
const Color kBlueAccent     = Color(0xFFE8EEF5);
const Color kWhite          = Color(0xFFFFFFFF);
const Color kOffWhite       = Color(0xFFF8F9FA);
const Color kCardBg         = Color(0xFFFFFFFF);
const Color kBorderColor    = Color(0xFFE0E6F0);
const Color kTextPrimary    = Color(0xFF0D1B30);
const Color kTextSecondary  = Color(0xFF6B7A99);
const Color kTextHint       = Color(0xFFB0BAD0);
const Color kErrorColor     = Color(0xFFE53935);
const Color kSuccessColor   = Color(0xFF43A047);
const Color kWarningColor   = Color(0xFFFFA000);
const Color kDivider        = Color(0xFFEEF2F8);


// ─────────────────────────────────────────
// ENTRY POINT — MAIN SCREEN
// ─────────────────────────────────────────
class MedicalRegistrationScreen extends StatefulWidget {
  final String prefilledMobile;

  const MedicalRegistrationScreen({
    Key? key,
    this.prefilledMobile = '9876543210',
  }) : super(key: key);

  @override
  State<MedicalRegistrationScreen> createState() =>
      _MedicalRegistrationScreenState();
}

class _MedicalRegistrationScreenState
    extends State<MedicalRegistrationScreen> {
  int _currentStep = 0;
  final PageController _pageController =
      PageController(initialPage: 0, keepPage: true);

  final List<GlobalKey<FormState>> _formKeys =
      List.generate(9, (_) => GlobalKey<FormState>());

  String? _savedBusinessId;

  // ── Step 1 ──
  final _ownerNameCtrl   = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _altMobileCtrl   = TextEditingController();
  String _profilePhotoPath = '';
  String _altCountryCode   = '+91';

  // ── Step 2 ──
  final _medicalNameCtrl    = TextEditingController();
  final _medicalAddressCtrl = TextEditingController();
  final _cityCtrl           = TextEditingController();
  final _stateCtrl          = TextEditingController();
  final _pincodeCtrl        = TextEditingController();
  final _latCtrl            = TextEditingController();
  final _lngCtrl            = TextEditingController();
  String _medicalLogo   = '';
  String _medicalBanner = '';
  List<String> _medicalPhotos = [];

  // ── Step 3 ──
  final Set<String> _selectedCategories = {};

  // ── Step 4 ──
  TimeOfDay _openingTime  = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closingTime  = const TimeOfDay(hour: 22, minute: 0);
  final Set<String> _workingDays = {
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  };
  bool _acceptOnlineOrders  = true;
  bool _is24HoursOpen       = false;
  bool _isEmergencyMedicine = false;

  // ── Step 5 ──
  final _drugLicenseCtrl       = TextEditingController();
  final _pharmacistRegCtrl     = TextEditingController();
  final _gstNumberCtrl         = TextEditingController();
  final _tradeLicenseCtrl      = TextEditingController();
  final _panCtrl               = TextEditingController();
  final _aadhaarCtrl           = TextEditingController();
  String _drugLicenseCertPath  = '';
  String _pharmacistCertPath   = '';
  String _gstCertPath          = '';
  String _panDocPath           = '';
  String _aadhaarDocPath       = '';


  // ── Step 6 ──
  final _accountHolderCtrl  = TextEditingController();
  final _accountNumberCtrl  = TextEditingController();
  final _confirmAccountCtrl = TextEditingController();
  final _ifscCtrl           = TextEditingController();
  final _upiCtrl            = TextEditingController();
  String _selectedBank        = '';
  String _cancelledChequePath = '';

  // ── Step 7 ──
  String _deliveryOption        = 'cartkaro';
  bool _isPrescriptionRequired  = false;
  bool _isSameDayDelivery       = true;
  bool _isEmergencyDelivery     = false;

  // ── Step 8 ──
  bool _agreementAccepted = false;

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      _ownerNameCtrl, _emailCtrl, _passwordCtrl, _confirmPassCtrl,
      _altMobileCtrl, _medicalNameCtrl, _medicalAddressCtrl,
      _cityCtrl, _stateCtrl, _pincodeCtrl, _latCtrl, _lngCtrl,
      _drugLicenseCtrl, _pharmacistRegCtrl, _gstNumberCtrl,
      _tradeLicenseCtrl, _panCtrl, _aadhaarCtrl,
      _accountHolderCtrl, _accountNumberCtrl,
      _confirmAccountCtrl, _ifscCtrl, _upiCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────
  // GPS — locationSettings explicitly pass karo
  // ─────────────────────────────────────────
  Future<void> _fetchRealLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your GPS is disabled, Please enable it.')),
        );
        await Geolocator.openLocationSettings();
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location permission permanently denied. App Settings se enable karo.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: Geolocator.openAppSettings,
              textColor: Colors.white,
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Fatching Your Location.')),
      );
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (!mounted) return;

      setState(() {
        _latCtrl.text = position.latitude.toStringAsFixed(6);
        _lngCtrl.text = position.longitude.toStringAsFixed(6);
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          Placemark place = placemarks.first;
          setState(() {
            _medicalAddressCtrl.text =
                [place.street, place.subLocality, place.locality]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(', ');
            _cityCtrl.text =
                place.locality ?? place.subAdministrativeArea ?? '';
            _stateCtrl.text   = place.administrativeArea ?? '';
            _pincodeCtrl.text = place.postalCode ?? '';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Location and address filled.'),
                backgroundColor: kSuccessColor,
              ),
            );
          }
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location and address not filled.'),
            ),
          );
        }
      }
    } catch (e) {
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _latCtrl.text = lastPos.latitude.toStringAsFixed(6);
          _lngCtrl.text = lastPos.longitude.toStringAsFixed(6);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('We use last known location.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(
      ImageSource source, ValueChanged<String> onPathUpdated) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => onPathUpdated(pickedFile.path));
    }
  }

  Future<void> _pickDocument(ValueChanged<String> onPathUpdated) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => onPathUpdated(result.files.single.path!));
    }
  }
  
  Future<void> _showImagePickerOptions(
  ValueChanged<String> onPathUpdated,
) async {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
              ),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);

                _pickImage(
                  ImageSource.camera,
                  onPathUpdated,
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
              ),
              title: const Text(
                "Choose From Gallery",
              ),
              onTap: () {
                Navigator.pop(context);

                _pickImage(
                  ImageSource.gallery,
                  onPathUpdated,
                );
              },
            ),

          ],
        ),
      );
    },
  );
}
  // ─────────────────────────────────────────
  // NAVIGATION — WidgetsBinding se jumpToPage call karo
  // ─────────────────────────────────────────
  Future<void> _nextStep() async {
    FocusScope.of(context).unfocus();

    final form = _formKeys[_currentStep].currentState;

    if (form != null && !form.validate()) {
      return;
    }

    // Step 0 Profile Photo is no longer mandatory

      // Step 2 GPS Location Mandatory
  if (_currentStep == 1 &&
      (_latCtrl.text.isEmpty || _lngCtrl.text.isEmpty)) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please use current location first",
        ),
        backgroundColor: kErrorColor,
      ),
    );

    return;
  }

  if (_currentStep == 1 && _medicalPhotos.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Please upload at least one medical store photo",
      ),
      backgroundColor: kErrorColor,
    ),
  );
  return;
}

    if (_currentStep == 7 && !_agreementAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please accept the agreement to continue"),
        ),
      );
      return;
    }

    if (_currentStep < 8) {
      final nextPage = _currentStep + 1;

      if (nextPage == 8) {
        // Save to Firestore
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final docRef = FirebaseFirestore.instance.collection('businesses').doc();
            await docRef.set({
              'ownerUid': user.uid,
              'businessType': 'medical',
              'status': 'pending',
              'isLive': false,
              'createdAt': FieldValue.serverTimestamp(),
              'mobile': user.phoneNumber,
              'ownerName': _ownerNameCtrl.text,
              'email': _emailCtrl.text,
              'altMobile': _altMobileCtrl.text,
              'medicalName': _medicalNameCtrl.text,
              'medicalAddress': _medicalAddressCtrl.text,
              'city': _cityCtrl.text,
              'state': _stateCtrl.text,
              'pincode': _pincodeCtrl.text,
              'lat': _latCtrl.text,
              'lng': _lngCtrl.text,
              'categories': _selectedCategories.toList(),
              'openingTime': '${_openingTime.hour}:${_openingTime.minute}',
              'closingTime': '${_closingTime.hour}:${_closingTime.minute}',
              'workingDays': _workingDays.toList(),
              'acceptOnlineOrders': _acceptOnlineOrders,
              'is24HoursOpen': _is24HoursOpen,
              'isEmergencyMedicine': _isEmergencyMedicine,
              'drugLicense': _drugLicenseCtrl.text,
              'pharmacistReg': _pharmacistRegCtrl.text,
              'gstNumber': _gstNumberCtrl.text,
              'tradeLicense': _tradeLicenseCtrl.text,
              'pan': _panCtrl.text,
              'aadhaar': _aadhaarCtrl.text,
              'accountHolder': _accountHolderCtrl.text,
              'accountNumber': _accountNumberCtrl.text,
              'ifsc': _ifscCtrl.text,
              'upi': _upiCtrl.text,
              'bank': _selectedBank,
              'deliveryOption': _deliveryOption,
              'isPrescriptionRequired': _isPrescriptionRequired,
              'isSameDayDelivery': _isSameDayDelivery,
              'isEmergencyDelivery': _isEmergencyDelivery,
            });
            _savedBusinessId = docRef.id;
          }
        } catch (e) {
          debugPrint('Failed to save to Firestore: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to save data. Please check internet connection.")),
          );
          return; // Don't proceed if save failed
        }
      }

      setState(() {
        _currentStep = nextPage;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (nextPage == 8) {
          _pageController.jumpToPage(nextPage);
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: kNavyBlueDark,
      ),
      child: Scaffold(
        backgroundColor: kOffWhite,
        body: ScrollConfiguration(
          behavior:
              ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet  = constraints.maxWidth >= 600;
              final isDesktop = constraints.maxWidth >= 1024;
              final contentWidth = isDesktop
                  ? 720.0
                  : isTablet
                      ? constraints.maxWidth * 0.85
                      : constraints.maxWidth;

              return Column(
                children: [
                  _buildTopBar(context, isTablet),
                  if (_currentStep < 8)
                    _buildProgressBar(
                        constraints.maxWidth, contentWidth, isTablet),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStep1(),
                            _buildStep2(),
                            _buildStep3(),
                            _buildStep4(),
                            _buildStep5(),
                            _buildStep6(),
                            _buildStep7(),
                            _buildStep8(),
                            _MedicalSuccessScreen(businessId: _savedBusinessId),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_currentStep < 8)
                    _buildBottomNav(contentWidth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isTablet) {
    return Container(
      color: kNavyBlueDark,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (_currentStep < 8)
              GestureDetector(
                onTap: _currentStep > 0 ? _prevStep : () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kNavyBlueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: kWhite, size: 18),
                ),
              )
            else
              const SizedBox(width: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Cart',
                          style: TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.w800,
                              fontSize: 18),
                        ),
                        TextSpan(
                          text: 'Karo',
                          style: TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.w400,
                              fontSize: 18),
                        ),
                        TextSpan(
                          text: '  Partner Hub',
                          style: TextStyle(
                              color: Color(0xFF8DA4BF),
                              fontWeight: FontWeight.w400,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (_currentStep < 8)
                    Text(
                      'Step ${_currentStep + 1} of 9  •  ${_stepTitles[_currentStep]}',
                      style: const TextStyle(
                          color: Color(0xFF6B8BAB),
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<String> _stepTitles = [
    'Owner Details',
    'Pharmacy Details',
    'Medical Category',
    'Business Timing',
    'Legal Documents',
    'Bank Details',
    'Delivery Settings',
    'Agreement',
    'Success',
  ];

  Widget _buildProgressBar(
      double screenWidth, double contentWidth, bool isTablet) {
    return Container(
      color: kNavyBlueDark,
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: contentWidth,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: List.generate(8, (i) {
                    final done    = i < _currentStep;
                    final current = i == _currentStep;
                    return Expanded(
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            width: current ? 28 : 16,
                            height: 6,
                            decoration: BoxDecoration(
                              color: done || current ? kWhite : kNavyBlueLight,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          if (i < 7)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: done
                                    ? kWhite.withOpacity(0.5)
                                    : kNavyBlueLight,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          LinearProgressIndicator(
            value: (_currentStep + 1) / 9,
            backgroundColor: kNavyBlueLight,
            valueColor: const AlwaysStoppedAnimation<Color>(kWhite),
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(double contentWidth) {
    final isLastContentStep = _currentStep == 7;
    final canProceed = isLastContentStep ? _agreementAccepted : true;

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    flex: 2,
                    child: _OutlinedNavButton(
                      label: 'Previous',
                      icon: Icons.arrow_back_rounded,
                      onTap: _prevStep,
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _FilledNavButton(
                    label: isLastContentStep
                        ? 'Submit Registration'
                        : 'Continue',
                    icon: isLastContentStep
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward_rounded,
                    enabled: canProceed,
                    onTap: _nextStep,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // STEP 1 — Owner Details (same as grocery)
  // ─────────────────────────────────────────
  Widget _buildStep1() {
    return _StepWrapper(
      stepKey: _formKeys[0],
      title: 'Tell us about yourself',
      subtitle: 'Your account details for CartKaro Partner Hub',
      icon: Icons.person_outline_rounded,
      children: [
        _SectionLabel(label: 'Profile Photo'),
        Center(
          child: _ProfilePhotoUpload(
            path: _profilePhotoPath,
            onTap: () => _pickImage(
              ImageSource.gallery,
              (path) => _profilePhotoPath = path,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionLabel(label: 'Personal Information'),
        CustomTextField(
          controller: _ownerNameCtrl,
          label: 'Owner Full Name',
          hint: 'Enter your legal full name',
          required: true,
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),
        _PrefilledMobileField(mobile: widget.prefilledMobile),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailCtrl,
          label: 'Email Address',
          hint: 'business@example.com',
          required: true,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _SectionLabel(label: 'Alternate Contact'),
        _CountryCodeMobileField(
          controller: _altMobileCtrl,
          selectedCode: _altCountryCode,
          onCodeChanged: (v) => setState(() => _altCountryCode = v),
          label: 'Alternate Mobile Number',
          hint: 'Optional backup number',
        ),
        const SizedBox(height: 24),
        _SectionLabel(label: 'Security'),
        CustomTextField(
          controller: _passwordCtrl,
          label: 'Create 4 Digit PIN',
          hint: 'Enter 4 digit PIN',
          required: true,
          prefixIcon: Icons.pin_outlined,
          isPassword: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          validator: (value) {

            if (value == null || value.isEmpty) return 'PIN is required';
            if (value.length != 4) return 'PIN must be exactly 4 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPassCtrl,
          label: 'Confirm PIN',
          hint: 'Re-enter 4 digit PIN',
          required: true,
          prefixIcon: Icons.pin_outlined,
          isPassword: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          validator: (value) {

            if (value == null || value.isEmpty) return 'Confirm PIN required';
            if (value != _passwordCtrl.text) return 'PIN does not match';
            return null;
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─────────────────────────────────────────
  // STEP 2 — Pharmacy / Medical Store Details
  // ─────────────────────────────────────────
  Widget _buildStep2() {
    return _StepWrapper(
      stepKey: _formKeys[1],
      title: 'Setup your Medical Store / Pharmacy',
      subtitle: 'Help customers find and recognise your Medical Store / Pharmacy',
      icon: Icons.local_pharmacy_outlined,
      children: [
        _SectionLabel(label: 'Medical Store Branding'),
        _BannerLogoUploadRow(
          logoPath: _medicalLogo,
          bannerPath: _medicalBanner,
          logoLabel: 'Medical Store Logo',
          bannerLabel: 'Medical Store Banner',
          onLogoTap: () => _pickImage(
              ImageSource.gallery, (path) => setState(() => _medicalLogo = path)),
          onBannerTap: () => _pickImage(
              ImageSource.gallery, (path) => setState(() => _medicalBanner = path)),
        ),
        const SizedBox(height: 16),
        _SectionLabel(label: 'Medical Store Photos'),
        _MultiPhotoUpload(
          photos: _medicalPhotos,
          onAdd: () => _showImagePickerOptions(
          (path) {
            setState(() {
              _medicalPhotos.add(path);
            });
          },
        ),
          onRemove: (i) => setState(() => _medicalPhotos.removeAt(i)),
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Medical Store Information'),
        CustomTextField(
          controller: _medicalNameCtrl,
          label: 'Medical Store Name',
          hint: 'e.g. Apollo Medical Store',
          required: true,
          prefixIcon: Icons.local_pharmacy_outlined,
        ),
        const SizedBox(height: 16),
        _SectionLabel(label: 'Medical Store Address'),
        CustomTextField(
          controller: _medicalAddressCtrl,
          label: 'Full Medical Store Address',
          hint: 'Building, Street, Landmark',
          required: true,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _cityCtrl,
                label: 'City',
                hint: 'City',
                required: true,
                prefixIcon: Icons.location_city_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _stateCtrl,
                label: 'State',
                hint: 'State',
                required: true,
                prefixIcon: Icons.map_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _pincodeCtrl,
          label: 'Pincode / Zip Code',
          hint: 'e.g. 110001',
          required: true,
          prefixIcon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'GPS Location'),
        _LocationPickerCard(
          latCtrl: _latCtrl,
          lngCtrl: _lngCtrl,
          onFetchLocation: _fetchRealLocation,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─────────────────────────────────────────
  // STEP 3 — Medical Category
  // ─────────────────────────────────────────
  Widget _buildStep3() {
    const categories = [
  ('💊', 'Prescription Medicines'),
  ('💉', 'OTC Medicines'),

  ('🌿', 'Ayurvedic Medicines'),
  ('🍀', 'Homeopathy'),

  ('❤️', 'Health Conditions'),
  ('💉', 'Diabetes Care'),
  ('🫀', 'Heart Care'),
  ('🤕', 'Pain Relief'),

  ('🧪', 'Supplements'),
  ('🍊', 'Vitamins'),
  ('💪', 'Fitness Nutrition'),

  ('🧴', 'Personal Care'),
  ('✨', 'Skin Care'),
  ('💇', 'Hair Care'),

  ('👶', 'Baby Care'),
  ('🌸', 'Women Care'),
  ('👴', 'Elder Care'),

  ('🩺', 'Healthcare Devices'),
  ('🏥', 'Surgical Items'),
  ('🦴', 'Orthopedic Products'),

  ('🧼', 'Hygiene Products'),
  ('🚑', 'First Aid'),

  ('👁', 'Eye Care'),
  ('🦷', 'Dental Care'),

  ('🛡️', 'Sexual Wellness'),
  ('😷', 'Covid Essentials'),
];

    return _StepWrapper(
      stepKey: _formKeys[2],
      title: 'What medicines do you sell?',
      subtitle: 'Select pharmacy categories',
      icon: Icons.medication_outlined,
      children: [
        _InfoChip(
          label:
              '${_selectedCategories.length} categories selected  •  Multiple allowed',
        ),
        const SizedBox(height: 16),
        ...categories.map((cat) {
          final selected = _selectedCategories.contains(cat.$2);
          return _CategoryCheckTile(
            emoji: cat.$1,
            label: cat.$2,
            selected: selected,
            onTap: () => setState(() {
              if (selected) {
                _selectedCategories.remove(cat.$2);
              } else {
                _selectedCategories.add(cat.$2);
              }
            }),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─────────────────────────────────────────
  // STEP 4 — Medical Store Timing
  // ─────────────────────────────────────────
  Widget _buildStep4() {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];

    return _StepWrapper(
      stepKey: _formKeys[3],
      title: 'Set your Medical Store hours',
      subtitle: 'Customers will see these hours on your medical store page',
      icon: Icons.access_time_rounded,
      children: [
        _SectionLabel(label: 'Medical Store Timing'),
        Row(
          children: [
            Expanded(
              child: _TimePickerCard(
                label: 'Opening Time',
                time: _openingTime,
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _openingTime,
                    builder: (ctx, child) => _timePickerTheme(ctx, child),
                  );
                  if (t != null) setState(() => _openingTime = t);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimePickerCard(
                label: 'Closing Time',
                time: _closingTime,
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _closingTime,
                    builder: (ctx, child) => _timePickerTheme(ctx, child),
                  );
                  if (t != null) setState(() => _closingTime = t);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionLabel(label: 'Working Days'),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: days.map((d) {
            final active = _workingDays.contains(d);
            return GestureDetector(
              onTap: () => setState(() {
                if (active) {
                  _workingDays.remove(d);
                } else {
                  _workingDays.add(d);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? kNavyBlue : kWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? kNavyBlue : kBorderColor,
                    width: active ? 1.5 : 1,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: kNavyBlue.withOpacity(0.15),
                              blurRadius: 6)
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (active)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child:
                            Icon(Icons.check_circle, color: kWhite, size: 14),
                      ),
                    Text(
                      d.substring(0, 3),
                      style: TextStyle(
                        color: active ? kWhite : kTextSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _SectionLabel(label: 'Order Preferences'),
        _ToggleCard(
          label: 'Accept Online Orders',
          description: _acceptOnlineOrders
              ? 'Medical store is accepting online medicine orders'
              : 'Online ordering temporarily paused',
          value: _acceptOnlineOrders,
          onChanged: (v) => setState(() => _acceptOnlineOrders = v),
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          label: '24 Hours Open',
          description: _is24HoursOpen
              ? 'Your medical store is open 24 hours a day'
              : 'Store follows standard opening and closing hours',
          value: _is24HoursOpen,
          onChanged: (v) => setState(() => _is24HoursOpen = v),
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          label: 'Emergency Medicine Available',
          description: _isEmergencyMedicine
              ? 'Emergency medicines are available at your store'
              : 'Emergency medicine availability is currently disabled',
          value: _isEmergencyMedicine,
          onChanged: (v) => setState(() => _isEmergencyMedicine = v),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─────────────────────────────────────────
  // STEP 5 — Legal Documents (Medical / Pharmacy)
  // ─────────────────────────────────────────
  Widget _buildStep5() {
    return _StepWrapper(
      stepKey: _formKeys[4],
      title: 'Legal & Verification',
      subtitle: 'Upload valid documents for pharmacy verification',
      icon: Icons.verified_outlined,
      children: [
        _LegalBanner(),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Drug License Details  (Mandatory)'),
        CustomTextField(
          controller: _drugLicenseCtrl,
          label: 'Drug License Number',
          hint: 'Enter Drug License Number',
          required: true,
          prefixIcon: Icons.numbers_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(30)],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Drug License Number required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        UploadCard(
          label: 'Drug License Certificate',
          required: true,
          filePath: _drugLicenseCertPath,
          onTap: () => _pickDocument(
              (path) => setState(() => _drugLicenseCertPath = path)),
          accepts: 'PDF, JPG, PNG',
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Pharmacist Registration  (Mandatory)'),
        CustomTextField(
          controller: _pharmacistRegCtrl,
          label: 'Pharmacist Registration Number',
          hint: 'Enter Pharmacist Registration Number',
          required: true,
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(30)],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Pharmacist Registration Number required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        UploadCard(
          label: 'Pharmacist Certificate',
          required: true,
          filePath: _pharmacistCertPath,
          onTap: () => _pickDocument(
              (path) => setState(() => _pharmacistCertPath = path)),
          accepts: 'PDF, JPG, PNG',
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'GST Details  (Optional)'),
        CustomTextField(
          controller: _gstNumberCtrl,
          label: 'GST Number',
          hint: '15-digit GST number',
          prefixIcon: Icons.receipt_long_outlined,
          maxLength: 15,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(15)],
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            if (value.length != 15) return 'GST must be 15 characters';
            return null;
          },
        ),
        const SizedBox(height: 12),
        UploadCard(
          label: 'GST Certificate',
          filePath: _gstCertPath,
          onTap: () =>
              _pickDocument((path) => setState(() => _gstCertPath = path)),
          accepts: 'PDF, JPG, PNG',
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Shop / Trade License'),
        CustomTextField(
          controller: _tradeLicenseCtrl,
          label: 'Trade License Number',
          hint: 'Enter trade license number',
          prefixIcon: Icons.assignment_outlined,
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Owner Identity  (Mandatory)'),
        CustomTextField(
          controller: _panCtrl,
          label: 'PAN Card Number',
          hint: 'e.g. ABCDE1234F',
          required: true,
          prefixIcon: Icons.credit_card_outlined,
          maxLength: 10,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(10)],
          validator: (value) {
            if (value == null || value.isEmpty) return 'PAN required';
            if (value.length != 10) return 'PAN must be 10 characters';
            return null;
          },
        ),
        const SizedBox(height: 12),
        UploadCard(
          label: 'PAN Card',
          required: true,
          filePath: _panDocPath,
          onTap: () =>
              _pickDocument((path) => setState(() => _panDocPath = path)),
          accepts: 'JPG, PNG, PDF',
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _aadhaarCtrl,
          label: 'Aadhaar Card Number',
          hint: '12-digit Aadhaar number',
          required: true,
          prefixIcon: Icons.fingerprint_outlined,
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Aadhaar required';
            if (value.length != 12) return 'Aadhaar must be 12 digits';
            return null;
          },
        ),
        const SizedBox(height: 12),
        UploadCard(
          label: 'Aadhaar Card (Front & Back)',
          required: true,
          filePath: _aadhaarDocPath,
          onTap: () =>
              _pickDocument((path) => setState(() => _aadhaarDocPath = path)),
          accepts: 'JPG, PNG, PDF',
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─────────────────────────────────────────
  // STEP 6 — Bank Details (same as grocery)
  // ─────────────────────────────────────────
  Widget _buildStep6() {
    return _StepWrapper(
      stepKey: _formKeys[5],
      title: 'Where should we send your payments?',
      subtitle: 'Payouts are processed every Monday',
      icon: Icons.account_balance_outlined,
      children: [
        _InfoChip(label: '✓  Your bank details are 256-bit encrypted & secure'),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Account Information'),
        CustomTextField(
          controller: _accountHolderCtrl,
          label: 'Account Holder Name',
          hint: 'Exactly as on your passbook',
          required: true,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _BankSelectorField(
          selected: _selectedBank,
          onSelect: (v) => setState(() => _selectedBank = v),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _accountNumberCtrl,
          label: 'Account Number',
          hint: 'Enter account number',
          required: true,
          prefixIcon: Icons.numbers_outlined,
          keyboardType: TextInputType.number,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmAccountCtrl,
          label: 'Confirm Account Number',
          hint: 'Re-enter account number',
          required: true,
          prefixIcon: Icons.numbers_outlined,
          keyboardType: TextInputType.number,
          validator: (value) {

            if (value == null || value.isEmpty) {
              return 'Confirm account number required';
            }
            if (value != _accountNumberCtrl.text) {
              return 'Account numbers do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _ifscCtrl,
          label: 'IFSC Code',
          hint: 'e.g. SBIN0001234',
          required: true,
          prefixIcon: Icons.code_outlined,
          textCapitalization: TextCapitalization.characters,
          maxLength: 11,
          inputFormatters: [
            LengthLimitingTextInputFormatter(11),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
          validator: (value) {

            if (value == null || value.isEmpty) return 'IFSC Code required';
            final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
            if (!ifscRegex.hasMatch(value.toUpperCase())) {
              return 'Invalid IFSC (e.g. SBIN0001234)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _upiCtrl,
          label: 'UPI ID',
          hint: 'e.g. name@upi or mobile@paytm',
          required: true,
          prefixIcon: Icons.qr_code_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Cancelled Cheque  (Optional)'),
        UploadCard(
          label: 'Upload Cancelled Cheque',
          filePath: _cancelledChequePath,
          onTap: () => _pickDocument(
              (path) => setState(() => _cancelledChequePath = path)),
          accepts: 'JPG, PNG, PDF',
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─────────────────────────────────────────
  // STEP 7 — Medicine Delivery Setup
  // ─────────────────────────────────────────
  Widget _buildStep7() {

    return _StepWrapper(
      stepKey: _formKeys[6],
      title: 'Medicine Delivery Setup',
      subtitle: 'Manage medicine delivery preferences',
      icon: Icons.delivery_dining_outlined,
      children: [
        _SectionLabel(label: 'Delivery Option'),
        SelectionCard(
          icon: Icons.electric_moped_outlined,
          title: 'CartKaro Delivery Partner',
          subtitle:
              "CartKaro's trained delivery fleet handles all your medicine orders end-to-end.",
          selected: _deliveryOption == 'cartkaro',
          onTap: () => setState(() => _deliveryOption = 'cartkaro'),
          badge: 'Recommended',
        ),
        const SizedBox(height: 12),
        
        
        const SizedBox(height: 24),
        _SectionLabel(label: 'Medicine Delivery Settings'),
        _ToggleCard(
          label: 'Prescription Required',
          description: _isPrescriptionRequired
              ? 'Customers must upload a valid prescription to order'
              : 'Medicines can be ordered without a prescription',
          value: _isPrescriptionRequired,
          onChanged: (v) => setState(() => _isPrescriptionRequired = v),
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          label: 'Same Day Delivery',
          description: _isSameDayDelivery
              ? 'Same day medicine delivery is available'
              : 'Same day delivery is currently not available',
          value: _isSameDayDelivery,
          onChanged: (v) => setState(() => _isSameDayDelivery = v),
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          label: 'Emergency Delivery Available',
          description: _isEmergencyDelivery
              ? 'Emergency medicine delivery is available at your store'
              : 'Emergency delivery is currently not available',
          value: _isEmergencyDelivery,
          onChanged: (v) => setState(() => _isEmergencyDelivery = v),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─────────────────────────────────────────
  // STEP 8 — Agreement
  // ─────────────────────────────────────────
  Widget _buildStep8() {
    return _StepWrapper(
      stepKey: _formKeys[7],
      title: 'CartKaro Medical Partner Agreement',
      subtitle: 'Please read carefully before submitting',
      icon: Icons.handshake_outlined,
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.35,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: _MedicalAgreementText(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kBlueAccent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kNavyBlue.withOpacity(0.35)),
          ),
          child: Row(
            children: const [
              Icon(Icons.percent_rounded, color: kNavyBlueDark, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commission Rate: 5% – 15%',
                      style: TextStyle(
                          color: kNavyBlueDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Based on order type. Payouts every Monday.',
                      style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () =>
              setState(() => _agreementAccepted = !_agreementAccepted),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _agreementAccepted ? kBlueAccent : kWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _agreementAccepted ? kNavyBlue : kBorderColor,
                width: _agreementAccepted ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _agreementAccepted ? kNavyBlue : kWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _agreementAccepted ? kNavyBlue : kBorderColor,
                      width: 2,
                    ),
                  ),
                  child: _agreementAccepted
                      ? const Icon(Icons.check, color: kWhite, size: 16)
                      : null,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'I have read and accept the CartKaro Medical Partner Agreement, terms of service, commission structure and privacy policy.',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _timePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(
          primary: kNavyBlue,
          onPrimary: kWhite,
          onSurface: kTextPrimary,
        ),
      ),
      child: child!,
    );
  }
}

// ================================================================
// STEP 9 — MEDICAL SUCCESS SCREEN (StatefulWidget)
// 5 second loading → fir success + dashboard button
// ================================================================
class _MedicalSuccessScreen extends StatefulWidget {
  final String? businessId;
  const _MedicalSuccessScreen({this.businessId});

  @override
  State<_MedicalSuccessScreen> createState() =>
      _MedicalSuccessScreenState();
}

class _MedicalSuccessScreenState extends State<_MedicalSuccessScreen> {
  bool _showLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: kBlueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: kNavyBlue, width: 2.5),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: kNavyBlue,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Processing Your\nRegistration...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kNavyBlueDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please wait while we securely\nsubmit your details.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: kTextSecondary, fontSize: 14, height: 1.55),
              ),
              const SizedBox(height: 36),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kNavyBlueDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.schedule_rounded, color: kWhite, size: 32),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expected Verification Time',
                          style: TextStyle(
                              color: Color(0xFF8DA4BF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '24 – 48 Hours',
                          style: TextStyle(
                              color: kWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                    color: kNavyBlue, strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Submitting your information...',
                style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    // ── SUCCESS STATE ──
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: kBlueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: kNavyBlue, width: 2.5),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: kNavyBlue, size: 52),
          ),
          const SizedBox(height: 24),
          const Text(
            'Registration Completed\nSuccessfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kNavyBlueDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your medical store is now under review.\nOur team will verify your documents.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: kTextSecondary, fontSize: 14, height: 1.55),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: const [
                _SuccessCheckItem(label: 'Account Created', done: true),
                SizedBox(height: 14),
                _SuccessCheckItem(
                    label: 'Medical Store Details Added', done: true),
                SizedBox(height: 14),
                _SuccessCheckItem(
                    label: 'License Documents Submitted', done: true),
                SizedBox(height: 14),
                _SuccessCheckItem(
                    label: 'Verification Pending',
                    done: false,
                    pending: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: kNavyBlueDark,
                borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: const [
                Icon(Icons.schedule_rounded, color: kWhite, size: 30),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Verification Time',
                      style: TextStyle(
                          color: Color(0xFF8DA4BF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '24 – 48 Hours',
                      style: TextStyle(
                          color: kWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.businessId != null) {
                  context.go('/dashboard', extra: widget.businessId);
                } else {
                  context.go('/business-type');
                }
              },
              icon: const Icon(Icons.dashboard_rounded, size: 20),
              label: const Text(
                'Go To Dashboard',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNavyBlue,
                foregroundColor: kWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
              onPressed: () async {
                final Uri callUri = Uri(
                  scheme: 'tel',
                  path: '+919876543210',
                );

                if (await canLaunchUrl(callUri)) {
                  await launchUrl(callUri);
                }
              },

              icon: const Icon(
                Icons.call,
                color: kNavyBlueLight,
                size: 18,
              ),

              label: const Text(
                'Need help? Contact Partner Support\n+91 98765 43210',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kNavyBlueLight,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ================================================================
// ── REUSABLE WIDGETS ──
// ================================================================

class _StepWrapper extends StatelessWidget {
  final GlobalKey<FormState> stepKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _StepWrapper({
    required this.stepKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: stepKey,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kNavyBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: kWhite, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: kNavyBlueDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.inputFormatters,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;
  bool _focused = false;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() {
        setState(() => _focused = _focus.hasFocus);
      });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPass = widget.isPassword || widget.obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: widget.label,
            style: const TextStyle(
                color: kTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
            children: widget.required
                ? const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: kErrorColor))
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _focused
                ? [
                    BoxShadow(
                        color: kNavyBlue.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            keyboardType: widget.keyboardType,
            obscureText: isPass && _obscure,
            maxLines: isPass ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            style: const TextStyle(
                color: kTextPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                  color: kTextHint,
                  fontSize: 14,
                  fontWeight: FontWeight.w400),
              filled: true,
              fillColor: kWhite,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon,
                      color: _focused ? kNavyBlue : kTextHint, size: 20)
                  : null,
              suffixIcon: isPass
                  ? GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: kTextHint,
                        size: 20,
                      ),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: kBorderColor, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: kNavyBlue, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: kErrorColor, width: 1.2)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: kErrorColor, width: 1.5)),
            ),
            validator: widget.validator ??
                (value) {
                  if (widget.required == true) {
                    if (value == null || value.trim().isEmpty) {
                      return '${widget.label} is required';
                    }
                  }
                  return null;
                },
          ),
        ),
      ],
    );
  }
}

class UploadCard extends StatelessWidget {
  final String label;
  final bool required;
  final String filePath;
  final VoidCallback onTap;
  final String accepts;

  const UploadCard({
    Key? key,
    required this.label,
    this.required = false,
    required this.filePath,
    required this.onTap,
    this.accepts = 'PDF, JPG, PNG',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uploaded = filePath.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uploaded ? kBlueAccent : kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploaded ? kNavyBlue : kBorderColor,
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: uploaded ? kNavyBlue.withOpacity(0.15) : kOffWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: uploaded
                        ? kNavyBlue.withOpacity(0.3)
                        : kBorderColor),
              ),
              child: Icon(
                uploaded
                    ? Icons.check_circle_outline_rounded
                    : Icons.upload_file_outlined,
                color: uploaded ? kNavyBlueDark : kNavyBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          uploaded ? filePath.split('/').last : label,
                          style: TextStyle(
                            color: uploaded ? kNavyBlueDark : kTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (required && !uploaded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kErrorColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Required',
                              style: TextStyle(
                                  color: kErrorColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    uploaded ? 'Tap to replace' : 'Tap to upload  •  $accepts',
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: kTextHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const SelectionCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? kNavyBlueDark : kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? kNavyBlue : kBorderColor,
              width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: kNavyBlue.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? kNavyBlue.withOpacity(0.2) : kOffWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selected ? kWhite : kNavyBlue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                                color: selected ? kWhite : kTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5)),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: kNavyBlueLight,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(badge!,
                              style: const TextStyle(
                                  color: kWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: selected
                              ? const Color(0xFF8DA4BF)
                              : kTextSecondary,
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? kWhite : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? kWhite : kBorderColor, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check, color: kNavyBlueDark, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _FilledNavButton(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? kNavyBlue : kBorderColor,
          borderRadius: BorderRadius.circular(13),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: kNavyBlue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    color: enabled ? kWhite : kTextHint,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(width: 8),
            Icon(icon, color: enabled ? kWhite : kTextHint, size: 18),
          ],
        ),
      ),
    );
  }
}

class _OutlinedNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlinedNavButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: kBorderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kTextSecondary, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: kNavyBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: kDivider)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kNavyBlueLight.withOpacity(0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: kNavyBlueLight,
              fontSize: 12.5,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _ProfilePhotoUpload extends StatelessWidget {
  final String path;
  final VoidCallback onTap;

  const _ProfilePhotoUpload({required this.path, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uploaded = path.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: uploaded ? kBlueAccent : kOffWhite,
              shape: BoxShape.circle,
              border: Border.all(
                  color: uploaded ? kNavyBlue : kBorderColor, width: 2),
              image: uploaded
                  ? DecorationImage(
                      image: FileImage(File(path)), fit: BoxFit.cover)
                  : null,
            ),
            child: !uploaded
                ? const Icon(Icons.person_outline,
                    color: kTextHint, size: 44)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kNavyBlue,
                shape: BoxShape.circle,
                border: Border.all(color: kWhite, width: 2),
              ),
              child:
                  const Icon(Icons.camera_alt, color: kWhite, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefilledMobileField extends StatelessWidget {
  final String mobile;
  const _PrefilledMobileField({required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text('Mobile Number',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Icon(Icons.verified_rounded, color: kNavyBlue, size: 15),
            SizedBox(width: 4),
            Text('OTP Verified',
                style: TextStyle(
                    color: kNavyBlueDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor),
          ),
          child: Row(
            children: [
              const Text('🇮🇳  +91',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: kTextSecondary)),
              Container(
                  width: 1,
                  height: 18,
                  color: kBorderColor,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                child: Text(mobile,
                    style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
              ),
              const Icon(Icons.lock_outline_rounded,
                  color: kTextHint, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Mobile number cannot be changed. Contact support to update.',
          style: TextStyle(color: kTextHint, fontSize: 11),
        ),
      ],
    );
  }
}

const List<Map<String, String>> _countryCodes = [
  {'flag': '🇮🇳', 'code': '+91',  'name': 'India'},
];

class _CountryCodeMobileField extends StatelessWidget {
  final TextEditingController controller;
  final String selectedCode;
  final ValueChanged<String> onCodeChanged;
  final String label;
  final String hint;

  const _CountryCodeMobileField({
    required this.controller,
    required this.selectedCode,
    required this.onCodeChanged,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: kTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showCodePicker(context),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorderColor),
                ),
                child: Row(
                  children: [
                    Text(
                      _countryCodes.firstWhere(
                        (c) => c['code'] == selectedCode,
                        orElse: () => _countryCodes[0],
                      )['flag']!,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(selectedCode,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: kTextPrimary)),
                    const Icon(Icons.arrow_drop_down,
                        color: kTextHint, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length != 10) {
                    return 'Enter valid 10-digit mobile number';
                  }
                  return null;
                },
                style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: hint,
                  counterText: '',
                  hintStyle:
                      const TextStyle(color: kTextHint, fontSize: 14),
                  filled: true,
                  fillColor: kWhite,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBorderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBorderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: kNavyBlue, width: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCodePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: kBorderColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('Select Country Code',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: kTextPrimary)),
              const SizedBox(height: 16),
              ..._countryCodes.map(
                (c) => ListTile(
                  leading: Text(c['flag']!,
                      style: const TextStyle(fontSize: 22)),
                  title: Text('${c['name']}  (${c['code']})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500)),
                  trailing: c['code'] == selectedCode
                      ? const Icon(Icons.check, color: kNavyBlue)
                      : null,
                  onTap: () {
                    onCodeChanged(c['code']!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BannerLogoUploadRow extends StatelessWidget {
  final String logoPath;
  final String bannerPath;
  final String logoLabel;
  final String bannerLabel;
  final VoidCallback onLogoTap;
  final VoidCallback onBannerTap;

  const _BannerLogoUploadRow({
    required this.logoPath,
    required this.bannerPath,
    required this.onLogoTap,
    required this.onBannerTap,
    this.logoLabel = 'Store Logo',
    this.bannerLabel = 'Store Banner',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onLogoTap,
            child: _UploadBox(
              label: logoLabel,
              icon: Icons.local_pharmacy_outlined,
              imagePath: logoPath,
              aspectRatio: 1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: onBannerTap,
            child: _UploadBox(
              label: bannerLabel,
              icon: Icons.panorama_outlined,
              imagePath: bannerPath,
              aspectRatio: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final String imagePath;
  final double aspectRatio;

  const _UploadBox({
    required this.label,
    required this.icon,
    required this.imagePath,
    this.aspectRatio = 1,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = imagePath.isNotEmpty;
    return SizedBox(
      height: 95,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: uploaded ? kBlueAccent : kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: uploaded ? kNavyBlue : kBorderColor,
              style: BorderStyle.solid,
              width: uploaded ? 1.5 : 1,
            ),
            image: uploaded
                ? DecorationImage(
                    image: FileImage(File(imagePath)),
                    fit: BoxFit.cover)
                : null,
          ),
          child: !uploaded
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: kNavyBlue, size: 26),
                    const SizedBox(height: 8),
                    Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Tap to upload',
                        style: TextStyle(
                            color: kTextHint, fontSize: 10.5)),
                  ],
                )
              : Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.edit,
                          size: 16, color: kNavyBlue),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MultiPhotoUpload extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _MultiPhotoUpload(
      {required this.photos,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: kBorderColor, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_a_photo_outlined,
                      color: kNavyBlue, size: 22),
                  SizedBox(height: 6),
                  Text('Camera',
                      style: TextStyle(
                          color: kNavyBlue,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          ...List.generate(
            photos.length,
            (i) => Container(
              width: 80,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: kBlueAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kNavyBlue.withOpacity(0.4)),
                image: DecorationImage(
                    image: FileImage(File(photos[i])),
                    fit: BoxFit.cover),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: kErrorColor, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: kWhite, size: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPickerCard extends StatelessWidget {
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  final VoidCallback onFetchLocation;

  const _LocationPickerCard(
      {required this.latCtrl,
      required this.lngCtrl,
      required this.onFetchLocation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.map_rounded, color: kNavyBlue, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Google Map Location',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: kTextPrimary)),
              ),
              Text(' *',
                  style: TextStyle(color: kErrorColor, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onFetchLocation,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Use Current Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kNavyBlue,
                side: const BorderSide(color: kNavyBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _CoordField(
                      controller: latCtrl, label: 'Latitude')),
              const SizedBox(width: 12),
              Expanded(
                  child: _CoordField(
                      controller: lngCtrl, label: 'Longitude')),
            ],
          ),
          if (latCtrl.text.isNotEmpty && lngCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: kBlueAccent,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_rounded,
                      color: kNavyBlue, size: 15),
                  SizedBox(width: 8),
                  Text('Location captured successfully',
                      style: TextStyle(
                          color: kNavyBlueDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _CoordField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kTextSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 13, color: kTextPrimary),
          readOnly: true,
          decoration: InputDecoration(
            hintText: '0.0000',
            hintStyle:
                const TextStyle(color: kTextHint, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF3F5F9),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kNavyBlue)),
          ),
        ),
      ],
    );
  }
}

class _CategoryCheckTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCheckTile(
      {required this.emoji,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? kNavyBlueDark : kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? kNavyBlue : kBorderColor,
                width: selected ? 1.5 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: kNavyBlue.withOpacity(0.1),
                        blurRadius: 8)
                  ]
                : [],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: selected ? kWhite : kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? kWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: selected ? kWhite : kBorderColor,
                      width: 2),
                ),
                child: selected
                    ? const Icon(Icons.check,
                        color: kNavyBlueDark, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerCard(
      {required this.label, required this.time, required this.onTap});

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: kNavyBlue, size: 20),
                const SizedBox(width: 8),
                Text(_formatTime(time),
                    style: const TextStyle(
                        color: kNavyBlueDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const Spacer(),
                const Icon(Icons.edit_outlined,
                    color: kTextHint, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard(
      {required this.label,
      required this.description,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? kBlueAccent : kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: value ? kNavyBlue : kBorderColor,
            width: value ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(
                        color: value ? kNavyBlueDark : kTextSecondary,
                        fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kNavyBlue,
            activeTrackColor: kNavyBlue.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

class _LegalBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: kNavyBlueDark,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: const [
          Icon(Icons.security_rounded, color: kWhite, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'All documents are encrypted and stored securely. They are used only for pharmacy verification by CartKaro.',
              style: TextStyle(
                  color: Color(0xFF8DA4BF), fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

const List<Map<String, String>> _banks = [
  {'name': 'State Bank of India',      'abbr': 'SBI',  'color': '0xFF0066B2'},
  {'name': 'HDFC Bank',                'abbr': 'HDFC', 'color': '0xFF003087'},
  {'name': 'ICICI Bank',               'abbr': 'IC',   'color': '0xFFE94B3C'},
  {'name': 'Axis Bank',                'abbr': 'AXIS', 'color': '0xFF97144D'},
  {'name': 'Punjab National Bank',     'abbr': 'PNB',  'color': '0xFF6B2C7A'},
  {'name': 'Bank of Baroda',           'abbr': 'BOB',  'color': '0xFFEF7B10'},
  {'name': 'Kotak Mahindra Bank',      'abbr': 'KMB',  'color': '0xFFED1C24'},
  {'name': 'IndusInd Bank',            'abbr': 'IIB',  'color': '0xFF1C5CA6'},
  {'name': 'Yes Bank',                 'abbr': 'YES',  'color': '0xFF1E2F65'},
  {'name': 'IDFC First Bank',          'abbr': 'IDFC', 'color': '0xFF009A44'},
  {'name': 'Canara Bank',              'abbr': 'CNRA', 'color': '0xFF006CB5'},
  {'name': 'Union Bank of India',      'abbr': 'UBI',  'color': '0xFFE30613'},
  {'name': 'Indian Bank',              'abbr': 'INDB', 'color': '0xFF004B93'},
  {'name': 'Bank of India',            'abbr': 'BOI',  'color': '0xFF0072BC'},
  {'name': 'Central Bank of India',    'abbr': 'CBI',  'color': '0xFF003399'},
  {'name': 'Indian Overseas Bank',     'abbr': 'IOB',  'color': '0xFF005BAC'},
  {'name': 'UCO Bank',                 'abbr': 'UCO',  'color': '0xFF0073CF'},
  {'name': 'Bank of Maharashtra',      'abbr': 'BOM',  'color': '0xFF002D62'},
  {'name': 'Punjab & Sind Bank',       'abbr': 'PSB',  'color': '0xFFFFB000'},
  {'name': 'Federal Bank',             'abbr': 'FED',  'color': '0xFF004C97'},
  {'name': 'RBL Bank',                 'abbr': 'RBL',  'color': '0xFF002D72'},
  {'name': 'Bandhan Bank',             'abbr': 'BDB',  'color': '0xFFB00020'},
  {'name': 'South Indian Bank',        'abbr': 'SIB',  'color': '0xFF004A98'},
  {'name': 'Karur Vysya Bank',         'abbr': 'KVB',  'color': '0xFF00529B'},
  {'name': 'City Union Bank',          'abbr': 'CUB',  'color': '0xFF8B0000'},
  {'name': 'DCB Bank',                 'abbr': 'DCB',  'color': '0xFF006600'},
  {'name': 'Tamilnad Mercantile Bank', 'abbr': 'TMB',  'color': '0xFF004080'},
  {'name': 'Karnataka Bank',           'abbr': 'KBL',  'color': '0xFF7A003C'},
  {'name': 'Dhanlaxmi Bank',           'abbr': 'DLB',  'color': '0xFF8B0000'},
  {'name': 'CSB Bank',                 'abbr': 'CSB',  'color': '0xFFB22222'},
  {'name': 'Jammu & Kashmir Bank',     'abbr': 'JKB',  'color': '0xFF006400'},
  {'name': 'AU Small Finance Bank',    'abbr': 'AU',   'color': '0xFFFF6600'},
  {'name': 'Equitas Small Finance Bank','abbr': 'EQTS','color': '0xFF800080'},
  {'name': 'Ujjivan Small Finance Bank','abbr': 'UJJV','color': '0xFF005DAA'},
  {'name': 'Suryoday Small Finance Bank','abbr': 'SUR','color': '0xFFFF9933'},
  {'name': 'Jana Small Finance Bank',  'abbr': 'JANA', 'color': '0xFF008080'},
  {'name': 'Fincare Small Finance Bank','abbr': 'FIN', 'color': '0xFF00A651'},
  {'name': 'Airtel Payments Bank',     'abbr': 'AIR',  'color': '0xFFE40000'},
  {'name': 'India Post Payments Bank', 'abbr': 'IPPB', 'color': '0xFFFF0000'},
  {'name': 'Paytm Payments Bank',      'abbr': 'PYTM', 'color': '0xFF00BAF2'},
  {'name': 'Citibank',                 'abbr': 'CITI', 'color': '0xFF004B8D'},
  {'name': 'HSBC Bank',                'abbr': 'HSBC', 'color': '0xFFDB0011'},
  {'name': 'Standard Chartered Bank',  'abbr': 'SCB',  'color': '0xFF0072CE'},
  {'name': 'Deutsche Bank',            'abbr': 'DB',   'color': '0xFF0018A8'},
  {'name': 'DBS Bank',                 'abbr': 'DBS',  'color': '0xFFFF0000'},
  {'name': 'Barclays Bank',            'abbr': 'BARC', 'color': '0xFF00AEEF'},
  {'name': 'Bank of America',          'abbr': 'BOA',  'color': '0xFF012169'},
  {'name': 'JP Morgan Chase Bank',     'abbr': 'JPMC', 'color': '0xFF117ACA'},
  {'name': 'BNP Paribas',              'abbr': 'BNP',  'color': '0xFF00965E'},
  {'name': 'MUFG Bank',                'abbr': 'MUFG', 'color': '0xFFE60012'},
  {'name': 'Doha Bank',                'abbr': 'DOHA', 'color': '0xFF7A263A'},
  {'name': 'Bank of Bahrain and Kuwait','abbr': 'BBK', 'color': '0xFF004B93'},
];

class _BankSelectorField extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _BankSelectorField(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text('Bank Name',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Text(' *', style: TextStyle(color: kErrorColor)),
          ],
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: () => _showBankPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor),
            ),
            child: Row(
              children: [
                if (selected.isNotEmpty) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                          _banks.firstWhere(
                              (b) => b['name'] == selected)['color']!)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _banks.firstWhere(
                            (b) => b['name'] == selected)['abbr']!,
                        style: const TextStyle(
                            color: kWhite,
                            fontSize: 9,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(selected,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14)),
                  ),
                ] else
                  Expanded(
                    child: Row(
                      children: const [
                        Icon(Icons.account_balance_outlined,
                            color: kTextHint, size: 20),
                        SizedBox(width: 10),
                        Text('Select your bank',
                            style: TextStyle(
                                color: kTextHint, fontSize: 14)),
                      ],
                    ),
                  ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: kTextHint),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBankPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: kBorderColor,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Your Bank',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: kTextPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(overscroll: false),
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      controller: scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _banks.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: kDivider),
                      itemBuilder: (_, i) {
                        final bank = _banks[i];
                        final isSel = bank['name'] == selected;
                        return ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Color(int.parse(bank['color']!)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(bank['abbr']!,
                                  style: const TextStyle(
                                      color: kWhite,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                          title: Text(bank['name']!,
                              style: TextStyle(
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSel
                                      ? kNavyBlue
                                      : kTextPrimary)),
                          trailing: isSel
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: kNavyBlue)
                              : null,
                          onTap: () {
                            onSelect(bank['name']!);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SuccessCheckItem extends StatelessWidget {
  final String label;
  final bool done;
  final bool pending;

  const _SuccessCheckItem(
      {required this.label, required this.done, this.pending = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: done
                ? kNavyBlue
                : pending
                    ? kWarningColor.withOpacity(0.15)
                    : kOffWhite,
            shape: BoxShape.circle,
            border: Border.all(
                color: done
                    ? kNavyBlue
                    : pending
                        ? kWarningColor
                        : kBorderColor,
                width: 1.5),
          ),
          child: done
              ? const Icon(Icons.check, color: kWhite, size: 17)
              : pending
                  ? const Icon(Icons.hourglass_empty_rounded,
                      color: kWarningColor, size: 16)
                  : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: done
                      ? kNavyBlueDark
                      : pending
                          ? kWarningColor
                          : kTextSecondary,
                  fontWeight: done || pending
                      ? FontWeight.w600
                      : FontWeight.w400,
                  fontSize: 14)),
        ),
        Text(done ? 'Done' : pending ? 'Pending' : '',
            style: TextStyle(
                color: done ? kNavyBlueDark : kWarningColor,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Medical Partner Agreement Text ──
class _MedicalAgreementText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
        color: kNavyBlueDark,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        height: 1.6);
    const bodyStyle = TextStyle(
        color: kTextSecondary, fontSize: 12.5, height: 1.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('CartKaro Medical Partner Agreement',
            style: TextStyle(
                color: kNavyBlueDark,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        SizedBox(height: 6),
        Text('Effective upon registration. Last updated: June 2026.',
            style: TextStyle(color: kTextHint, fontSize: 11)),
        Divider(height: 24, color: kDivider),
        Text('1. Drug License & Compliance', style: headerStyle),
        Text(
          'Medical partners must hold a valid Drug License issued by the appropriate State Drug Controller. The license must remain active throughout the partnership. CartKaro reserves the right to suspend accounts upon license expiry or revocation.',
          style: bodyStyle,
        ),
        SizedBox(height: 14),
        Text('2. I Have a Valid Drug License', style: headerStyle),
        Text(
          'By registering, you confirm that your pharmacy holds all required drug licenses as mandated by the Drugs and Cosmetics Act, 1940, and all applicable state regulations.',
          style: bodyStyle,
        ),
        SizedBox(height: 14),
        Text('3. I Will Sell Only Approved Medicines', style: headerStyle),
        Text(
          'Medical partners must only list and sell medicines that are approved by the Central Drugs Standard Control Organisation (CDSCO) and are not prohibited, banned, or restricted under applicable law.',
          style: bodyStyle,
        ),
        SizedBox(height: 14),
        Text('4. I Will Verify Prescriptions When Required', style: headerStyle),
        Text(
          'For Schedule H, H1, and X drugs, partners must verify and retain valid prescriptions from customers before dispensing. Digital prescriptions uploaded via the app must be verified before order fulfilment.',
          style: bodyStyle,
        ),
        SizedBox(height: 14),
        Text('5. Commission & Payment Terms', style: headerStyle),
        Text(
          'CartKaro charges a commission of 5%–15% per successful order based on order type and medicine category. Payouts are processed every Monday for orders completed in the previous week. CartKaro reserves the right to withhold payments in case of disputes or policy violations.',
          style: bodyStyle,
        ),
        SizedBox(height: 14),
        Text('6. Medicine Listing Policy', style: headerStyle),
        Text(
          'Partners must not list medicines that are unavailable, expired, or incorrectly priced. Product descriptions, images, and dosage information must be accurate. CartKaro reserves the right to remove non-compliant listings without prior notice.',
          style: bodyStyle,
        ),
        SizedBox(height: 14),
        Text('7. Account Termination', style: headerStyle),
        Text(
          'CartKaro may suspend or terminate pharmacy accounts for repeated policy violations, fraudulent activity, sale of prohibited substances, customer complaints, or non-compliance with drug regulations. Partners may appeal within 15 days of suspension.',
          style: bodyStyle,
        ),
        SizedBox(height: 14),
        Text('8. I Accept CartKaro Medical Partner Terms', style: headerStyle),
        Text(
          'By completing registration, you agree to abide by all CartKaro Medical Partner policies, the Drugs and Cosmetics Act 1940, Pharmacy Act 1948, and all applicable central and state drug regulations. This agreement is governed by the laws of India.',
          style: bodyStyle,
        ),
        SizedBox(height: 8),
      ],
    );
  }
}

// ================================================================
// MAIN ENTRY POINT
// ================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DemoApp());
}

class _DemoApp extends StatelessWidget {
  const _DemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CartKaro Partner Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
            seedColor: kNavyBlue, primary: kNavyBlue),
        scaffoldBackgroundColor: kOffWhite,
        useMaterial3: true,
      ),
      home: const MedicalRegistrationScreen(
          prefilledMobile: '9876543210'),
    );
  }
}