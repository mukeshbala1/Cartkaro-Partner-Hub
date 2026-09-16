import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CloudStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a single file to Firebase Cloud Storage and returns its permanent Download URL.
  /// If [localPath] is already a remote URL (http:// or https://), it is returned directly.
  /// If the local file does not exist or upload fails, returns [fallback] (defaults to empty string).
  static Future<String> uploadFile({
    required String localPath,
    required String destinationPath,
    String fallback = '',
  }) async {
    final cleanPath = localPath.trim();
    if (cleanPath.isEmpty) return fallback;

    // Already a remote URL
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    try {
      final file = File(cleanPath);
      if (!await file.exists()) {
        debugPrint('[CloudStorageService] Local file not found: $cleanPath');
        return fallback;
      }

      final ext = cleanPath.contains('.') ? cleanPath.split('.').last.toLowerCase() : 'jpg';
      final contentType = _getContentType(ext);

      final ref = _storage.ref().child(destinationPath);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'source': 'partner_hub',
        },
      );

      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[CloudStorageService] Uploaded successfully: $destinationPath -> $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[CloudStorageService] Upload failed for $cleanPath to $destinationPath: $e');
      return fallback;
    }
  }

  /// Uploads a list of multiple local photo paths to Firebase Storage.
  /// Returns a list of Cloud Download URLs.
  static Future<List<String>> uploadMultipleFiles({
    required List<String> localPaths,
    required String destinationFolder,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < localPaths.length; i++) {
      final path = localPaths[i].trim();
      if (path.isEmpty) continue;

      if (path.startsWith('http://') || path.startsWith('https://')) {
        downloadUrls.add(path);
        continue;
      }

      final ext = path.contains('.') ? path.split('.').last.toLowerCase() : 'jpg';
      final destination = '$destinationFolder/photo_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

      final url = await uploadFile(
        localPath: path,
        destinationPath: destination,
      );

      if (url.isNotEmpty) {
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
        return 'application/octet-stream';
    }
  }
}
