import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;
import '../modules/rating_popup.dart';
import '../modules/rating_controller.dart';
import 'dart:async';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final isLoggedIn = false.obs;
  final isLoading = false.obs;
  final currentUser = Rxn<Map<String, dynamic>>();
  var isRatingPopupDisplayed = false;

  late final RatingController ratingController;

  @override
  void onInit() {
    super.onInit();
    // Perform login status check immediately
    checkLoginStatus();

    // Resolve RatingController after DI completes, then attach listeners
    Future.microtask(() {
      ratingController = Get.find<RatingController>();

      // React when rating status loads
      ever<bool>(ratingController.statusLoaded, (loaded) {
        if (loaded && isLoggedIn.value && ratingController.displayQ.value == 0 && !isRatingPopupDisplayed) {
          isRatingPopupDisplayed = true;
          Get.dialog(RatingPopup()).then((_) => isRatingPopupDisplayed = false);
        }
      });

      // Periodically check displayQ to decide whether to show the rating popup
      Timer.periodic(const Duration(seconds: 3), (timer) {
        final shouldPrompt = isLoggedIn.value &&
            ratingController.statusLoaded.value &&
            ratingController.displayQ.value == 0 &&
            !isRatingPopupDisplayed;
        if (shouldPrompt) {
          isRatingPopupDisplayed = true;
          Get.dialog(RatingPopup()).then((result) {
            isRatingPopupDisplayed = false;
            if (result == 'later') {
              Future.delayed(const Duration(seconds: 4), () {
                final shouldRePrompt = isLoggedIn.value &&
                    ratingController.statusLoaded.value &&
                    ratingController.displayQ.value == 0;
                if (shouldRePrompt) {
                  isRatingPopupDisplayed = true;
                  Get.dialog(RatingPopup()).then((_) => isRatingPopupDisplayed = false);
                }
              });
            }
          });
        }
      });
    });
  }

  Future<void> checkLoginStatus() async {
    isLoading.value = true;
    try {
      final token = await _apiService.getValidAccessToken();
      if (token != null && token.isNotEmpty) {
        final userData = await _fetchUserData();
        if (userData != null) {
          currentUser.value = userData;
          isLoggedIn.value = true;
        } else {
          await logout();
        }
      } else {
        isLoggedIn.value = false;
        currentUser.value = null;
      }
    } catch (e) {
      developer.log('Error checking login status: $e', name: 'AuthController');
      isLoggedIn.value = false;
      currentUser.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final id = await _storage.read(key: 'userId');
    final email = await _storage.read(key: 'userEmail');
    final nom = await _storage.read(key: 'userName');
    final prenom = await _storage.read(key: 'userFirstName');
    final note = await _storage.read(key: 'note');

    if (id != null && email != null) {
      return {
        'id': int.tryParse(id) ?? 0,
        'email': email,
        'nom': nom ?? '',
        'prenom': prenom ?? '',
        'note': int.tryParse(note ?? '0') ?? 0,
      };
    }
    return null;
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    try {
      final success = await _apiService.login(email, password);
      if (success) {
        await checkLoginStatus();
        if (isLoggedIn.value && currentUser.value?['note'] == 0 && !isRatingPopupDisplayed) {
          isRatingPopupDisplayed = true;
          Get.dialog(RatingPopup()).then((result) {
            isRatingPopupDisplayed = false;
            if (result == 'later') {
              Future.delayed(const Duration(seconds: 4), () {
                if (isLoggedIn.value && currentUser.value?['note'] == 0) {
                  isRatingPopupDisplayed = true;
                  Get.dialog(RatingPopup()).then((_) => isRatingPopupDisplayed = false);
                }
              });
            }
          });
        }
        return true;
      } else {
        isLoggedIn.value = false;
        currentUser.value = null;
        return false;
      }
    } catch (e) {
      developer.log('Login failed: $e', name: 'AuthController');
      isLoggedIn.value = false;
      currentUser.value = null;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _apiService.logout();
      isLoggedIn.value = false;
      currentUser.value = null;
    } catch (e) {
      developer.log('Logout error: $e', name: 'AuthController');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refreshes the token if needed.
  Future<void> refreshTokenIfNeeded() async {
    final isLoggedIn = await _apiService.isLoggedIn();
    if (isLoggedIn) {
      developer.log('Token refreshed successfully', name: 'AuthController');
    } else {
      developer.log('Token refresh failed or user not logged in', name: 'AuthController');
      // If refresh failed, we should redirect to login
      Get.offAllNamed('/login');
    }
  }

  /// Checks if token needs refresh and refreshes it proactively
  Future<bool> ensureValidToken() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return false;

      // Check if token is expired or will expire soon
      if (JwtDecoder.isExpired(token)) {
        developer.log('Token is expired, refreshing...', name: 'AuthController');
        return await _apiService.isLoggedIn();
      }

      // Check if token will expire within 5 minutes
      try {
        final remainingTime = JwtDecoder.getRemainingTime(token);
        if (remainingTime.inMinutes <= 5) {
          developer.log('Token will expire soon (${remainingTime.inMinutes} minutes), refreshing proactively...', name: 'AuthController');
          return await _apiService.isLoggedIn();
        }
      } catch (e) {
        developer.log('Error checking token expiry time: $e', name: 'AuthController');
      }

      return true;
    } catch (e) {
      developer.log('Error ensuring valid token: $e', name: 'AuthController');
      return false;
    }
  }
}
