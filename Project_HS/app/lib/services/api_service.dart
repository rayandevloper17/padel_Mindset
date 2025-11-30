import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;
  ApiResponse({required this.statusCode, required this.data});
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // Adjust if your backend base changes; include '/api' if needed.
  final String baseUrl = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://0.0.0.0:300/api',
  );

  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getValidAccessToken() async {
    // Try common keys; customize if your app uses different storage keys.
    final token = await _storage.read(key: 'access_token') ??
        await _storage.read(key: 'token');
    return token;
  }

  Future<Map<String, String>> authHeaders({Map<String, String>? extra}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = await getValidAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Uri _buildUri(String path, {Map<String, dynamic>? queryParameters}) {
    final origin = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$origin$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }

  Future<ApiResponse> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final headers = await authHeaders();
    final uri = _buildUri(path, queryParameters: queryParameters);
    final resp = await _client.get(uri, headers: headers);
    dynamic data;
    try {
      data = json.decode(resp.body);
    } catch (_) {
      data = resp.body;
    }
    return ApiResponse(statusCode: resp.statusCode, data: data);
  }

  Future<ApiResponse> post(String path, {Object? data, Map<String, dynamic>? queryParameters}) async {
    final headers = await authHeaders();
    final uri = _buildUri(path, queryParameters: queryParameters);
    final body = data == null ? null : json.encode(data);
    final resp = await _client.post(uri, headers: headers, body: body);
    dynamic decoded;
    try {
      decoded = json.decode(resp.body);
    } catch (_) {
      decoded = resp.body;
    }
    return ApiResponse(statusCode: resp.statusCode, data: decoded);
  }

  Future<ApiResponse> put(String path, {Object? data, Map<String, dynamic>? queryParameters}) async {
    final headers = await authHeaders();
    final uri = _buildUri(path, queryParameters: queryParameters);
    final body = data == null ? null : json.encode(data);
    final resp = await _client.put(uri, headers: headers, body: body);
    dynamic decoded;
    try {
      decoded = json.decode(resp.body);
    } catch (_) {
      decoded = resp.body;
    }
    return ApiResponse(statusCode: resp.statusCode, data: decoded);
  }
}