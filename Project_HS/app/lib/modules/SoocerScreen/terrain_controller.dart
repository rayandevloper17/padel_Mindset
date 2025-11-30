import 'dart:convert';
import 'package:app/modules/SoocerScreen/terrain_model.dart';
import 'package:get/get.dart';
import 'package:app/services/api_service.dart';

class TerrainController extends GetxController {
  // Change to list of terrains instead of single terrain
  RxList<Terrain> terrains = <Terrain>[].obs;
  var isLoading = false.obs;

  final String baseUrl = 'http://127.0.0.1:300/api/terrains';
  final String baseUrl2 = 'http://127.0.0.1:300/api/plage-horaire';

  // Fetch price by plage horaire ID
  Future<double?> fetchPriceByPlageHoraireId(int plageHoraireId) async {
    isLoading.value = true;

    try {
      final resp = await ApiService.instance.get(
        '/plage-horaire/$plageHoraireId',
      );

      if (resp.statusCode == 200) {
        final data =
            resp.data is Map<String, dynamic>
                ? resp.data as Map<String, dynamic>
                : json.decode(resp.data as String) as Map<String, dynamic>;
        return (data['price'] as num?)?.toDouble();
      } else {
        Get.snackbar('Error', 'Failed to fetch price');
        return null;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch plage horaire details by ID
  Future<Map<String, dynamic>?> fetchPlageHoraireById(
    int plageHoraireId,
  ) async {
    isLoading.value = true;

    try {
      final resp = await ApiService.instance.get(
        '/plage-horaire/$plageHoraireId',
      );

      if (resp.statusCode == 200) {
        final data =
            resp.data is Map<String, dynamic>
                ? resp.data as Map<String, dynamic>
                : json.decode(resp.data as String) as Map<String, dynamic>;
        return {
          'id': data['id'],
          'start_time': data['start_time'],
          'end_time': data['end_time'],
          'price': data['price'],
          'type': data['type'],
          'disponible': data['disponible'],
          'terrain_id': data['terrain_id'],
        };
      } else {
        Get.snackbar('Error', 'Failed to fetch plage horaire details');
        return null;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch all terrains
  Future<void> fetchAllTerrains() async {
    isLoading.value = true;

    try {
      final resp = await ApiService.instance.get('/terrains');
      print('Raw response: ${resp.data}');

      if (resp.statusCode == 200) {
        final List<dynamic> data =
            resp.data is List
                ? resp.data as List
                : json.decode(resp.data as String) as List<dynamic>;
        terrains.value = data.map((json) => Terrain.fromJson(json)).toList();
      } else {
        Get.snackbar('Error', 'Failed to load terrains');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Keep the original method if you still need it sometimes
  Future<void> fetchTerrainById(int id) async {
    isLoading.value = true;

    try {
      final resp = await ApiService.instance.get('/terrains/$id');

      if (resp.statusCode == 200) {
        final terrain = Terrain.fromJson(
          resp.data is Map<String, dynamic>
              ? resp.data as Map<String, dynamic>
              : json.decode(resp.data as String) as Map<String, dynamic>,
        );
        // Add to list if not already present
        if (!terrains.any((t) => t.id == terrain.id)) {
          terrains.add(terrain);
        }
      } else {
        Get.snackbar('Error', 'Terrain not found');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to get a specific terrain by ID from the loaded list
  Terrain? getTerrainById(int id) {
    try {
      return terrains.firstWhere((terrain) => terrain.id == id);
    } catch (e) {
      return null;
    }
  }

  // Optional: Method to refresh the data
  Future<void> refreshTerrains() async {
    await fetchAllTerrains();
  }
}
