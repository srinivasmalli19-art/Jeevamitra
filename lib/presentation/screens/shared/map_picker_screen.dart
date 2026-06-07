import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/common/jm_button.dart';

/// Full-screen map that lets the user drag a pin to pick a lat/lng.
/// Receives optional `extra: {'lat': double, 'lng': double}` for an initial position.
/// Pops `{'lat': double, 'lng': double}` on confirm, or null on cancel.
class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapCtrl;
  late LatLng _picked;

  static const _defaultCenter = LatLng(16.5, 80.6); // Andhra Pradesh centre

  @override
  void initState() {
    super.initState();
    _picked = widget.initialLat != null && widget.initialLng != null
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _defaultCenter;
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng pos) => setState(() => _picked = pos);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(null),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _picked,
              zoom: widget.initialLat != null ? 15 : 10,
            ),
            onMapCreated: (c) => _mapCtrl = c,
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('picked'),
                position: _picked,
                draggable: true,
                onDragEnd: (pos) => setState(() => _picked = pos),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Instruction chip at the top
          Positioned(
            top: AppSpacing.base,
            left: AppSpacing.base,
            right: AppSpacing.base,
            child: Material(
              elevation: 2,
              borderRadius: AppSpacing.cardRadius,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tap map or drag the pin to set land location',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Coordinate display + confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg)),
              ),
              padding: AppSpacing.screenPadding
                  .copyWith(bottom: AppSpacing.base + 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selected Location',
                                style: Theme.of(context).textTheme.labelMedium),
                            Text(
                              '${_picked.latitude.toStringAsFixed(6)}, '
                              '${_picked.longitude.toStringAsFixed(6)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.base),
                  JmButton(
                    label: 'Confirm Location',
                    leadingIcon: Icons.check_rounded,
                    onPressed: () => context.pop({
                      'lat': _picked.latitude,
                      'lng': _picked.longitude,
                    }),
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
