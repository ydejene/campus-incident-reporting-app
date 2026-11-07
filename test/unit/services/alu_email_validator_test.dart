import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/models/user_role.dart';
import 'package:campus_incident_reporting_app/features/authentication/domain/services/alu_email_validator.dart';

void main() {
  group('ALUEmailValidator', () {
    test('normalizes casing and trims whitespace', () {
      expect(
        ALUEmailValidator.normalize('  A.Mugisha@ALUSTUDENT.COM  '),
        'a.mugisha@alustudent.com',
      );
    });

    test('validates student email addresses correctly', () {
      expect(ALUEmailValidator.isStudentEmail('john.doe@alustudent.com'), isTrue);
      expect(ALUEmailValidator.isStudentEmail('J.DOE@ALUSTUDENT.COM'), isTrue);
      expect(ALUEmailValidator.isStudentEmail('john.doe@alueducation.com'), isFalse);
      expect(ALUEmailValidator.isStudentEmail('john.doe@gmail.com'), isFalse);
      expect(ALUEmailValidator.isStudentEmail('@alustudent.com'), isFalse);
      expect(ALUEmailValidator.isStudentEmail('invalid-email'), isFalse);
    });

    test('validates staff email addresses correctly', () {
      expect(ALUEmailValidator.isStaffEmail('facilitator@alueducation.com'), isTrue);
      expect(ALUEmailValidator.isStaffEmail('FACILITATOR@ALUEDUCATION.COM'), isTrue);
      expect(ALUEmailValidator.isStaffEmail('facilitator@alustudent.com'), isFalse);
      expect(ALUEmailValidator.isStaffEmail('facilitator@gmail.com'), isFalse);
      expect(ALUEmailValidator.isStaffEmail('@alueducation.com'), isFalse);
    });

    test('validates general ALU eligibility', () {
      expect(ALUEmailValidator.isEligibleEmail('student@alustudent.com'), isTrue);
      expect(ALUEmailValidator.isEligibleEmail('staff@alueducation.com'), isTrue);
      expect(ALUEmailValidator.isEligibleEmail('visitor@external.org'), isFalse);
      expect(ALUEmailValidator.isEligibleEmail('personal@gmail.com'), isFalse);
    });

    test('resolves expected role based on email domain', () {
      expect(
        ALUEmailValidator.expectedRoleForEmail('student@alustudent.com'),
        UserRole.student,
      );
      expect(
        ALUEmailValidator.expectedRoleForEmail('staff@alueducation.com'),
        UserRole.staff,
      );
      expect(
        ALUEmailValidator.expectedRoleForEmail('user@gmail.com'),
        isNull,
      );
    });

    test('student registration form validation', () {
      expect(ALUEmailValidator.validateStudentRegistration(''), isNotNull);
      expect(ALUEmailValidator.validateStudentRegistration('invalid'), isNotNull);
      expect(
        ALUEmailValidator.validateStudentRegistration('staff@alueducation.com'),
        isNotNull,
      );
      expect(
        ALUEmailValidator.validateStudentRegistration('student@alustudent.com'),
        isNull,
      );
    });

    test('login form validation', () {
      expect(ALUEmailValidator.validateLogin(''), isNotNull);
      expect(ALUEmailValidator.validateLogin('notanemail'), isNotNull);
      expect(ALUEmailValidator.validateLogin('user@gmail.com'), isNotNull);
      expect(ALUEmailValidator.validateLogin('student@alustudent.com'), isNull);
      expect(ALUEmailValidator.validateLogin('staff@alueducation.com'), isNull);
    });
  });
}

