import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Standard way to render a land photo anywhere in the app (My Lands
/// cards, Land Detail carousel, shepherd discovery/detail screens, the
/// photo manager grid): disk+memory cached, with a shimmer-style
/// placeholder while loading and a neutral fallback icon on error so a
/// broken/expired URL never shows a red error box to a farmer or
/// shepherd.
class CachedFarmImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CachedFarmImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _errorFallback(),
    );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _errorFallback() => Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.landscape_rounded, size: 32, color: AppColors.textDisabled),
      );
}
