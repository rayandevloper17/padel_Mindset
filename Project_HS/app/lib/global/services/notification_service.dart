import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Modern notification service for displaying success/error messages
/// with professional design and animations
class NotificationService {
  static const Duration _duration = Duration(seconds: 4);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFF44336);
  static const Color _warningColor = Color(0xFFFF9800);
  static const Color _infoColor = Color(0xFF2196F3);

  /// Show success notification with modern design
  static void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    SnackPosition? position,
  }) {
    Get.snackbar(
      title,
      message,
      duration: duration ?? _duration,
      snackPosition: position ?? SnackPosition.TOP,
      backgroundColor: _successColor.withValues(alpha: 0.9),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
      shouldIconPulse: true,
      snackStyle: SnackStyle.FLOATING,
      boxShadows: [
        BoxShadow(
          color: _successColor.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  /// Show error notification with modern design
  static void showError({
    required String title,
    required String message,
    Duration? duration,
    SnackPosition? position,
  }) {
    Get.snackbar(
      title,
      message,
      duration: duration ?? _duration,
      snackPosition: position ?? SnackPosition.TOP,
      backgroundColor: _errorColor.withValues(alpha: 0.9),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
      shouldIconPulse: true,
      snackStyle: SnackStyle.FLOATING,
      boxShadows: [
        BoxShadow(
          color: _errorColor.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  /// Show warning notification with modern design
  static void showWarning({
    required String title,
    required String message,
    Duration? duration,
    SnackPosition? position,
  }) {
    Get.snackbar(
      title,
      message,
      duration: duration ?? _duration,
      snackPosition: position ?? SnackPosition.TOP,
      backgroundColor: _warningColor.withValues(alpha: 0.9),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      icon: const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 28),
      shouldIconPulse: true,
      snackStyle: SnackStyle.FLOATING,
      boxShadows: [
        BoxShadow(
          color: _warningColor.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  /// Show info notification with modern design
  static void showInfo({
    required String title,
    required String message,
    Duration? duration,
    SnackPosition? position,
  }) {
    Get.snackbar(
      title,
      message,
      duration: duration ?? _duration,
      snackPosition: position ?? SnackPosition.TOP,
      backgroundColor: _infoColor.withValues(alpha: 0.9),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      icon: const Icon(Icons.info_outline, color: Colors.white, size: 28),
      shouldIconPulse: true,
      snackStyle: SnackStyle.FLOATING,
      boxShadows: [
        BoxShadow(
          color: _infoColor.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  /// Show connection failed notification
  static void showConnectionFailed({
    String? message,
    Duration? duration,
  }) {
    showError(
      title: 'Connexion échouée',
      message: message ?? 'Impossible de se connecter au serveur. Veuillez vérifier votre connexion internet.',
      duration: duration ?? const Duration(seconds: 6),
    );
  }

  /// Show validation error with field-specific message
  static void showValidationError({
    required String field,
    required String message,
  }) {
    showError(
      title: 'Erreur de validation',
      message: '$field: $message',
      duration: const Duration(seconds: 3),
    );
  }

  /// Dismiss all notifications
  static void dismissAll() {
    Get.closeAllSnackbars();
  }
}