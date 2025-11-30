import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:app/services/api_service.dart';

class HistoryController extends GetxController {
  final isLoading = false.obs;
  final notifications = <ScoreNotification>[].obs;
  final unreadCount = 0.obs;

  /// Submit score with player validation tracking
  /// Submit score with backend error handling and player validation tracking
  Future<bool> submitDirectScore({
    required String reservationId,
    required int? set1A,
    required int? set1B,
    required int? set2A,
    required int? set2B,
    required int? set3A,
    required int? set3B,
    required bool superTieBreak,
    required int? teamWin,
    required String p1A,
    required String p2A,
    required String p1B,
    required String p2B,
  }) async {
    try {
      print(
        '==================== 🧩 SCORE SUBMISSION START ====================',
      );
      print('Reservation ID: $reservationId');
      print('DEBUG: Received player parameters - p1A: $p1A, p2A: $p2A, p1B: $p1B, p2B: $p2B');

      final token = await ApiService.instance.getValidAccessToken();
      final userId = await FlutterSecureStorage().read(key: 'userId');

      if (token == null || userId == null) {
        print('🚫 Token or User ID is missing. Cannot submit score.');
        return false;
      }

      print('🌐 Endpoint: /reservations/$reservationId/score');

      // Build player validation map
      Map<String, String> playerValidations = {};
      if (p1A.isNotEmpty)
        playerValidations['p1A'] = '$p1A|1'; // current user submits
      if (p2A.isNotEmpty) playerValidations['p2A'] = '$p2A|0';
      if (p1B.isNotEmpty) playerValidations['p1B'] = '$p1B|0';
      if (p2B.isNotEmpty) playerValidations['p2B'] = '$p2B|0';

      final requestBody = {
        'Set1A': set1A,
        'Set1B': set1B,
        'Set2A': set2A,
        'Set2B': set2B,
        'Set3A': set3A,
        'Set3B': set3B,
        'supertiebreak': superTieBreak ? 1 : 0,
        'teamwin': teamWin,
        'p1A': playerValidations['p1A'],
        'p2A': playerValidations['p2A'],
        'p1B': playerValidations['p1B'],
        'p2B': playerValidations['p2B'],
        'submitter_id': userId,
        'score_status': 1, // pending validation
      };

      print('DEBUG: Player validations map: $playerValidations');
      print('📤 Sending payload: ${jsonEncode(requestBody)}');

      final resp = await ApiService.instance.put(
        '/reservations/$reservationId/score',
        data: requestBody,
      );

      print('📊 Backend Response Status: ${resp.statusCode}');
      print('📩 Backend Response Data: ${resp.data}');

      // Handle various response codes
      if (resp.statusCode == 200) {
        print('✅ Score successfully submitted! Creating notifications...');
        await _createScoreNotifications(
          reservationId: reservationId,
          submitterId: userId,
          players: [p1A, p2A, p1B, p2B],
        );
        print('📬 Notifications created successfully.');
        return true;
      } else if (resp.statusCode == 400) {
        print(
          '⚠️ Backend rejected score: Bad Request — likely invalid fields or validation rules.',
        );
      } else if (resp.statusCode == 401) {
        print('🔒 Unauthorized — token expired or invalid.');
      } else if (resp.statusCode == 403) {
        print(
          '🚫 Forbidden — you may not have permission to submit this score.',
        );
      } else if (resp.statusCode == 404) {
        print('❓ Reservation not found — verify the reservation ID.');
      } else if ((resp.statusCode ?? 0) >= 500) {
        print(
          '🔥 Server error (${resp.statusCode}) — something went wrong on the backend.',
        );
      } else {
        print(
          '🤔 Unexpected response (${resp.statusCode}): ${resp.data}',
        );
      }

      print(
        '==================== 🧩 SCORE SUBMISSION END ====================',
      );
      return false;
    } catch (e, stack) {
      print('💥 Exception caught during score submission: $e');
      print('📜 Stack trace: $stack');
      print(
        '==================== 🧩 SCORE SUBMISSION FAILED ====================',
      );
      return false;
    }
  }

