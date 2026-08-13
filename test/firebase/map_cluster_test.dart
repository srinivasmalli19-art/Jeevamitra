import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/presentation/screens/shepherd/explore_map/map_cluster.dart';

void main() {
  group('clusterEntities', () {
    test('empty input returns no clusters', () {
      expect(clusterEntities(const [], 12), isEmpty);
    });

    test('a single entity produces one non-cluster pin', () {
      const entity = MapEntity(id: 'a', type: MapEntityType.land, lat: 16.3, lng: 80.4);
      final result = clusterEntities([entity], 12);
      expect(result, hasLength(1));
      expect(result.first.isCluster, isFalse);
      expect(result.first.soleType, MapEntityType.land);
    });

    test('two entities very close together collapse into one cluster at low zoom', () {
      final entities = [
        const MapEntity(id: 'a', type: MapEntityType.land, lat: 16.300, lng: 80.400),
        const MapEntity(id: 'b', type: MapEntityType.vet, lat: 16.301, lng: 80.401),
      ];
      final result = clusterEntities(entities, 4); // very zoomed out
      expect(result, hasLength(1));
      expect(result.first.isCluster, isTrue);
      expect(result.first.entities, hasLength(2));
    });

    test('the same two entities stay separate at high zoom', () {
      final entities = [
        const MapEntity(id: 'a', type: MapEntityType.land, lat: 16.300, lng: 80.400),
        const MapEntity(id: 'b', type: MapEntityType.vet, lat: 16.500, lng: 80.700),
      ];
      final result = clusterEntities(entities, 18); // zoomed in close
      expect(result, hasLength(2));
      expect(result.every((c) => !c.isCluster), isTrue);
    });

    test('cluster centroid is the average position of its members', () {
      final entities = [
        const MapEntity(id: 'a', type: MapEntityType.land, lat: 16.0, lng: 80.0),
        const MapEntity(id: 'b', type: MapEntityType.land, lat: 16.0, lng: 80.0),
      ];
      final result = clusterEntities(entities, 4);
      expect(result, hasLength(1));
      expect(result.first.lat, 16.0);
      expect(result.first.lng, 80.0);
    });

    test('far-apart entities never merge regardless of zoom', () {
      final entities = [
        const MapEntity(id: 'a', type: MapEntityType.land, lat: 10.0, lng: 70.0),
        const MapEntity(id: 'b', type: MapEntityType.vet, lat: 25.0, lng: 90.0),
      ];
      final result = clusterEntities(entities, 2);
      expect(result, hasLength(2));
    });

    test('soleType is null for an actual cluster', () {
      final entities = [
        const MapEntity(id: 'a', type: MapEntityType.land, lat: 16.300, lng: 80.400),
        const MapEntity(id: 'b', type: MapEntityType.vet, lat: 16.301, lng: 80.401),
      ];
      final result = clusterEntities(entities, 4);
      expect(result.first.soleType, isNull);
    });

    test('alert entities cluster the same way as land/vet entities', () {
      const entity = MapEntity(id: 'a1', type: MapEntityType.alert, lat: 16.3, lng: 80.4);
      final result = clusterEntities([entity], 12);
      expect(result, hasLength(1));
      expect(result.first.soleType, MapEntityType.alert);
    });
  });
}
