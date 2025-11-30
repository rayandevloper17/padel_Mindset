import 'package:dio/dio.dart' as dio;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'dart:developer' as developer;

class ApiService extends GetxService {
  late dio.Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // Resolve base URL depending on platform/environment
  final String baseUrl =
      (() {
        const String envBase = String.fromEnvironment('API_BASE_URL');
        if (envBase.isNotEmpty) return envBase;
        if (kIsWeb) return 'http://localhost:300/api';
        try {
          if (Platform.isAndroid) return 'http://127.0.0.1:300/api';
        } catch (_) {
          // Platform may not be available in some environments
        }
        return 'http://localhost:300/api';
      })();

  static ApiService get instance => Get.find<ApiService>();

  @override
  void onInit() {
    super.onInit();
    _initializeDio();
  }

  void _initializeDio() {
    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
        // Don't make Dio throw for 4xx responses so interceptors can handle 401
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to all requests except login and refresh
          if (!options.path.contains('/login') &&
              !options.path.contains('/refresh-token')) {
            final token = await _getValidToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          // Intercept 401 responses and attempt a token refresh+retry
          final status = response.statusCode ?? 0;
          final reqOptions = response.requestOptions;

          if (status == 401 &&
              !reqOptions.path.contains('/login') &&
              !reqOptions.path.contains('/refresh-token')) {
            // Check if this is a token expiration that needs refresh
            final needsRefresh = response.data?['needsRefresh'] == true;
            final isAccessTokenExpired =
                response.data?['code'] == 'ACCESS_TOKEN_EXPIRED';

            // Only attempt refresh if it's a token expiration issue
            if (needsRefresh || isAccessTokenExpired) {
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Retry the original request with new token
                final token = await _storage.read(key: 'token');
                try {
                  final opts = dio.Options(
                    method: reqOptions.method,
                    headers: {
                      ...reqOptions.headers,
                      'Authorization': 'Bearer $token',
                    },
                    responseType: reqOptions.responseType,
                    contentType: reqOptions.contentType,
                    followRedirects: reqOptions.followRedirects,
                    validateStatus: (s) => s != null && s < 500,
                  );

                  final retryResponse = await _dio.request(
                    reqOptions.path,
                    data: reqOptions.data,
                    queryParameters: reqOptions.queryParameters,
                    options: opts,
                  );

                  handler.resolve(retryResponse);
                  return;
                } catch (e) {
                  developer.log(
                    'Retry after refresh failed: $e',
                    name: 'ApiService',
                  );
                  // fall through to clear tokens and redirect
                }
              }
            }

            // If refresh failed or it's not a token expiration issue, clear tokens and go to login
            await _clearTokens();
            try {
              Get.offAllNamed('/login');
            } catch (_) {}
            handler.next(response);
            return;
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          // Forward other errors (network, 5xx, etc.)
          handler.next(error);
        },
      ),
    );
  }

  /// Public: Get a valid access token, refreshing if expired.
  /// Returns null if refresh fails or no token is present.
  Future<String?> getValidAccessToken() async {
    return await _getValidToken();
  }

  /// Public: Build Authorization headers with a valid token.
  /// If token cannot be obtained, throws an exception for the caller to handle.
  Future<Map<String, String>> authHeaders({Map<String, String>? extra}) async {
    final token = await getValidAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authorization failed: no valid token');
    }
    return {'Authorization': 'Bearer $token', if (extra != null) ...extra};
  }

  /// Gets a valid token, refreshing it if necessary.
  Future<String?> _getValidToken() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return null;

    if (JwtDecoder.isExpired(token)) {
      developer.log('Token is expired, attempting refresh', name: 'ApiService');
      final refreshed = await _refreshToken();
      if (refreshed) {
        return await _storage.read(key: 'token');
      }
      return null;
    }

    // Check if token will expire soon (within 5 minutes) and refresh proactively
    try {
      final remainingTime = JwtDecoder.getRemainingTime(token);
      if (remainingTime.inMinutes <= 5) {
        developer.log(
          'Token will expire soon (${remainingTime.inMinutes} minutes), refreshing proactively',
          name: 'ApiService',
        );
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await _storage.read(key: 'token');
        }
      }
    } catch (e) {
      developer.log('Error checking token expiry time: $e', name: 'ApiService');
    }

    // Ensure stored userId is populated: some tokens may not include `id` claim
    try {
      final decoded = JwtDecoder.decode(token);
      if (!decoded.containsKey('id')) {
        // Try to fetch current user profile using the token and store the id
        try {
          final resp = await _dio.get(
            '/utilisateurs/profile/me',
            options: dio.Options(headers: {'Authorization': 'Bearer $token'}),
          );
          if (resp.statusCode == 200) {
            final user = resp.data;
            if (user != null && user['id'] != null) {
              await _storage.write(key: 'userId', value: user['id'].toString());
              await _storage.write(
                key: 'userEmail',
                value: user['email']?.toString() ?? '',
              );
              await _storage.write(
                key: 'userName',
                value: user['nom']?.toString() ?? '',
              );
              await _storage.write(
                key: 'userFirstName',
                value: user['prenom']?.toString() ?? '',
              );
            }
          }
        } catch (e) {
          // If profile call fails, don't treat it as fatal here — caller will handle missing userId
          developer.log(
            'Failed to populate userId from token: $e',
            name: 'ApiService',
          );
        }
      }
    } catch (e) {
      // If decoding fails, log and proceed — token may still be valid
      developer.log('Failed to decode token payload: $e', name: 'ApiService');
    }

    return token;
  }

  /// Refreshes the access token using the stored refresh token.
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        developer.log('No refresh token available', name: 'ApiService');
        return false;
      }

      developer.log('Attempting to refresh token', name: 'ApiService');

      final response = await _dio.post(
        '/utilisateurs/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newToken != null && newToken.isNotEmpty) {
          await _storage.write(key: 'token', value: newToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await _storage.write(key: 'refresh_token', value: newRefreshToken);
          }

          developer.log('Token refreshed successfully', name: 'ApiService');

          // Update user info if available in response
          if (data['user'] != null) {
            final user = data['user'] as Map<String, dynamic>;
            await _storage.write(
              key: 'userId',
              value: user['id']?.toString() ?? '',
            );
            await _storage.write(key: 'userEmail', value: user['email'] ?? '');
            await _storage.write(key: 'userName', value: user['nom'] ?? '');
            await _storage.write(
              key: 'userFirstName',
              value: user['prenom'] ?? '',
            );
          }

          return true;
        }
      }

      developer.log(
        'Token refresh failed: ${response.statusCode}',
        name: 'ApiService',
      );
      return false;
    } catch (e) {
      developer.log('Token refresh error: $e', name: 'ApiService');
      return false;
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'userEmail');
    await _storage.delete(key: 'userName');
    await _storage.delete(key: 'userFirstName');
  }

  // Public methods for making API calls
  Future<dio.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<dio.Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<dio.Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<dio.Response> delete(String path) {
    return _dio.delete(path);
  }

  // Multipart upload helpers for profile picture
  Future<dio.Response> uploadProfilePictureFile(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = dio.FormData.fromMap({
      'image': await dio.MultipartFile.fromFile(filePath, filename: fileName),
    });
    return _dio.post(
      '/utilisateurs/profile/me/profile-picture',
      data: formData,
      options: dio.Options(contentType: 'multipart/form-data'),
    );
  }

  Future<dio.Response> uploadProfilePictureBytes(
    List<int> bytes,
    String fileName,
  ) async {
    final formData = dio.FormData.fromMap({
      'image': dio.MultipartFile.fromBytes(bytes, filename: fileName),
    });
    return _dio.post(
      '/utilisateurs/profile/me/profile-picture',
      data: formData,
      options: dio.Options(contentType: 'multipart/form-data'),
    );
  }

  // Authentication methods
  Future<bool> login(String email, String password) async {
    try {
      developer.log('Attempting login for: $email', name: 'ApiService');
      developer.log('Using base URL: $baseUrl', name: 'ApiService');

      final response = await post(
        '/utilisateurs/login',
        data: {'email': email, 'mot_de_passe': password},
      );

      developer.log(
        'Login response status: ${response.statusCode}',
        name: 'ApiService',
      );
      if (response.statusCode != 200) {
        try {
          developer.log(
            'Login response body: ${response.data}',
            name: 'ApiService',
          );
        } catch (_) {
          // Response might not be JSON
        }
      }

      if (response.statusCode == 200) {
        final data = response.data;
        developer.log('Login successful, storing tokens', name: 'ApiService');

        // Store tokens and user data
        await _storage.write(key: 'token', value: data['accessToken']);
        // Backwards compatibility: keep legacy 'token' key in sync
        await _storage.write(key: 'token', value: data['accessToken']);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);

        final userData = data['user'];
        await _storage.write(
          key: 'userId',
          value: userData['id']?.toString() ?? '0',
        );
        await _storage.write(
          key: 'userEmail',
          value: userData['email']?.toString() ?? '',
        );
        await _storage.write(
          key: 'userName',
          value: userData['nom']?.toString() ?? '',
        );
        await _storage.write(
          key: 'userFirstName',
          value: userData['prenom']?.toString() ?? '',
        );
        await _storage.write(
          key: 'note',
          value: userData['note']?.toString() ?? '0',
        );

        return true;
      } else {
        developer.log(
          'Login failed with status: ${response.statusCode}',
          name: 'ApiService',
        );
      }
    } catch (e) {
      developer.log('Login failed: $e', name: 'ApiService', error: e);
      // Check if it's a connection error
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        developer.log(
          'Server appears to be down. Please start the backend server.',
          name: 'ApiService',
        );
      }
    }

    return false;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        await post(
          '/utilisateurs/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (e) {
      developer.log('Logout API call failed: $e', name: 'ApiService', error: e);
    } finally {
      await _clearTokens();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return false;

    // If token is expired, try to refresh
    if (JwtDecoder.isExpired(token)) {
      return await _refreshToken();
    }

    return true;
  }

  Future<Map<String, String>?> getCurrentUser() async {
    final userId = await _storage.read(key: 'userId');
    if (userId == null) return null;

    return {
      'id': userId,
      'email': await _storage.read(key: 'userEmail') ?? '',
      'nom': await _storage.read(key: 'userName') ?? '',
      'prenom': await _storage.read(key: 'userFirstName') ?? '',
    };
  }

  // Test server connection
  Future<bool> testConnection() async {
    try {
      developer.log('Testing connection to: $baseUrl', name: 'ApiService');
      final response = await _dio.get(
        '/test',
        options: dio.Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      developer.log(
        'Connection test successful: ${response.statusCode}',
        name: 'ApiService',
      );
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Connection test failed: $e', name: 'ApiService', error: e);
      return false;
    }
  }
}
