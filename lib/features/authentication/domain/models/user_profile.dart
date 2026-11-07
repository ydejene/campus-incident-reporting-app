import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/datetime_utils.dart';
import 'user_role.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserProfile(
      uid: uid ?? (map['uid'] as String? ?? ''),
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      createdAt: DateTimeUtils.toDateTime(map['createdAt']),
      updatedAt: DateTimeUtils.toDateTime(map['updatedAt']),
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile.fromMap(data, uid: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'role': role.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'role': role.value,
      'createdAt': DateTimeUtils.toTimestamp(createdAt),
      'updatedAt': DateTimeUtils.toTimestamp(updatedAt),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          displayName == other.displayName &&
          email == other.email &&
          role == other.role &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      uid.hashCode ^
      displayName.hashCode ^
      email.hashCode ^
      role.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}

