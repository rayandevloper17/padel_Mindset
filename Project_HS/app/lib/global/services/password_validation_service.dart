import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Service for real-time password validation with strength indicator
class PasswordValidationService extends GetxController {
  /// Password validation rules
  static const int minLength = 10;
  static final RegExp hasUpperCase = RegExp(r'[A-Z]');
  static final RegExp hasLowerCase = RegExp(r'[a-z]');
  static final RegExp hasNumbers = RegExp(r'[0-9]');
  static final RegExp hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// Observable for password validation state
  final RxString password = ''.obs;
  final RxBool isValidating = false.obs;
  final Rx<PasswordStrength> strength = PasswordStrength.weak.obs;

  /// Validation results
  final RxBool hasMinLength = false.obs;
  final RxBool hasUpperCaseChar = false.obs;
  final RxBool hasLowerCaseChar = false.obs;
  final RxBool hasNumber = false.obs;
  final RxBool hasSpecialChar = false.obs;
  final RxBool isPasswordValid = false.obs;

  /// Validate password and update observables
  void validatePassword(String value) {
    password.value = value;
    
    // Validate each requirement
    hasMinLength.value = value.length >= minLength;
    hasUpperCaseChar.value = hasUpperCase.hasMatch(value);
    hasLowerCaseChar.value = hasLowerCase.hasMatch(value);
    hasNumber.value = hasNumbers.hasMatch(value);
    hasSpecialChar.value = hasSpecialCharacters.hasMatch(value);
    
    // Calculate overall validity
    isPasswordValid.value = hasMinLength.value && 
                           hasUpperCaseChar.value && 
                           hasLowerCaseChar.value && 
                           hasNumber.value && 
                           hasSpecialChar.value;
    
    // Calculate password strength
    _calculatePasswordStrength();
  }

  /// Calculate password strength based on fulfilled requirements
  void _calculatePasswordStrength() {
    int fulfilledRequirements = 0;
    
    if (hasMinLength.value) fulfilledRequirements++;
    if (hasUpperCaseChar.value) fulfilledRequirements++;
    if (hasLowerCaseChar.value) fulfilledRequirements++;
    if (hasNumber.value) fulfilledRequirements++;
    if (hasSpecialChar.value) fulfilledRequirements++;
    
    if (fulfilledRequirements <= 2) {
      strength.value = PasswordStrength.weak;
    } else if (fulfilledRequirements <= 4) {
      strength.value = PasswordStrength.medium;
    } else {
      strength.value = PasswordStrength.strong;
    }
  }

  /// Get strength color based on password strength
  Color getStrengthColor() {
    switch (strength.value) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  /// Get strength text based on password strength
  String getStrengthText() {
    switch (strength.value) {
      case PasswordStrength.weak:
        return 'Faible';
      case PasswordStrength.medium:
        return 'Moyen';
      case PasswordStrength.strong:
        return 'Fort';
    }
  }

  /// Get validation icon color for a specific requirement
  Color getRequirementColor(bool isFulfilled) {
    return isFulfilled ? Colors.green : Colors.grey;
  }

  /// Get validation icon for a specific requirement
  IconData getRequirementIcon(bool isFulfilled) {
    return isFulfilled ? Icons.check_circle : Icons.circle_outlined;
  }

  /// Reset validation state
  void resetValidation() {
    password.value = '';
    hasMinLength.value = false;
    hasUpperCaseChar.value = false;
    hasLowerCaseChar.value = false;
    hasNumber.value = false;
    hasSpecialChar.value = false;
    isPasswordValid.value = false;
    strength.value = PasswordStrength.weak;
  }
}

/// Password strength enumeration
enum PasswordStrength {
  weak,
  medium,
  strong,
}