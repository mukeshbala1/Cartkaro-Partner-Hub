import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import 'safe_image_provider.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Flag to prevent app lifecycle watcher from locking or redirecting
  /// when camera or file picker activity is opened in foreground.
  static bool isPickingMedia = false;

  /// Safely picks an image from [source] with downsampling and compression
  /// to protect against Out-Of-Memory (OOM) errors and process killing on Android.
  static Future<String?> pickImage({
    required ImageSource source,
    double maxWidth = 1600,
    double maxHeight = 1600,
    int imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    isPickingMedia = true;
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );

      // Clean image cache to release any previous high-resolution bitmaps
      PaintingBinding.instance.imageCache.clearLiveImages();

      return file?.path;
    } catch (e) {
      debugPrint('[ImagePickerHelper] Error picking image: $e');
      return null;
    } finally {
      // Small buffer delay to allow lifecycle resumed events to settle
      await Future.delayed(const Duration(milliseconds: 600));
      isPickingMedia = false;
    }
  }

  /// Safely picks multiple images with downsampling.
  static Future<List<String>> pickMultipleImages({
    double maxWidth = 1600,
    double maxHeight = 1600,
    int imageQuality = 85,
  }) async {
    isPickingMedia = true;
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      PaintingBinding.instance.imageCache.clearLiveImages();
      return files.map((f) => f.path).toList();
    } catch (e) {
      debugPrint('[ImagePickerHelper] Error picking multiple images: $e');
      return [];
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
      isPickingMedia = false;
    }
  }

  /// Checks if the Android Activity was killed while picking an image and restores it.
  static Future<LostDataResponse?> retrieveLostData() async {
    try {
      if (!Platform.isAndroid) return null;
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      return response;
    } catch (e) {
      debugPrint('[ImagePickerHelper] Error retrieving lost data: $e');
      return null;
    }
  }

  /// Displays interactive full-screen photo viewer dialog
  static void showFullPhotoDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: SafeImageWidget(
                    imagePath: imagePath,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays bottom sheet specifically for Owner Face / Profile Photo
  /// with direct Selfie (Front Camera) mode for crystal clear face alignment.
  static Future<void> showProfilePhotoPickerOptions({
    required BuildContext context,
    required ValueChanged<String> onImageSelected,
    String? currentPath,
    VoidCallback? onRemove,
    String title = 'Owner Profile Photo',
    double maxWidth = 1600,
    double maxHeight = 1600,
    int imageQuality = 90,
  }) async {
    final hasCurrent = currentPath != null &&
        currentPath.trim().isNotEmpty &&
        getSafeImageProvider(currentPath) != null;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kDarkText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Capture a clear, well-lit photo of the owner\'s face',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                if (hasCurrent) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.eye, color: Colors.blue, size: 22),
                    ),
                    title: const Text('View Full Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: const Text('Inspect face clarity without cropping', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      showFullPhotoDialog(context, currentPath);
                    },
                  ),
                ],
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.userCheck, color: AppColors.kPrimary, size: 22),
                  ),
                  title: Text(hasCurrent ? 'Retake Selfie (Front Camera)' : 'Take Selfie (Front Camera)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Open front camera to capture your face', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final path = await pickImage(
                      source: ImageSource.camera,
                      preferredCameraDevice: CameraDevice.front,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                      imageQuality: imageQuality,
                    );
                    if (path != null && path.isNotEmpty) {
                      onImageSelected(path);
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: AppColors.kPrimary, size: 22),
                  ),
                  title: Text(hasCurrent ? 'Retake with Back Camera' : 'Take Photo (Back Camera)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Use back camera for portrait', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final path = await pickImage(
                      source: ImageSource.camera,
                      preferredCameraDevice: CameraDevice.rear,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                      imageQuality: imageQuality,
                    );
                    if (path != null && path.isNotEmpty) {
                      onImageSelected(path);
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.image, color: AppColors.kPrimary, size: 22),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Select a portrait photo from device gallery', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final path = await pickImage(
                      source: ImageSource.gallery,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                      imageQuality: imageQuality,
                    );
                    if (path != null && path.isNotEmpty) {
                      onImageSelected(path);
                    }
                  },
                ),
                if (hasCurrent && onRemove != null) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.trash2, color: Colors.red, size: 22),
                    ),
                    title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.red)),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onRemove();
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Displays standard bottom sheet for Camera vs Gallery choice
  static Future<void> showPickerOptions({
    required BuildContext context,
    required ValueChanged<String> onImageSelected,
    String title = 'Select Image Source',
    double maxWidth = 1600,
    double maxHeight = 1600,
    int imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kDarkText,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: AppColors.kPrimary, size: 22),
                  ),
                  title: const Text('Take Photo (Camera)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Capture direct photo with camera', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final path = await pickImage(
                      source: ImageSource.camera,
                      preferredCameraDevice: preferredCameraDevice,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                      imageQuality: imageQuality,
                    );
                    if (path != null && path.isNotEmpty) {
                      onImageSelected(path);
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.image, color: AppColors.kPrimary, size: 22),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Select an image from device gallery', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final path = await pickImage(
                      source: ImageSource.gallery,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                      imageQuality: imageQuality,
                    );
                    if (path != null && path.isNotEmpty) {
                      onImageSelected(path);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Displays bottom sheet for Documents: Camera Photo, Gallery, or PDF/File
  static Future<void> showDocumentPickerOptions({
    required BuildContext context,
    required ValueChanged<String> onFileSelected,
    String title = 'Upload Document / Certificate',
    double maxWidth = 1600,
    double maxHeight = 1600,
    int imageQuality = 85,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kDarkText,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: AppColors.kPrimary, size: 22),
                  ),
                  title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Take a live photo of your physical document', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final path = await pickImage(
                      source: ImageSource.camera,
                      preferredCameraDevice: CameraDevice.rear,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                      imageQuality: imageQuality,
                    );
                    if (path != null && path.isNotEmpty) {
                      onFileSelected(path);
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.image, color: AppColors.kPrimary, size: 22),
                  ),
                  title: const Text('Choose Photo from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Pick document image from your gallery', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final path = await pickImage(
                      source: ImageSource.gallery,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                      imageQuality: imageQuality,
                    );
                    if (path != null && path.isNotEmpty) {
                      onFileSelected(path);
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.fileText, color: AppColors.kPrimary, size: 22),
                  ),
                  title: const Text('Browse PDF / File', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Upload PDF document or file', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    isPickingMedia = true;
                    try {
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      );
                      if (result != null && result.files.single.path != null) {
                        onFileSelected(result.files.single.path!);
                      }
                    } catch (e) {
                      debugPrint('[FilePicker] Error: $e');
                    } finally {
                      await Future.delayed(const Duration(milliseconds: 600));
                      isPickingMedia = false;
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
