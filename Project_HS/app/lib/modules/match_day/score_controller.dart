import 'dart:convert';
import 'package:get/get.dart';
import 'package:app/services/api_service.dart';

class ScoreStatus {
  final String? finalScore;
  final String? scoreStatus; // Pending, Validated, Disputed, Invalid, None
  final List<dynamic> scores;
  final List<dynamic> votes;

  ScoreStatus({
    this.finalScore,
    this.scoreStatus,
    this.scores = const [],
    this.votes = const [],
  });

  factory ScoreStatus.fromJson(Map<String, dynamic> json) {
    return ScoreStatus(
      finalScore: json['finalScore']?.toString(),
      scoreStatus: json['scoreStatus']?.toString(),
      scores: json['scores'] ?? [],
      votes: json['votes'] ?? [],
    );
  }
}

class ScoreController extends GetxController {

  var statusByReservation = <String, ScoreStatus>{}.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  Future<ScoreStatus?> fetchStatus(String reservationId) async {
    try {
      final resp = await ApiService.instance
          .get('/scores/reservations/$reservationId/direct/status');
      if (resp.statusCode == 200) {
        final data = resp.data;
        final status = ScoreStatus.fromJson(
            data is String ? json.decode(data) : data as Map<String, dynamic>);
        statusByReservation[reservationId] = status;
        return status;
      } else {
        errorMessage.value = 'Status code ${resp.statusCode}: ${resp.data}';
      }
    } catch (e) {
      errorMessage.value = 'Failed to fetch score status: $e';
    }
    return null;
  }

  // Legacy endpoints below remain for compatibility if used elsewhere.
  Future<bool> submitScore(String reservationId, String scoreText) async {
    try {
      final resp = await ApiService.instance.post(
        '/reservations/$reservationId/scores',
        data: {'scoreText': scoreText},
      );
      if (resp.statusCode == 201) {
        await fetchStatus(reservationId);
        return true;
      }
    } catch (e) {
      errorMessage.value = 'Failed to submit score: $e';
    }
    return false;
  }

  Future<bool> validateScore(String reservationId, String scoreId) async {
    try {
      final resp = await ApiService.instance
          .post('/reservations/$reservationId/scores/$scoreId/validate');
      if (resp.statusCode == 200) {
        await fetchStatus(reservationId);
        return true;
      }
    } catch (e) {
      errorMessage.value = 'Failed to validate score: $e';
    }
    return false;
  }

  Future<bool> disputeScore(
    String reservationId,
    String scoreId,
    String? alternativeScoreText,
  ) async {
    try {
      final resp = await ApiService.instance.post(
        '/reservations/$reservationId/scores/$scoreId/dispute',
        data: {'alternativeScoreText': alternativeScoreText},
      );
      if (resp.statusCode == 200) {
        await fetchStatus(reservationId);
        return true;
      }
    } catch (e) {
      errorMessage.value = 'Failed to dispute score: $e';
    }
    return false;
  }
}