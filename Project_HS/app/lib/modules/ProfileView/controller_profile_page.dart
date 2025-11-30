import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:app/utils/sse_event_source_stub.dart'
    if (dart.library.html) 'package:app/utils/sse_event_source_web.dart';

class ProfileController extends GetxController {
  final _storage = const FlutterSecureStorage();
  final _apiService = Get.find<ApiService>();

  // SSE live credit updates (web only)
  SseEventSource? _creditSse;
  bool _sseConnected = false;

  var userId = ''.obs;
  var isLoading = false.obs;
  var userProfile = {}.obs;
  var imageUrl = ''.obs;

  // User data observables
  var nom = ''.obs;
  var prenom = ''.obs;
  var email = ''.obs;
  var creditBalance = '0'.obs; // Single credit balance instead of gold/silver
  var note = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Defer heavy state changes to after the first frame to avoid
    // 'setState during build' errors in Obx widgets.
  }

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadUserProfile();
      _startCreditSse();
    });
  }

  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;

      // Get user info from storage first
      final storedUserId = await _storage.read(key: 'userId');
      final storedEmail = await _storage.read(key: 'userEmail');
      final storedNom = await _storage.read(key: 'userName');
      final storedPrenom = await _storage.read(key: 'userFirstName');

      developer.log(
        'Stored user data: ID=$storedUserId, Email=$storedEmail',
        name: 'ProfileController',
      );

      if (storedUserId == null || storedUserId.isEmpty || storedUserId == '0') {
        developer.log(
          '⚠️ No valid user ID found in storage. Redirecting to login.',
          name: 'ProfileController',
        );
        // Schedule navigation after the current frame to avoid build-time tree issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute != '/login') {
            Get.offAllNamed('/login');
          }
        });
        return;
      }

      // Update observables with stored data first
      userId.value = storedUserId;
      email.value = storedEmail ?? '';
      nom.value = storedNom ?? '';
      prenom.value = storedPrenom ?? '';

      // Fetch fresh data from API
      try {
        final response = await _apiService.get('/utilisateurs/profile/me');

        if (response.statusCode == 200) {
          final data = response.data;
          userProfile.value = data;

          // Update user info
          nom.value = data['nom']?.toString() ?? '';
          prenom.value = data['prenom']?.toString() ?? '';
          email.value = data['email']?.toString() ?? '';
          imageUrl.value = data['image_url']?.toString() ?? '';

          // Handle credits safely - use single credit balance
          _updateCreditValue(
            'credit_balance',
            data['credit_balance'] ?? data['credit_gold_padel'] ?? 0,
          );

          // Fetch rating status
          await getRatingStatus();

          developer.log(
            '✅ Profile loaded successfully',
            name: 'ProfileController',
          );
          // Ensure SSE is connected after successful profile load
          _startCreditSse();
        }
      } catch (apiError) {
        developer.log(
          '⚠️ API call failed, using stored data: $apiError',
          name: 'ProfileController',
        );
        // Continue with stored data if API fails
      }
    } catch (e) {
      developer.log(
        '💥 Error loading profile: $e',
        name: 'ProfileController',
        error: e,
      );
      _resetToDefaults();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getRatingStatus() async {
    final storedUserId = await _storage.read(key: 'userId');
    if (storedUserId == null || storedUserId.isEmpty) return;

    try {
      final response = await _apiService.get('/rating/$storedUserId');
      if (response.statusCode == 200) {
        final data = response.data;
        note.value = (data['note'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (e) {
      developer.log(
        'Error fetching rating status: $e',
        name: 'ProfileController',
      );
    }
  }

  void _updateCreditValue(String creditType, dynamic value) {
    try {
      String creditString = '0';
      if (value != null && value.toString().trim().isNotEmpty) {
        int creditValue = int.parse(value.toString());
        creditString = creditValue.toString();
      }

      if (creditType == 'credit_balance') {
        creditBalance.value = creditString;
      }
    } catch (e) {
      developer.log('Error parsing $creditType: $e', name: 'ProfileController');
      if (creditType == 'credit_balance') {
        creditBalance.value = '0';
      }
    }
  }

  void _resetToDefaults() {
    nom.value = '';
    prenom.value = '';
    email.value = '';
    creditBalance.value = '0';
    userId.value = '';
    userProfile.value = {};
  }

  Future<void> refreshProfile() async {
    await loadUserProfile();
    _startCreditSse();
  }

  // Full URL for profile image based on backend base URL
  String get profileImageUrl {
    final url = imageUrl.value;
    if (url.isEmpty) return '';
    final base = _apiService.baseUrl;
    final host =
        base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
    return '$host$url';
  }

  // Pick and upload a new profile picture
  Future<void> editProfilePicture() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      isLoading.value = true;
      var response = await _apiService.uploadProfilePictureFile(picked.path);

      // Handle web separately if path is not usable
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        response = await _apiService.uploadProfilePictureBytes(
          bytes,
          picked.name,
        );
      }

      if (response.statusCode == 200) {
        final newUrl = response.data['image_url']?.toString() ?? '';
        imageUrl.value = newUrl;
        await refreshProfile();
        Get.snackbar(
          'Succès',
          'Photo de profil mise à jour',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.2),
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Échec du téléchargement (${response.statusCode})',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.2),
        );
      }
    } catch (e) {
      developer.log(
        'Error updating profile image: $e',
        name: 'ProfileController',
      );
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Initialize SSE subscription to live credit balance (web only)
  Future<void> _startCreditSse() async {
    if (!kIsWeb) return;
    if (_sseConnected) return;
    try {
      // Make sure we have a valid access token
      await _apiService.isLoggedIn();
      final token = await _apiService.getValidAccessToken();
      if (token == null || token.isEmpty) return;

      final base = _apiService.baseUrl;
      final host = base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
      final url = '$host/api/credits/stream?token=$token';

      _creditSse ??= SseEventSource();
      _creditSse!.connect(
        url,
        onMessage: (data) {
          try {
            final payload = jsonDecode(data);
            final dynamic balanceVal = payload['balance'];
            _updateCreditValue('credit_balance', balanceVal);
          } catch (e) {
            developer.log('SSE parse error: $e', name: 'ProfileController');
          }
        },
        onError: () {
          developer.log('SSE error encountered, will allow reconnect later', name: 'ProfileController');
          _sseConnected = false;
        },
      );
      _sseConnected = true;
      developer.log('📡 Connected to credit SSE', name: 'ProfileController');
    } catch (e) {
      developer.log('SSE setup failed: $e', name: 'ProfileController');
      _sseConnected = false;
    }
  }

  @override
  void onClose() {
    try {
      _creditSse?.close();
      _creditSse = null;
      _sseConnected = false;
    } catch (_) {}
    super.onClose();
  }
}
