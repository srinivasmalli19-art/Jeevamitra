import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A vet's profile circle: their photo when it loads, their initial
/// letter otherwise — including when [profileImageUrl] is set but the
/// URL fails to load. Before this existed, `PremiumVetCard` and
/// `VetDetailScreen` each built this inline with the fallback initial
/// gated on `profileImageUrl == null`, so a *broken* (non-null but
/// unreachable) URL rendered a blank circle instead of falling back —
/// the fallback branch never ran because the URL wasn't null, it just
/// didn't load.
class VetAvatar extends StatefulWidget {
  final String? profileImageUrl;
  final String name;
  final double radius;

  const VetAvatar(
      {super.key,
      required this.profileImageUrl,
      required this.name,
      required this.radius});

  @override
  State<VetAvatar> createState() => _VetAvatarState();
}

class _VetAvatarState extends State<VetAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(VetAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileImageUrl != widget.profileImageUrl) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final showImage = widget.profileImageUrl != null && !_failed;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.primaryContainer,
      backgroundImage: showImage
          ? CachedNetworkImageProvider(widget.profileImageUrl!)
          : null,
      onBackgroundImageError:
          showImage ? (_, __) => setState(() => _failed = true) : null,
      child: showImage
          ? null
          : Text(
              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'V',
              style: TextStyle(
                fontSize: widget.radius * 0.75,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
    );
  }
}