  /// Create notifications for other players about score submission
  Future<void> _createScoreNotifications({
    required String reservationId,
    required String submitterId,
    required List<String> players,
  }) async {
    try {
      // Notify all players except the submitter
      final recipientIds =
          players.where((id) => id.isNotEmpty && id != submitterId).toList();

      for (final recipientId in recipientIds) {
        final notificationBody = {
          'recipient_id': recipientId,
          'reservation_id': reservationId,
          'submitter_id': submitterId,
          'type': 'score_suggestion',
          'message':
              'A player has suggested a match score. Please review and validate.',
        };
        await ApiService.instance.post(
          '/notifications',
          data: notificationBody,
        );
      }
    } catch (e) {
      print('💥 Error creating notifications: $e');
    }
  }

  /// Validate a suggested score
  Future<bool> validateScore({
    required String reservationId,
    required bool accept,
    int? alternativeSet1A,
    int? alternativeSet1B,
    int? alternativeSet2A,
    int? alternativeSet2B,
    int? alternativeSet3A,
    int? alternativeSet3B,
  }) async {
    try {
      final userId = await FlutterSecureStorage().read(key: 'userId');
      if (userId == null) return false;

      final requestBody = {
        'user_id': userId,
        'accept': accept,
        'alternative_score':
            accept
                ? null
                : {
                  'Set1A': alternativeSet1A,
                  'Set1B': alternativeSet1B,
                  'Set2A': alternativeSet2A,
                  'Set2B': alternativeSet2B,
                  'Set3A': alternativeSet3A,
                  'Set3B': alternativeSet3B,
                },
      };

      final resp = await ApiService.instance.post(
        '/reservations/$reservationId/validate-score',
        data: requestBody,
      );
      return resp.statusCode == 200;
    } catch (e) {
      print('💥 Error validating score: $e');
      return false;
    }
  }

  /// Fetch score notifications for current user
  Future<void> fetchNotifications() async {
    try {
      final userId = await FlutterSecureStorage().read(key: 'userId');
      if (userId == null) return;

      final resp = await ApiService.instance.get(
        '/notifications/user/$userId',
      );
      if (resp.statusCode == 200) {
        final List jsonData =
            resp.data is String ? json.decode(resp.data) : resp.data as List;
        notifications.assignAll(
          jsonData.map((data) => ScoreNotification.fromJson(
              data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data))).toList(),
        );
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      print('💥 Error fetching notifications: $e');
    }
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await ApiService.instance.put(
        '/notifications/$notificationId/read',
      );
      await fetchNotifications();
    } catch (e) {
      print('💥 Error marking notification as read: $e');
    }
  }

  /// Check if score entry window is open (within 24h after match end)
  bool isScoreEntryOpen(DateTime? endTime) {
    if (endTime == null) return false;
    final now = DateTime.now();
    return now.isAfter(endTime) && now.difference(endTime).inHours <= 24;
  }

  /// Auto-finalize score after 24h if no disputes
  Future<void> checkAndFinalizeScores() async {
    try {
      await ApiService.instance.post(
        '/reservations/finalize-pending-scores',
      );
    } catch (e) {
      print('💥 Error finalizing scores: $e');
    }
  }
}

class ScoreNotification {
  final String id;
  final String reservationId;
  final String submitterId;
  final String submitterName;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? scoreData;

  ScoreNotification({
    required this.id,
    required this.reservationId,
    required this.submitterId,
    required this.submitterName,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.scoreData,
  });

  factory ScoreNotification.fromJson(Map<String, dynamic> json) {
    return ScoreNotification(
      id: json['id'].toString(),
      reservationId: json['reservation_id'].toString(),
      submitterId: json['submitter_id'].toString(),
      submitterName: json['submitter_name'] ?? 'Unknown Player',
      type: json['type'] ?? 'score_suggestion',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      scoreData: json['score_data'],
    );
  }
}
