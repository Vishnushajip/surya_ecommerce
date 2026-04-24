import './cached_network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class AppCachedImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const AppCachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.secondaryDark;
    final child = (url == null || url!.isEmpty)
        ? _Fallback(bg: effectiveBg)
        : CachedNetworkImageWidget(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: _Shimmer(bg: effectiveBg),
            errorWidget: _Fallback(bg: effectiveBg),
          );

    if (borderRadius == null) return child;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: ColoredBox(color: effectiveBg, child: child),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final Color bg;
  const _Shimmer({required this.bg});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: bg,
      highlightColor: AppColors.borderSoft,
      child: Container(color: bg),
    );
  }
}

class _Fallback extends StatelessWidget {
  final Color bg;
  const _Fallback({required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: const Icon(Icons.image, color: AppColors.softGrey, size: 48),
    );
  }
}

