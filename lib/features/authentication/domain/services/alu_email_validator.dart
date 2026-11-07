import '../models/user_role.dart';

class ALUEmailValidator {
  ALUEmailValidator._();

  static const String studentDomain = 'alustudent.com';
  static const String staffDomain = 'alueducation.com';

  static String normalize(String email) {
    return email.trim().toLowerCase();
  }

  static bool isStudentEmail(String email) {
    final normalized = normalize(email);
    final parts = normalized.split('@');
    if (parts.length != 2 || parts[0].isEmpty) {
      return false;
    }
    return parts[1] == studentDomain;
  }

  static bool isStaffEmail(String email) {
    final normalized = normalize(email);
    final parts = normalized.split('@');
    if (parts.length != 2 || parts[0].isEmpty) {
      return false;
    }
    return parts[1] == staffDomain;
  }

  static bool isEligibleEmail(String email) {
    return isStudentEmail(email) || isStaffEmail(email);
  }

  static UserRole? expectedRoleForEmail(String email) {
    if (isStudentEmail(email)) {
      return UserRole.student;
    }
    if (isStaffEmail(email)) {
      return UserRole.staff;
    }
    return null;
  }

  static String? validateStudentRegistration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Student email is required';
    }
    final normalized = normalize(value);
    if (!normalized.contains('@') || normalized.split('@').length != 2) {
      return 'Enter a valid email address';
    }
    if (!isStudentEmail(normalized)) {
      return 'Only ALU student emails (@$studentDomain) can register';
    }
    return null;
  }

  static String? validateLogin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final normalized = normalize(value);
    if (!normalized.contains('@') || normalized.split('@').length != 2) {
      return 'Enter a valid email address';
    }
    if (!isEligibleEmail(normalized)) {
      return 'Use an authorized ALU email (@$studentDomain or @$staffDomain)';
    }
    return null;
  }
}

