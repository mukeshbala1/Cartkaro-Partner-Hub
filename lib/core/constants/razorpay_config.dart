/// ============================================================
/// CartKaro Partner Hub — Razorpay Configuration
/// File: razorpay_config.dart
/// ============================================================

class RazorpayConfig {
  /// Razorpay API Key ID
  static String keyId = 'rzp_test_TeKFIBzfa5CEKA';

  /// Razorpay API Key Secret
  static String keySecret = 'N3Um8gmpiKm8oJeWEbyiPiRQ';

  /// Optional: RazorpayX Source Account Number (for penny-drop validation if enabled on RazorpayX)
  static String sourceAccountNumber = '';

  /// Razorpay API Base URL
  static const String apiBaseUrl = 'https://api.razorpay.com/v1';

  /// Razorpay IFSC Public URL
  static const String ifscBaseUrl = 'https://ifsc.razorpay.com';

  /// Checks whether live/test credentials have been provided
  static bool get isConfigured =>
      keyId.trim().isNotEmpty &&
      keySecret.trim().isNotEmpty &&
      keyId != 'YOUR_RAZORPAY_KEY_ID' &&
      keySecret != 'YOUR_RAZORPAY_KEY_SECRET';
}
