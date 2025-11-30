import 'package:app/modules/ProfileView/controller_profile_page.dart';
import 'package:get/get.dart';
import 'package:app/services/api_service.dart';

class UserPadelController {
  final String _baseUrl = 'http://127.0.0.1:300/api/utilisateurs';
  final String _ratingBaseUrl = 'http://127.0.0.1:300/api/rating';
  // final ProfileController profileController = Get.put(ProfileController());

  Future<Map<String, dynamic>> deductCredit({
    required String userId,
    String? creditAmount, // Single credit amount instead of gold/silver
  }) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      final token = await ApiService.instance.getValidAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final resp = await ApiService.instance.put(
        '/utilisateurs/$userId',
        data: {
          'creditOperation': 'deduct',
          'creditAmount': double.tryParse(creditAmount ?? '0') ?? 0,
          'creditType': 'single',
          'sport': 'padel',
        },
      );

      final Map<String, dynamic> responseData =
          (resp.data is Map<String, dynamic>)
              ? resp.data
              : (resp.data != null
                  ? Map<String, dynamic>.from(resp.data as Map)
                  : <String, dynamic>{});

      switch (resp.statusCode) {
        case 200:
          final user = responseData['user'];

          // ✅ refresh profile values in the SAME controller
          final profileController = Get.find<ProfileController>();
          await profileController.loadUserProfile();

          return {
            'success': true,
            'message': 'Credit deducted successfully',
            'user': user,
            'currentBalance': profileController.creditBalance.value,
          };

        case 400:
          final message = responseData['message'] ?? 'Invalid request';
          if (message.contains('insuffisant') ||
              message.contains('Insufficient')) {
            throw Exception(
              'Insufficient credit balance. Current balance: ${responseData['currentBalance'] ?? 'unknown'}',
            );
          }
          throw Exception(message);

        case 401:
          throw Exception('Unauthorized access. Please login again.');

        case 403:
          throw Exception(
            'Access denied. You can only modify your own account.',
          );

        case 404:
          throw Exception('User with ID $userId not found in the system');

        default:
          throw Exception(
            'Failed to deduct credit. Status: ${resp.statusCode}. '
            'Message: ${responseData['message'] ?? 'Unknown error'}',
          );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error deducting credit for user $userId: $e');
    }
  }

  // Helper method to get current credit balance
  Future<double> getCreditBalance({required String userId}) async {
    try {
      final token = await ApiService.instance.getValidAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final resp = await ApiService.instance.get('/utilisateurs/$userId');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> user =
            (resp.data is Map<String, dynamic>)
                ? resp.data
                : Map<String, dynamic>.from(resp.data as Map);
        return (user['credit_balance'] ?? user['credit_gold_padel'] ?? 0)
            .toDouble();
      } else {
        throw Exception('Failed to fetch credit balance');
      }
    } catch (e) {
      throw Exception('Error fetching credit balance: ${e.toString()}');
    }
  }

  // Method to add credits
  Future<Map<String, dynamic>> addCredit({
    required String userId,
    required double creditAmount,
    required String creditType,
    required String sport,
  }) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      if (creditAmount <= 0) {
        throw Exception('Credit amount must be greater than 0');
      }

      final token = await ApiService.instance.getValidAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final resp = await ApiService.instance.put(
        '/utilisateurs/$userId',
        data: {
          'creditOperation': 'add',
          'creditAmount': creditAmount,
          'creditType': creditType,
          'sport': sport,
        },
      );

      final Map<String, dynamic> responseData =
          (resp.data is Map<String, dynamic>)
              ? resp.data
              : (resp.data != null
                  ? Map<String, dynamic>.from(resp.data as Map)
                  : <String, dynamic>{});

      if (resp.statusCode == 200) {
        return {
          'success': true,
          'message': 'Credit added successfully',
          'user': responseData['user'],
        };
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add credit');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error adding credit: ${e.toString()}');
    }
  }

  // Method to update user information
  Future<Map<String, dynamic>> updateUserInfo({
    required String userId,
    Map<String, dynamic>? userUpdates,
  }) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      final token = await ApiService.instance.getValidAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final resp = await ApiService.instance.put(
        '/utilisateurs/$userId',
        data: userUpdates ?? {},
      );

      final Map<String, dynamic> responseData =
          (resp.data is Map<String, dynamic>)
              ? resp.data
              : (resp.data != null
                  ? Map<String, dynamic>.from(resp.data as Map)
                  : <String, dynamic>{});

      if (resp.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error updating user: ${e.toString()}');
    }
  }

  // Get user information
  Future<Map<String, dynamic>> getUserInfo({required String userId}) async {
    try {
      final token = await ApiService.instance.getValidAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final resp = await ApiService.instance.get('/utilisateurs/$userId');

      final Map<String, dynamic> responseData =
          (resp.data is Map<String, dynamic>)
              ? resp.data
              : (resp.data != null
                  ? Map<String, dynamic>.from(resp.data as Map)
                  : <String, dynamic>{});

      if (resp.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch user info');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error fetching user info: ${e.toString()}');
    }
  }

  // Combined method for complex operations
  Future<Map<String, dynamic>> updateUserAndCredit({
    required String userId,
    Map<String, dynamic>? userUpdates,
    String? creditOperation, // 'add' or 'deduct'
    double? creditAmount,
    String? creditType,
    String? sport,
  }) async {
    try {
      final token = await ApiService.instance.getValidAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      Map<String, dynamic> requestBody = userUpdates ?? {};

      // Add credit operation if specified
      if (creditOperation != null &&
          creditAmount != null &&
          creditType != null &&
          sport != null) {
        requestBody.addAll({
          'creditOperation': creditOperation,
          'creditAmount': creditAmount,
          'creditType': creditType,
          'sport': sport,
        });
      }

      final resp = await ApiService.instance.put(
        '/utilisateurs/$userId',
        data: requestBody,
      );

      final Map<String, dynamic> responseData =
          (resp.data is Map<String, dynamic>)
              ? resp.data
              : (resp.data != null
                  ? Map<String, dynamic>.from(resp.data as Map)
                  : <String, dynamic>{});

      if (resp.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Operation failed');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error in combined operation: ${e.toString()}');
    }
  }

  // Public rating endpoint: fetch rating for any user by ID
  Future<double> getRating({required String userId}) async {
    try {
      final resp = await ApiService.instance.get('/rating/$userId');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data =
            (resp.data is Map<String, dynamic>)
                ? resp.data
                : Map<String, dynamic>.from(resp.data as Map);
        final noteVal = double.tryParse(data['note']?.toString() ?? '');
        return noteVal ?? 0.0;
      } else {
        throw Exception('Failed to fetch rating: ${resp.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching rating for user $userId: $e');
    }
  }
}
