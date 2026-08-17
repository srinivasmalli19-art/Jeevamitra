import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/domain/entities/user_profile_type.dart';

void main() {
  group('UserProfileType.backendRole', () {
    test('livestockOwner maps to the existing shepherd role', () {
      expect(UserProfileType.livestockOwner.backendRole, 'shepherd');
    });

    test('fodderLandProvider maps to the existing farmer role', () {
      expect(UserProfileType.fodderLandProvider.backendRole, 'farmer');
    });

    test('both maps to farmer (a documented default, never a restriction)', () {
      expect(UserProfileType.both.backendRole, 'farmer');
    });
  });

  group('UserProfileType.fromStorageValue / storageValue', () {
    test('every value round-trips through its own storage value', () {
      for (final type in UserProfileType.values) {
        expect(UserProfileType.fromStorageValue(type.storageValue), type);
      }
    });

    test('returns null for null, empty, or unrecognized values', () {
      expect(UserProfileType.fromStorageValue(null), isNull);
      expect(UserProfileType.fromStorageValue(''), isNull);
      expect(UserProfileType.fromStorageValue('farmer'), isNull);
    });
  });

  group('UserProfileType.inferFromRole', () {
    test('shepherd infers livestockOwner', () {
      expect(UserProfileType.inferFromRole('shepherd'), UserProfileType.livestockOwner);
    });

    test('farmer infers fodderLandProvider', () {
      expect(UserProfileType.inferFromRole('farmer'), UserProfileType.fodderLandProvider);
    });

    test('an unrecognized role falls back to fodderLandProvider, not a crash', () {
      expect(UserProfileType.inferFromRole('anything-else'),
          UserProfileType.fodderLandProvider);
    });
  });
}
