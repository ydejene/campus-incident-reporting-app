enum UserRole {
  student('student', 'Student'),
  staff('staff', 'Staff');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  bool get isStudent => this == UserRole.student;
  bool get isStaff => this == UserRole.staff;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value || role.name == value,
      orElse: () => UserRole.student,
    );
  }
}

