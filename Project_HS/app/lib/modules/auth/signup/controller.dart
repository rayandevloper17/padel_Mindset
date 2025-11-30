import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:app/services/api_service.dart';

// Basic User model (adjust fields)
class User {
  final int id;
  final String email;
  // Add other user fields you need

  User({required this.id, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      email: json['email']?.toString() ?? '',
    );
  }
}

class SignControllerGetx extends GetxController {
  // Resolve base URL depending on platform/environment
  static String _resolveBaseUrl() {
    const String envBase = String.fromEnvironment('API_BASE_URL');
    if (envBase.isNotEmpty) return envBase;
    if (kIsWeb) return 'http://127.0.0.1:300/api';
    try {
      if (Platform.isAndroid) return 'http://127.0.0.1:300/api';
    } catch (_) {
      // Platform may not be available in some environments
    }
    return 'http://127.0.0.1:300/api';
  }

  final String baseUrl = _resolveBaseUrl();

  var userList = <User>[].obs;
  var currentUser = Rxn<User>();
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Fetch all users
  Future<void> getAllUsers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final resp = await ApiService.instance.get('/utilisateurs');
      if (resp.statusCode == 200) {
        final data = resp.data;
        final List<dynamic> list =
            data is List
                ? data
                : (data is String
                    ? json.decode(data) as List<dynamic>
                    : <dynamic>[]);
        userList.value =
            list
                .map((e) => User.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
      } else {
        errorMessage.value = 'Failed to load users: ${resp.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load users: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Get single user by id
  Future<User?> getUserById(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final resp = await ApiService.instance.get('/utilisateurs/$id');
      if (resp.statusCode == 200) {
        final data = resp.data;
        final map =
            data is Map<String, dynamic>
                ? data
                : Map<String, dynamic>.from(
                  data is String ? json.decode(data) : (data as Map),
                );
        currentUser.value = User.fromJson(map);
        return currentUser.value;
      } else {
        errorMessage.value = 'Failed to get user: ${resp.statusCode}';
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Failed to get user: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Map backend errors to user-friendly French messages
  String _getUserFriendlyErrorMessage(int statusCode, String responseBody) {
    try {
      final responseData = json.decode(responseBody);

      // Handle specific status codes
      switch (statusCode) {
        case 409: // Conflict - resource already exists
          if (responseData['field'] == 'email') {
            return 'Cet email est déjà utilisé. Veuillez utiliser un autre email.';
          } else if (responseData['field'] == 'numero_telephone') {
            return 'Ce numéro de téléphone est déjà utilisé.';
          }
          return 'Cette ressource existe déjà. Veuillez vérifier vos informations.';

        case 400: // Bad Request
          if (responseData['message'] != null) {
            final message = responseData['message'].toString().toLowerCase();
            if (message.contains('email')) {
              return 'Format d\'email invalide. Veuillez vérifier votre email.';
            } else if (message.contains('téléphone') ||
                message.contains('telephone')) {
              return 'Format de numéro de téléphone invalide.';
            } else if (message.contains('mot de passe') ||
                message.contains('password')) {
              return 'Le mot de passe ne répond pas aux critères de sécurité.';
            }
          }
          return 'Données invalides. Veuillez vérifier vos informations.';

        case 422: // Unprocessable Entity
          return 'Données invalides. Veuillez vérifier tous les champs.';

        case 500: // Internal Server Error
          return 'Erreur serveur. Veuillez réessayer plus tard.';

        case 503: // Service Unavailable
          return 'Service temporairement indisponible. Veuillez réessayer plus tard.';

        default:
          // Generic fallback for other status codes
          if (statusCode >= 400 && statusCode < 500) {
            return 'Données invalides. Veuillez vérifier vos informations.';
          } else if (statusCode >= 500) {
            return 'Erreur serveur. Veuillez réessayer plus tard.';
          }
          return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
      }
    } catch (e) {
      // If JSON parsing fails, return generic message based on status code
      if (statusCode == 409) {
        return 'Cette ressource existe déjà. Veuillez vérifier vos informations.';
      } else if (statusCode >= 400 && statusCode < 500) {
        return 'Données invalides. Veuillez vérifier vos informations.';
      } else if (statusCode >= 500) {
        return 'Erreur serveur. Veuillez réessayer plus tard.';
      }
      return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
    }
  }

  // Create new user (signup)
  Future<User?> createUser(Map<String, dynamic> userData) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // ✅ Convert phone number to string if it's a number
      if (userData['numero_telephone'] != null) {
        userData['numero_telephone'] = userData['numero_telephone'].toString();
      }

      final resp = await ApiService.instance.post(
        '/utilisateurs/register',
        data: userData,
      );

      print('Sent data: ${json.encode(userData)}');
      print('Response status: ${resp.statusCode}');
      print('Response body: ${resp.data}');

      // Handle success (201 Created or 200 OK)
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        print('✅ User successfully created!');
        final data =
            resp.data is Map<String, dynamic>
                ? resp.data
                : Map<String, dynamic>.from(
                  resp.data is String
                      ? json.decode(resp.data)
                      : (resp.data as Map),
                );
        final newUser = User.fromJson(data);
        userList.add(newUser);
        return newUser;
      } else {
        // Use user-friendly error message
        final bodyStr =
            resp.data is String ? resp.data : json.encode(resp.data);
        errorMessage.value = _getUserFriendlyErrorMessage(
          resp.statusCode ?? 0,
          bodyStr,
        );
        return null;
      }
    } catch (e) {
      print('❌ Exception during signup: $e');
      print('❌ Exception type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');

      // Handle network/connection errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('TimeoutException')) {
        errorMessage.value =
            'Connexion impossible. Vérifiez votre connexion internet.';
      } else {
        errorMessage.value =
            'Une erreur inattendue s\'est produite. Veuillez réessayer.';
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Update existing user
  Future<User?> updateUser(int id, Map<String, dynamic> updateData) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final resp = await ApiService.instance.put(
        '/utilisateurs/$id',
        data: updateData,
      );

      if (resp.statusCode == 200) {
        final data =
            resp.data is Map<String, dynamic>
                ? resp.data
                : Map<String, dynamic>.from(
                  resp.data is String
                      ? json.decode(resp.data)
                      : (resp.data as Map),
                );
        final updatedUser = User.fromJson(data);
        // Update user in userList if present
        final index = userList.indexWhere((u) => u.id == id);
        if (index != -1) {
          userList[index] = updatedUser;
          userList.refresh();
        }
        currentUser.value = updatedUser;
        return updatedUser;
      } else {
        errorMessage.value = 'Failed to update user: ${resp.statusCode}';
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Failed to update user: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete a user by id
  Future<bool> deleteUser(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final resp = await ApiService.instance.delete('/utilisateurs/$id');
      if (resp.statusCode == 204) {
        userList.removeWhere((u) => u.id == id);
        if (currentUser.value?.id == id) currentUser.value = null;
        return true;
      } else {
        errorMessage.value = 'Failed to delete user: ${resp.statusCode}';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to delete user: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
