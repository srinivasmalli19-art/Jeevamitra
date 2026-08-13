import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/disease_alert_model.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/alerts/disease_alert_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/retry_card.dart';
import '../../shepherd/explore_map/map_cluster.dart';
import 'alert_severity.dart';

const _alertMapRadiusKm = 150.0;

/// Disease Alerts on a map: severity-colored markers, grid clustering
/// (reusing the exact `MapEntity`/`clusterEntities` primitives built for
/// the unified Explore map in Sprint 2 Batch 2D — no new clustering
/// algorithm), tap a marker to open its Alert Detail screen.
class AlertMapScreen extends ConsumerStatefulWidget {
  const AlertMapScreen({super.key});

  @override
  ConsumerState<AlertMapScreen> createState() => _AlertMapScreenState();
}

class _AlertMapScreenState extends ConsumerState<AlertMapScreen> {
  GoogleMapController? _mapCtrl;
  double _zoom = 9;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = ref.read(locationProvider);
      if (!loc.hasValue || loc.valueOrNull == null) {
        ref.read(locationProvider.notifier).fetch();
      }
    });
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _focusOn(double lat, double lng) async {
    await _mapCtrl?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), (_zoom + 2).clamp(2, 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locAsync = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc.alertsMapTitle)),
      body: locAsync.isLoading
          ? const Center(child: JmLoading())
          : locAsync.hasError || locAsync.valueOrNull == null
              ? EmptyStateCard(
                  icon: Icons.location_off_rounded,
                  title: loc.locationRequiredTitle,
                  subtitle: loc.locationNeededAlertsMapMsg,
                  buttonLabel: loc.enableLocationBtn,
                  onButtonTap: () => ref.read(locationProvider.notifier).fetch(),
                )
              : _AlertMap(
                  lat: locAsync.value!.lat,
                  lng: locAsync.value!.lng,
                  zoom: _zoom,
                  loc: loc,
                  onMapCreated: (c) => _mapCtrl = c,
                  onCameraMove: (pos) => _zoom = pos.zoom,
                  onCameraIdle: () => setState(() {}),
                  onClusterTap: _focusOn,
                ),
    );
  }
}

class _AlertMap extends ConsumerWidget {
  final double lat, lng, zoom;
  final AppLocalizations loc;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<CameraPosition> onCameraMove;
  final VoidCallback onCameraIdle;
  final Future<void> Function(double lat, double lng) onClusterTap;

  const _AlertMap({
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.loc,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCameraIdle,
    required this.onClusterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync =
        ref.watch(nearbyAlertsProvider((lat: lat, lng: lng, radiusKm: _alertMapRadiusKm)));

    return alertsAsync.when(
      loading: () => const Center(child: JmLoading()),
      error: (e, _) => RetryCard(error: e, onRetry: () => ref.invalidate(nearbyAlertsProvider)),
      data: (alerts) {
        final byId = {for (final a in alerts) a.id: a};
        final entities = alerts
            .map((a) => MapEntity(id: a.id, type: MapEntityType.alert, lat: a.lat, lng: a.lng))
            .toList();
        final clusters = clusterEntities(entities, zoom);

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: zoom),
              onMapCreated: onMapCreated,
              onCameraMove: onCameraMove,
              onCameraIdle: onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _buildMarkers(context, clusters, byId),
            ),
            if (alerts.isEmpty)
              Positioned(
                top: AppSpacing.base,
                left: 16,
                right: 16,
                child: _NoAlertsBanner(loc: loc),
              ),
          ],
        );
      },
    );
  }

  Set<Marker> _buildMarkers(
      BuildContext context, List<MapCluster> clusters, Map<String, DiseaseAlertModel> byId) {
    return clusters.map((cluster) {
      if (!cluster.isCluster) {
        final entity = cluster.entities.first;
        final alert = byId[entity.id];
        final severity = AlertSeverity.of(alert?.severity ?? 'low');
        return Marker(
          markerId: MarkerId('alert-${entity.id}'),
          position: LatLng(cluster.lat, cluster.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(severity)),
          infoWindow: InfoWindow(title: alert?.title ?? loc.diseaseAlertFallbackTitle),
          onTap: () => context.push(RouteConstants.alertDetail(entity.id)),
        );
      }
      final id = cluster.entities.map((e) => e.id).join('-');
      return Marker(
        markerId: MarkerId('cluster-$id'),
        position: LatLng(cluster.lat, cluster.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: loc.alertsHereMsg(cluster.entities.length)),
        onTap: () => onClusterTap(cluster.lat, cluster.lng),
      );
    }).toSet();
  }

  double _hueFor(AlertSeverity severity) {
    if (severity == AlertSeverity.critical) return BitmapDescriptor.hueRed;
    if (severity == AlertSeverity.high) return BitmapDescriptor.hueOrange;
    if (severity == AlertSeverity.medium) return BitmapDescriptor.hueAzure;
    return BitmapDescriptor.hueYellow;
  }
}

class _NoAlertsBanner extends StatelessWidget {
  final AppLocalizations loc;
  const _NoAlertsBanner({required this.loc});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Flexible(
                child: Text(
                    loc.noActiveAlertsRadiusMsg(_alertMapRadiusKm.toInt()))),
          ],
        ),
      ),
    );
  }
}
