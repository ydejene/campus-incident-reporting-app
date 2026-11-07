import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_profile.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';

void main() {
  group('UserProfile and UserRole', () {
    test('UserRole mapping from string', () {
      expect(UserRole.fromString('student'), UserRole.student);
      expect(UserRole.fromString('staff'), UserRole.staff);
      expect(UserRole.fromString('unknown'), UserRole.student);
      expect(UserRole.student.isStudent, isTrue);
      expect(UserRole.staff.isStaff, isTrue);
    });

    test('UserProfile parses from map and serializes correctly', () {
      final now = DateTime(2026, 11, 7, 10, 0);
      final map = {
        'uid': 'user-123',
        'displayName': 'Aline Mugisha',
        'email': 'a.mugisha@alustudent.com',
        'role': 'student',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final profile = UserProfile.fromMap(map, uid: 'user-123');

      expect(profile.uid, 'user-123');
      expect(profile.displayName, 'Aline Mugisha');
      expect(profile.email, 'a.mugisha@alustudent.com');
      expect(profile.role, UserRole.student);
      expect(profile.createdAt, now);
      expect(profile.updatedAt, now);

      final serialized = profile.toMap();
      expect(serialized['uid'], 'user-123');
      expect(serialized['role'], 'student');
      expect(serialized['email'], 'a.mugisha@alustudent.com');

      final firestoreMap = profile.toFirestore();
      expect(firestoreMap['role'], 'student');
    });

    test('UserProfile copyWith updates fields properly', () {
      final now = DateTime(2026, 11, 7, 10, 0);
      final profile = UserProfile(
        uid: 'user-123',
        displayName: 'Aline Mugisha',
        email: 'a.mugisha@alustudent.com',
        role: UserRole.student,
        createdAt: now,
        updatedAt: now,
      );

      final updated = profile.copyWith(
        displayName: 'Aline M.',
        role: UserRole.staff,
      );

      expect(updated.displayName, 'Aline M.');
      expect(updated.role, UserRole.staff);
      expect(updated.uid, 'user-123');
      expect(profile == updated, isFalse);
    });
  });
}

