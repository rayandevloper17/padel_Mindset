import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'notification_service.dart';

/// Simple HTTP helper for API call tracking and error handling
/// Provides clean console logging and user notifications for API errors
class ApiHelper {
  
  /// Log HTTP request details
  static void logRequest(String method, String url, {Map<String, String>? headers, dynamic body}) {
    try {
      developer.log(
        '📤 API REQUEST',
        name: 'API',
        error: {
          'method': method,
          'url': url,
          'headers': headers,
          'body': body,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      developer.log(
        '❌ Error logging request',
        name: 'API',
        error: e,
      );
    }
  }

  /// Log HTTP response details and handle errors
  static void logResponse(http.Response response) {
    try {
      final statusCode = response.statusCode;
      final isSuccess = statusCode >= 200 && statusCode < 300;
      
      // Log response details
      developer.log(
        isSuccess ? '✅ API RESPONSE' : '❌ API ERROR',
        name: 'API',
        error: {
          'statusCode': statusCode,
          'url': response.request?.url.toString(),
          'method': response.request?.method,
          'body': response.body,
          'headers': response.headers,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Handle different error scenarios
      if (!isSuccess) {
        _handleApiError(statusCode, response.body);
      }
    } catch (e) {
      developer.log(
        '❌ Error logging response',
        name: 'API',
        error: e,
      );
    }
  }

  /// Handle API errors with appropriate user notifications
  static void _handleApiError(int statusCode, String? responseBody) {
    String errorMessage = 'Une erreur inconnue s\'est produite';
    String errorTitle = 'Erreur';

    try {
      // Try to parse error message from response body
      if (responseBody != null) {
        final decodedBody = json.decode(responseBody);
        if (decodedBody is Map && decodedBody.containsKey('message')) {
          errorMessage = decodedBody['message'].toString();
        } else if (decodedBody is Map && decodedBody.containsKey('error')) {
          errorMessage = decodedBody['error'].toString();
        } else if (decodedBody is String) {
          errorMessage = decodedBody;
        }
      }
    } catch (e) {
      // If parsing fails, use status code based messages
      errorMessage = _getStatusCodeMessage(statusCode);
    }

    // Customize error title based on status code
    if (statusCode >= 400 && statusCode < 500) {
      errorTitle = 'Erreur client';
    } else if (statusCode >= 500) {
      errorTitle = 'Erreur serveur';
    }

    // Show user-friendly error notification
    NotificationService.showError(
      title: errorTitle,
      message: errorMessage,
    );
  }

  /// Get user-friendly message based on HTTP status code
  static String _getStatusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide';
      case 401:
        return 'Non autorisé';
      case 403:
        return 'Accès refusé';
      case 404:
        return 'Ressource non trouvée';
      case 409:
        return 'Conflit - Email déjà utilisé';
      case 422:
        return 'Données invalides';
      case 500:
        return 'Erreur serveur interne';
      case 502:
        return 'Erreur de passerelle';
      case 503:
        return 'Service indisponible';
      case 504:
        return 'Délai d\'attente dépassé';
      default:
        return 'Erreur inattendue (Code: $statusCode)';
    }
  }
}