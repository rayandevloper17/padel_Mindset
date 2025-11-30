import 'dart:async';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/services/api_service.dart';

// Model class for PlageHoraire
class PlageHoraire {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final double price;
  late final int terrainId;
  final bool? disponible;

  PlageHoraire(
    this.disponible, {
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.terrainId,
  });

  factory PlageHoraire.fromJson(Map<String, dynamic> json) {
    return PlageHoraire(
      json['disponible'] as bool?,
      id: int.parse(json['id'].toString()),
      terrainId: int.parse(json['terrain_id'].toString()),
      // Convert to local time for accurate day comparisons
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: DateTime.parse(json['end_time']).toLocal(),
      price: double.parse(json['price'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'price': price,
    };
  }
}

// GetX Controller with extensive debugging
class PlageHoraireController extends GetxController {
  static const String baseUrl = 'http://127.0.0.1:300/api';
  final storage = const FlutterSecureStorage();

  var plageHoraires = <PlageHoraire>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var selectedPlageHoraireId = 0.obs;

  // Get auth token from secure storage
  Future<String?> _getAuthToken() async {
    return await ApiService.instance.getValidAccessToken();
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    // Use centralized ApiService to ensure token is valid/refreshed
    return await ApiService.instance.authHeaders(
      extra: {'Content-Type': 'application/json'},
    );
  }

  @override
  void onInit() {
    super.onInit();
    print('🔥 PlageHoraireController onInit() called');

    final args = Get.arguments;

    if (args != null && args['terrainId'] != null) {
      getAllPlageHoraires(terrainId: args['terrainId']);
    } else {
      print('❗ No terrainId found in Get.arguments');
      errorMessage.value = 'No terrain selected';
    }
  }

  Future<void> getPlageHorairesForTerrain(
    int terrainId, {
    DateTime? selectedDate,
  }) async {
    print('🚀 Fetching plage horaires for terrain ID: $terrainId');
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Use selected date or default to today
      final date = selectedDate ?? DateTime.now();
      final formattedDate = date.toIso8601String().split('T')[0];

      final resp = await ApiService.instance.get(
        '/plage-horaire/terrain/$terrainId',
        queryParameters: {'date': formattedDate},
      );

      print('📡 Response Status: ${resp.statusCode}');
      print('📄 Body: ${resp.data}');
      print('📅 Filtering for date: $formattedDate');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> decoded =
            (resp.data is Map<String, dynamic>)
                ? resp.data
                : Map<String, dynamic>.from(resp.data as Map);
        final List<dynamic> data = decoded['data'];
        final total = (decoded['count'] ?? data.length);

        final mapped = data.map((item) => PlageHoraire.fromJson(item)).toList();

        // Filtrer les créneaux pour la date sélectionnée et la disponibilité
        final filtered =
            mapped.where((horaire) {
              final startLocal = DateTime(
                horaire.startTime.year,
                horaire.startTime.month,
                horaire.startTime.day,
              );
              final selectedLocal = DateTime(date.year, date.month, date.day);
              final isSameDate = startLocal.isAtSameMomentAs(selectedLocal);
              return (horaire.disponible ?? false) && isSameDate;
            }).toList();

        // Ne pas afficher de créneaux hors date sélectionnée
        plageHoraires.value = filtered;
        errorMessage.value =
            filtered.isEmpty ? 'Aucun créneau disponible pour cette date.' : '';

        print(
          '✅ Loaded ${plageHoraires.length} slots (filtered=${filtered.length}, total=${total}) for $formattedDate',
        );
      } else {
        errorMessage.value = 'Échec du chargement des créneaux';
      }
    } catch (e) {
      print('❌ Error loading plage horaires: $e');
      errorMessage.value = 'Exception : $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAllPlageHoraires({required int terrainId}) async {
    print('🚀 Starting getAllPlageHoraires() for terrainId = $terrainId');
    isLoading.value = true;
    errorMessage.value = '';

    try {
      print('📡 Sending GET request via ApiService');

      final resp = await ApiService.instance.get(
        '/plage-horaire',
        queryParameters: {'terrain_id': terrainId, 'disponible': true},
      );

      print('📡 Response received!');
      print('📊 Status Code: ${resp.statusCode}');
      print('📄 Raw Body: ${resp.data}');

      if (resp.statusCode == 200) {
        try {
          final Map<String, dynamic> decoded =
              (resp.data is Map<String, dynamic>)
                  ? resp.data
                  : Map<String, dynamic>.from(resp.data as Map);
          final List<dynamic> data = decoded['data'];

          plageHoraires.value =
              data.map((item) => PlageHoraire.fromJson(item)).toList();
          print('✅ Data loaded successfully. Total: ${plageHoraires.length}');
          if (plageHoraires.isNotEmpty) {
            print('🔍 First item: ${plageHoraires.first.toJson()}');
          }
        } catch (jsonError) {
          print('❌ JSON parsing error: $jsonError');
          errorMessage.value = 'Format de données invalide';
        }
      } else {
        print('❌ HTTP Error ${resp.statusCode}: ${resp.data}');
        errorMessage.value = 'Erreur ${resp.statusCode}';
      }
    } on TimeoutException catch (timeoutError) {
      print('⏰ Request timed out: $timeoutError');
      errorMessage.value = 'Délai d\'attente dépassé';
    } catch (e) {
      print('❌ Exception: $e');
      errorMessage.value = 'Une erreur s\'est produite : $e';
    } finally {
      isLoading.value = false;
      print('🏁 Finished getAllPlageHoraires()');
      print(
        '📊 Final State — Loading: ${isLoading.value}, Error: ${errorMessage.value}, Items: ${plageHoraires.length}',
      );
    }
  }

  Future<void> manualRefresh() async {
    final args = Get.arguments;

    if (args != null && args['terrainId'] != null) {
      await getAllPlageHoraires(terrainId: args['terrainId']);
    } else {
      print('❗ Cannot refresh, terrainId missing');
      errorMessage.value = 'Aucun terrain sélectionné';
    }
  }

  Future<void> testConnection() async {
    print('🧪 Testing connection to API...');
    try {
      final resp = await ApiService.instance.get('/plage-horaire');
      print('🧪 Connection test result: ${resp.statusCode}');
      print('🧪 Response: ${resp.data}');
    } catch (e) {
      print('🧪 Connection test failed: $e');
    }
  }

  Future<bool> createPlageHoraire({
    required DateTime startTime,
    required DateTime endTime,
    required double price,
  }) async {
    print('➕ Creating new PlageHoraire...');

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final Map<String, dynamic> requestBody = {
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'price': price,
      };

      print('📤 Request body: $requestBody');

      final resp = await ApiService.instance.post(
        '/plage-horaire',
        data: requestBody,
      );

      print('📤 Create response: ${resp.statusCode}');
      print('📤 Create response body: ${resp.data}');

      if (resp.statusCode == 201) {
        print('✅ PlageHoraire created successfully');
        await getAllPlageHoraires(terrainId: Get.arguments['terrainId']);
        return true;
      } else {
        final Map<String, dynamic> responseData =
            (resp.data is Map<String, dynamic>)
                ? resp.data
                : Map<String, dynamic>.from(resp.data as Map);
        errorMessage.value = responseData['message'] ?? 'Failed to create';
        print('❌ Create failed: ${errorMessage.value}');
        return false;
      }
    } catch (e) {
      print('❌ Create exception: $e');
      errorMessage.value = 'Error: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
