import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Service for checking email availability with modern UI feedback
class EmailValidationService extends GetxController {
  static const String _baseUrl =
      'http://127.0.0.1:3000/api'; // Adjust as needed

  /// Observable for email validation state
  final RxBool isCheckingEmail = false.obs;
  final RxBool isEmailAvailable = true.obs;
  final RxString emailValidationMessage = ''.obs;
  final Rx<EmailValidationStatus> validationStatus =
      EmailValidationStatus.idle.obs;

  /// Timer for debouncing email checks
  Timer? _debounceTimer;

  /// Check if email is available
  Future<void> checkEmailAvailability(String email) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Reset state
    isCheckingEmail.value = false;
    isEmailAvailable.value = true;
    emailValidationMessage.value = '';
    validationStatus.value = EmailValidationStatus.idle;

    // Validate email format first
    if (email.isEmpty || !_isValidEmailFormat(email)) {
      validationStatus.value = EmailValidationStatus.invalid;
      emailValidationMessage.value = 'Format d\'email invalide';
      return;
    }

    // Set checking state
    isCheckingEmail.value = true;
    validationStatus.value = EmailValidationStatus.checking;

    // Debounce the API call
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/utilisateur/check-email/$email'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          isEmailAvailable.value = data['available'] ?? true;

          if (isEmailAvailable.value) {
            validationStatus.value = EmailValidationStatus.available;
            emailValidationMessage.value = 'Email disponible';
          } else {
            validationStatus.value = EmailValidationStatus.unavailable;
            emailValidationMessage.value = 'Email déjà utilisé';
          }
        } else {
          // If endpoint doesn't exist, assume email is available
          isEmailAvailable.value = true;
          validationStatus.value = EmailValidationStatus.available;
          emailValidationMessage.value = '';
        }
      } catch (e) {
        // On error, assume email is available to allow registration
        isEmailAvailable.value = true;
        validationStatus.value = EmailValidationStatus.available;
        emailValidationMessage.value = '';
      } finally {
        isCheckingEmail.value = false;
      }
    });
  }

  /// Validate email format
  bool _isValidEmailFormat(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Get validation icon based on status
  IconData getValidationIcon() {
    switch (validationStatus.value) {
      case EmailValidationStatus.checking:
        return Icons.sync;
      case EmailValidationStatus.available:
        return Icons.check_circle;
      case EmailValidationStatus.unavailable:
        return Icons.cancel;
      case EmailValidationStatus.invalid:
        return Icons.error_outline;
      case EmailValidationStatus.idle:
        return Icons.email_outlined;
    }
  }

  /// Get validation color based on status
  Color getValidationColor() {
    switch (validationStatus.value) {
      case EmailValidationStatus.checking:
        return Colors.orange;
      case EmailValidationStatus.available:
        return Colors.green;
      case EmailValidationStatus.unavailable:
        return Colors.red;
      case EmailValidationStatus.invalid:
        return Colors.red;
      case EmailValidationStatus.idle:
        return Colors.grey;
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }
}

/// Email validation status enum
enum EmailValidationStatus { idle, checking, available, unavailable, invalid }
