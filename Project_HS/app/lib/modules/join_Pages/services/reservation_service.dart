import 'dart:convert';
import 'package:app/services/api_service.dart';

class ReservationService {
  final String baseUrl =
      "http://127.0.0.1:300"; // your backend (not used with ApiService)

  Future<Map<String, dynamic>> fetchReservationByCode(String code) async {
    print('fetchReservationByCode $code');
    final resp = await ApiService.instance.get('/reservations/$code');
    if (resp.statusCode == 200) {
      final data = resp.data;
      return data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(
            data is String ? json.decode(data) : data,
          );
    } else {
      throw Exception('Error ${resp.statusCode}: ${resp.data}');
    }
  }
}
