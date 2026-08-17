// Backward-compatibility coverage for the Profile Restructure: existing
// farmer/shepherd accounts (created before UserDoc.profileType existed)
// must keep working and get a sensible personalization default without
// any migration.
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/domain/entities/user_profile_type.dart';
import 'package:jeevamitra/presentation/providers/auth/user_doc.dart';

void main() {
  group('UserDoc backward compatibility', () {
    test('a legacy farmer doc with no profileType still has role == farmer '
        'and infers fodderLandProvider for personalization', () {
      const doc = UserDoc(
        uid: 'legacy-1',
        phone: '+919876543210',
        role: 'farmer',
        name: 'Ravi',
        isProfileComplete: true,
      );
      expect(doc.role, 'farmer');
      expect(doc.isFarmer, isTrue);
      expect(doc.profileType, isNull);
      expect(doc.effectiveProfileType, UserProfileType.fodderLandProvider);
    });

    test('a legacy shepherd doc with no profileType still has role == shepherd '
        'and infers livestockOwner for personalization', () {
      const doc = UserDoc(
        uid: 'legacy-2',
        phone: '+919876543211',
        role: 'shepherd',
        name: 'Suresh',
        isProfileComplete: true,
      );
      expect(doc.role, 'shepherd');
      expect(doc.isShepherd, isTrue);
      expect(doc.profileType, isNull);
      expect(doc.effectiveProfileType, UserProfileType.livestockOwner);
    });

    test('an explicit profileType overrides role-based inference without '
        'changing the stored backend role', () {
      const doc = UserDoc(
        uid: 'new-1',
        phone: '+919876543212',
        role: 'farmer',
        name: 'Lakshmi',
        isProfileComplete: true,
        profileType: 'both',
      );
      expect(doc.role, 'farmer'); // unchanged backend value
      expect(doc.effectiveProfileType, UserProfileType.both);
    });

    test('toMap only includes profileType when it is set — legacy write '
        'shape is preserved for docs that never chose one', () {
      const withType = UserDoc(
        uid: 'u1',
        phone: '+91',
        role: 'shepherd',
        name: 'X',
        isProfileComplete: true,
        profileType: 'livestockOwner',
      );
      expect(withType.toMap()['profileType'], 'livestockOwner');

      const withoutType = UserDoc(
        uid: 'u2',
        phone: '+91',
        role: 'shepherd',
        name: 'X',
        isProfileComplete: true,
      );
      expect(withoutType.toMap().containsKey('profileType'), isFalse);
    });
  });
}
