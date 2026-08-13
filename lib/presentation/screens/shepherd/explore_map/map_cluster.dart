import 'dart:math' as math;

/// A pin on a map — a land, a vet, or a disease alert — reduced to just
/// what clustering needs (id, coordinates, type). Kept independent of
/// `google_maps_flutter`'s `LatLng` so the clustering algorithm is plain
/// Dart and unit-testable without the Maps SDK.
enum MapEntityType { land, vet, alert }

class MapEntity {
  final String id;
  final MapEntityType type;
  final double lat;
  final double lng;

  const MapEntity({required this.id, required this.type, required this.lat, required this.lng});
}

/// One or more [MapEntity]s that fall in the same grid cell at the current
/// zoom level, collapsed to a single pin. [entities.length == 1] means
/// "no clustering happened here" — render it as a normal marker; more than
/// one means render a cluster badge with a count.
class MapCluster {
  final double lat;
  final double lng;
  final List<MapEntity> entities;

  const MapCluster({required this.lat, required this.lng, required this.entities});

  bool get isCluster => entities.length > 1;
  MapEntityType? get soleType => entities.length == 1 ? entities.first.type : null;
}

/// Buckets [entities] into a lat/lng grid sized for [zoom] and collapses
/// each occupied cell into one [MapCluster]. Grid-based clustering rather
/// than a quadtree/supercluster: simpler, deterministic, and fully
/// unit-testable without a running Maps SDK — the right tradeoff here
/// since this environment has no way to visually verify marker rendering
/// on a real map. Re-run this whenever the camera's zoom/idle position
/// changes, not on every frame.
List<MapCluster> clusterEntities(List<MapEntity> entities, double zoom) {
  if (entities.isEmpty) return const [];
  final cellSize = _cellSizeForZoom(zoom);
  final buckets = <String, List<MapEntity>>{};

  for (final e in entities) {
    final key = '${(e.lat / cellSize).floor()}:${(e.lng / cellSize).floor()}';
    buckets.putIfAbsent(key, () => []).add(e);
  }

  return buckets.values.map((group) {
    final lat = group.map((e) => e.lat).reduce((a, b) => a + b) / group.length;
    final lng = group.map((e) => e.lng).reduce((a, b) => a + b) / group.length;
    return MapCluster(lat: lat, lng: lng, entities: group);
  }).toList();
}

/// Higher zoom = smaller cells = less aggressive clustering (eventually
/// every pin stands alone once zoomed in far enough); lower zoom = bigger
/// cells = pins further apart collapse into one cluster.
double _cellSizeForZoom(double zoom) {
  final clamped = zoom.clamp(2.0, 20.0);
  return 40.0 * math.pow(2, -clamped);
}
