import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cartkaro_partner_hub/core/constants/app_colors.dart';

ImageProvider? getSafeImageProvider(String? path, {ImageProvider? fallback}) {
  if (path == null || path.trim().isEmpty) return fallback;
  final cleanPath = path.trim();
  if (cleanPath.startsWith('assets/') || cleanPath.startsWith('assets')) {
    return AssetImage(cleanPath);
  }
  if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
    return NetworkImage(cleanPath);
  }
  if (cleanPath.startsWith('blob:')) {
    if (kIsWeb) {
      return NetworkImage(cleanPath);
    }
    return fallback;
  }
  if (!kIsWeb) {
    try {
      final file = File(cleanPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
  }
  return fallback;
}

class SafeImageWidget extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Key? imageKey;

  const SafeImageWidget({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.imageKey,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFallback = errorWidget ??
        Container(
          width: width,
          height: height,
          color: AppColors.kPrimary.withOpacity(0.07),
          child: Center(
            child: Icon(
              LucideIcons.image,
              color: AppColors.kPrimary.withOpacity(0.4),
              size: (width != null && width! < 40) ? 16 : 24,
            ),
          ),
        );

    if (imagePath == null || imagePath!.trim().isEmpty) {
      return defaultFallback;
    }

    final path = imagePath!.trim();

    if (path.startsWith('assets/') || path.startsWith('assets')) {
      return Image.asset(
        path,
        key: imageKey,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => defaultFallback,
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        key: imageKey,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => defaultFallback,
      );
    }

    if (path.startsWith('blob:')) {
      if (kIsWeb) {
        return Image.network(
          path,
          key: imageKey,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => defaultFallback,
        );
      }
      return defaultFallback;
    }

    if (!kIsWeb) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            key: imageKey,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => defaultFallback,
          );
        }
      } catch (_) {}
    }

    return defaultFallback;
  }
}
