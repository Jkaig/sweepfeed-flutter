import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'loading_indicator.dart';

/// An optimized image widget with built-in caching, placeholder, and error handling
class OptimizedImage extends StatelessWidget {
  const OptimizedImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildDefaultErrorWidget(),
      // Optimize cache settings
      maxWidthDiskCache: 1920,
      maxHeightDiskCache: 1920,
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildDefaultPlaceholder() => Container(
      width: width,
      height: height,
      color: AppColors.primaryLight,
      child: Center(
        child: LoadingIndicator(
          size: height != null && height! < 100 ? 20 : 30,
        ),
      ),
    );

  Widget _buildDefaultErrorWidget() => Container(
      width: width,
      height: height,
      color: AppColors.primaryLight,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textMuted,
        size: 48,
      ),
    );
}

