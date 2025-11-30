import 'package:app/modules/Padel/controller/controller_participant.dart';
import 'package:app/modules/match_day/userrating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:app/services/api_service.dart';

class ReservationMatchController extends GetxController {
  final reservations = <Reservation>[].obs;
  final isLoading = false.obs;
  final isSearching = false.obs;
  final searchResults = <Reservation>[].obs;
  final searchNotFound = false.obs; // true when a code search returns 404
  final currentUserId = ''.obs;
  final joinedMatches = <String, bool>{}.obs; // Track joined matches
  final reservationParticipants =
      <String, List<Participant>>{}.obs; // Track participants by reservation ID
  final userRatings =
      <String, List<UserRating>>{}.obs; // Track user ratings by user ID
  final isRatingLoading = false.obs;
  // Hydrated time slots for reservations whose plageHoraire is missing in history
  final hydratedSlots = <String, PlageHoraire>{}.obs; // key: reservationId
  // History-specific flags
  final historyErrorMessage = ''.obs;
  final historyEmpty = false.obs;
  final ApiService _apiService = Get.find<ApiService>();

  @override
  void onReady() async {
    super.onReady();
    // Load current user id from secure storage so we can mark joined slots
    final storage = FlutterSecureStorage();
    final uid = await storage.read(key: 'userId');
    currentUserId.value = uid ?? '';

    // await fetchReservations();
  }

  // NEW: Fetch only available reservations (not full)
  Future<void> fetchAvailableReservations() async {
    if (isLoading.value) return;

    print('🔄 Starting fetchAvailableReservations...');
    isLoading.value = true;

    try {
      final resp = await _apiService.get('/reservations/available/all');

      print('📊 Available Reservations API Response:');
      print('   Status Code: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final List jsonData =
            resp.data is List
                ? (resp.data as List)
                : (resp.data is String ? json.decode(resp.data as String) : []);

        final newReservations =
            jsonData.map((data) => Reservation.fromJson(data)).toList();

        if (!isClosed) {
          reservations.assignAll(newReservations);
          print(
            '💾 Available reservations stored in controller: ${reservations.length} items',
          );
        }

        // Mark joined status for reservations
        for (final reservation in reservations) {
          await fetchParticipantsForReservation(reservation.id);
          final participants = reservationParticipants[reservation.id] ?? [];
          final joined = participants.any(
            (p) => p.idUtilisateur.toString() == currentUserId.value,
          );
          joinedMatches[reservation.id] = joined;
        }

        print('✅ fetchAvailableReservations completed');
      } else if (resp.statusCode == 401) {
        print('❌ Unauthorized. Token may be expired.');
      } else {
        print('❌ Error: Server returned status code ${resp.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching available reservations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // NEW: Fetch available reservations by date
  Future<void> fetchAvailableReservationsByDate(String date) async {
    if (isLoading.value) return;

    print('🔄 Starting fetchAvailableReservationsByDate for date: $date');
    isLoading.value = true;

    try {
      final resp = await _apiService.get('/reservations/available/date/$date');

      print('📊 Available Reservations by Date API Response:');
      print('   Status Code: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final List jsonData =
            resp.data is List
                ? (resp.data as List)
                : (resp.data is String ? json.decode(resp.data as String) : []);

        final newReservations =
            jsonData.map((data) => Reservation.fromJson(data)).toList();

        if (!isClosed) {
          reservations.assignAll(newReservations);
          print(
            '💾 Available reservations for date $date stored in controller: ${reservations.length} items',
          );
        }

        // Mark joined status for reservations
        for (final reservation in reservations) {
          await fetchParticipantsForReservation(reservation.id);
          final participants = reservationParticipants[reservation.id] ?? [];
          final joined = participants.any(
            (p) => p.idUtilisateur == currentUserId.value,
          );
          joinedMatches[reservation.id] = joined;
        }

        print('✅ fetchAvailableReservationsByDate completed for date $date');
      } else if (resp.statusCode == 401) {
        print('❌ Unauthorized. Token may be expired.');
      } else {
        print('❌ Error: Server returned status code ${resp.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching available reservations by date: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // NEW: Check if user has date conflict
  Future<bool> checkDateConflict(String date) async {
    try {
      final resp = await _apiService.get(
        '/reservations/check-date-conflict/$date',
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        return data['hasConflict'] ?? false;
      } else {
        print('❌ Error checking date conflict: ${resp.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Error checking date conflict: $e');
      return false;
    }
  }

  // NEW: Check if user has conflict on the same date and time slot
  Future<bool> checkDateTimeConflict({
    required String date,
    required String plageId,
  }) async {
    try {
      final resp = await _apiService.get(
        '/reservations/check-date-time-conflict/$date/$plageId',
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        return data['hasConflict'] ?? false;
      } else {
        print('❌ Error checking date-time conflict: ${resp.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Error checking date-time conflict: $e');
      return false;
    }
  }

  // Future<void> fetchReservations() async {
  //   if (isLoading.value) return;

  //   print('🔄 Starting fetchReservations...');
  //   isLoading.value = true;

  //   try {
  //     // Use ApiService (Dio) so 401s auto-refresh and retry
  //     print('📡 Making API call to fetch reservations via ApiService...');
  //     final resp = await _apiService.get('/reservations');

  //     print('📊 Reservations API Response:');
  //     print('   Status Code: ${resp.statusCode}');
  //     try {
  //       print('   Response Body: ${resp.data}');
  //     } catch (_) {}

  //     if (resp.statusCode == 200) {
  //       final List jsonData =
  //           resp.data is List
  //               ? (resp.data as List)
  //               : (resp.data is String ? json.decode(resp.data as String) : []);

  //       final newReservations =
  //           jsonData.map((data) => Reservation.fromJson(data)).toList();

  //       if (!isClosed) {
  //         reservations.assignAll(newReservations);
  //         print(
  //           '💾 Reservations stored in controller: ${reservations.length} items',
  //         );

  //         // Print reservation IDs for debugging
  //         for (int i = 0; i < reservations.length; i++) {
  //           print('   Reservation $i: ID = ${reservations[i].id}');
  //         }
  //       }

  //       // Mark joined status for reservations
  //       for (final reservation in reservations) {
  //         await fetchParticipantsForReservation(reservation.id);
  //         final participants = reservationParticipants[reservation.id] ?? [];
  //         final joined = participants.any(
  //           (p) => p.idUtilisateur == currentUserId.value,
  //         );
  //         joinedMatches[reservation.id] = joined;
  //       }

  //       print('✅ fetchReservations completed. Loading state: false');
  //     } else if (resp.statusCode == 401) {
  //       // ApiService will attempt refresh automatically; if still 401, user will be redirected
  //       print(
  //         '❌ Unauthorized. Token may be expired. Refresh attempted by ApiService.',
  //       );
  //     } else {
  //       print('❌ Error: Server returned status code ${resp.statusCode}');
  //       try {
  //         print('   Response body: ${resp.data}');
  //       } catch (_) {}
  //     }
  //   } catch (e) {
  //     print('💥 Error fetching reservations: $e');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  /// Fetch authenticated user's reservation history
  Future<void> fetchUserReservationHistory() async {
    if (isLoading.value) return;
    isLoading.value = true;
    historyErrorMessage.value = '';
    historyEmpty.value = false;
    try {
      final resp = await _apiService.get('/reservations/history/me');
      print('📊 History API Status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final List jsonData =
            resp.data is List
                ? (resp.data as List)
                : (resp.data is String ? json.decode(resp.data as String) : []);

        // Pretty-print the entire raw JSON list to console for inspection
        try {
          final pretty = const JsonEncoder.withIndent('  ').convert(jsonData);
          print('\n================= 📜 USER RESERVATION HISTORY (RAW JSON) =================');
          print(pretty);
          print('======================================================================\n');
        } catch (e) {
          print('⚠️ Failed to pretty-print history JSON: $e');
        }

        final newReservations =
            jsonData.map((data) => Reservation.fromJson(data)).toList();
        reservations.assignAll(newReservations);
        // Populate participants for each reservation
        await fetchParticipantsForAllReservations(
          await _apiService.getValidAccessToken() ?? '',
        );

        // Proactively hydrate missing plageHoraire for history items
        final futures = <Future>[];
        for (final r in reservations) {
          if (r.plageHoraire == null && r.idPlageHoraire.isNotEmpty) {
            futures.add(_hydrateSlotForReservation(r));
          }
        }
        if (futures.isNotEmpty) {
          await Future.wait(futures);
        }

        // Debug: print effective slot summary after hydration
        try {
          print('\n🧠 Effective slots after hydration:');
          for (final r in reservations) {
            final ph = r.plageHoraire ?? getHydratedSlotForReservationId(r.id);
            if (ph != null) {
              final s = ph.startTime; // no device-local conversion
              final e = ph.endTime;   // use as-is
              final start = '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
              final end = '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
              print('   • Reservation ${r.id} ➜ ${start}–${end} (slotId=${ph.id})');
            } else {
              print('   • Reservation ${r.id} ➜ no slot (id_plage_horaire=${r.idPlageHoraire})');
            }
          }
          print('✅ Hydration summary printed');
        } catch (e) {
          print('⚠️ Failed to print hydration summary: $e');
        }
      } else if (resp.statusCode == 404) {
        historyEmpty.value = true;
        reservations.assignAll([]);
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        historyErrorMessage.value = 'Authentication error';
        reservations.assignAll([]);
      } else {
        historyErrorMessage.value = 'Unable to load matches. Please try again.';
        reservations.assignAll([]);
      }
    } catch (e) {
      print('💥 Error fetching user reservation history: $e');
      historyErrorMessage.value = 'Network failure';
      reservations.assignAll([]);
    } finally {
      isLoading.value = false;
    }
  }

  /// Public helper: ensure reservation has a hydrated plageHoraire.
  /// Does nothing if already present.
  Future<void> ensurePlageHoraireHydrated(Reservation reservation) async {
    if (reservation.plageHoraire != null) return;
    if (hydratedSlots.containsKey(reservation.id)) return;
    await _hydrateSlotForReservation(reservation);
  }

  /// Returns the effective slot for a reservation (inline or hydrated)
  PlageHoraire? getHydratedSlotForReservationId(String reservationId) {
    return hydratedSlots[reservationId];
  }

  /// Internal: hydrate and cache plageHoraire for a reservation
  Future<void> _hydrateSlotForReservation(Reservation r) async {
    try {
      final ph = await fetchPlageHoraireById(r.idPlageHoraire);
      if (ph != null) {
        hydratedSlots[r.id] = ph;
      }
    } catch (e) {
      print('⚠️ Failed to hydrate plageHoraire for reservation ${r.id}: $e');
    }
  }

  /// Fetch plageHoraire by id from backend and parse to local-time model
  Future<PlageHoraire?> fetchPlageHoraireById(String id) async {
    try {
      final resp = await _apiService.get('/plage-horaire/$id');
      if (resp.statusCode == 200) {
        // The backend wraps result in { success, data }
        final Map<String, dynamic> decoded =
            (resp.data is Map<String, dynamic>)
                ? (resp.data as Map<String, dynamic>)
                : (resp.data is String
                    ? json.decode(resp.data as String)
                    : {});
        final data = decoded['data'] ?? decoded; // be tolerant to shape
        if (data is Map<String, dynamic>) {
          return PlageHoraire.fromJson(data);
        }
      } else {
        print('❌ Failed to fetch plageHoraire $id: ${resp.statusCode}');
      }
    } catch (e) {
      print('💥 Exception fetching plageHoraire $id: $e');
    }
    return null;
  }

  /// Search reservation by code (calls backend /api/reservations/code/:code)
  /// Optional: restrict results to a match type via [expectedTyper]
  /// typer: 1 => Private, 2 => Open
  Future<void> searchByCode(String code, {int? expectedTyper = 2}) async {
    searchNotFound.value = false;
    searchResults.clear();

    final query = code.trim();
    if (query.isEmpty) {
      // clear search and return
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    try {
      print(
        '🔎 Searching reservation by code "$query" (expectedTyper=$expectedTyper)...',
      );
      final resp = await _apiService.get('/reservations/code/$query');
      print('🔎 Search response status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data =
            resp.data is Map<String, dynamic>
                ? (resp.data as Map<String, dynamic>)
                : (resp.data is String ? json.decode(resp.data as String) : {});
        final found = Reservation.fromJson(data);
        print(
          '🔍 Found reservation: id=${found.id}, typer=${found.typer}, etat=${found.etat}, coder=${found.coder}',
        );

        final matchesType =
            expectedTyper == null || found.typer == expectedTyper;
        // For open matches, we keep a stricter status check to avoid showing closed items.
        // For private matches, accept any status; the page UI handles joinability.
        bool isAcceptable;
        if (expectedTyper == 2) {
          final et = (found.etat ?? '').toString().toLowerCase();
          isAcceptable =
              et.contains('attente') ||
              et.contains('pending') ||
              et == '1' ||
              et.contains('waiting');
        } else {
          isAcceptable = true;
        }

        if (matchesType && isAcceptable) {
          searchResults.assignAll([found]);
          searchNotFound.value = false;
          // fetch participants for the found reservation so circles render
          await fetchParticipantsForReservation(found.id);
          print('✅ Search accepted. Results updated.');
        } else {
          print(
            '🚫 Search rejected. Reasons: matchesType=$matchesType, isAcceptable=$isAcceptable',
          );
          searchResults.clear();
          searchNotFound.value = true;
        }
      } else if (resp.statusCode == 404) {
        print('🔎 No reservation found for code "$query" (404).');
        searchResults.clear();
        searchNotFound.value = true;
      } else {
        print(
          '⚠️ Unexpected search status: ${resp.statusCode}. Body: ${resp.data}',
        );
        searchResults.clear();
        searchNotFound.value = true;
      }
    } catch (e) {
      print('💥 Error searching reservation by code: $e');
      searchResults.clear();
      searchNotFound.value = true;
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> fetchParticipantsForAllReservations(String? token) async {
    if (token == null) {
      print('❌ No token provided for fetching participants');
      return;
    }

    print('👥 Starting to fetch participants for all reservations...');
    print('   Total reservations to process: ${reservations.length}');

    for (int i = 0; i < reservations.length; i++) {
      final reservation = reservations[i];
      print('\n🔍 Processing reservation ${i + 1}/${reservations.length}');
      print('   Reservation ID: ${reservation.id}');

      try {
        final participants = await fetchParticipantsByReservationId(
          reservation.id,
          token,
        );

        print(
          '   ✅ Found ${participants.length} participants for reservation ${reservation.id}',
        );

        if (!isClosed) {
          reservationParticipants[reservation.id] = participants;
          print('   💾 Participants stored for reservation ${reservation.id}');
        }
      } catch (e) {
        print(
          '   ❌ Error fetching participants for reservation ${reservation.id}: $e',
        );
      }
    }

    print('\n🎉 Completed fetching participants for all reservations');
    print('📊 Summary:');
    reservationParticipants.forEach((reservationId, participants) {
      print(
        '   Reservation $reservationId: ${participants.length} participants',
      );
    });
  }

  Future<List<Participant>> fetchParticipantsByReservationId(
    String reservationId,
    String token,
  ) async {
    print('🔍 Fetching participants for reservation: $reservationId');

    try {
      final resp = await _apiService.get(
        '/participants/reservation/$reservationId',
      );

      print('📊 Participants API Response for reservation $reservationId:');
      print('   Status Code: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final List jsonData =
            resp.data is List
                ? (resp.data as List)
                : (resp.data is String ? json.decode(resp.data as String) : []);

        // Print each participant data for debugging
        for (int i = 0; i < jsonData.length; i++) {
          print('   Participant $i: ${jsonData[i]}');
        }

        var participants =
            jsonData.map((data) => Participant.fromJson(data)).toList();

        // Fetch user details for each participant
        final updatedParticipants = <Participant>[];
        for (var participant in participants) {
          try {
            final userResp = await _apiService.get(
              '/utilisateurs/${participant.idUtilisateur}',
            );

            if (userResp.statusCode == 200) {
              final userData =
                  userResp.data is Map<String, dynamic>
                      ? (userResp.data as Map<String, dynamic>)
                      : (userResp.data is String
                          ? json.decode(userResp.data as String)
                          : {});
              final user = User.fromJson(userData);

              // Create new Participant with user data
              final updatedParticipant = Participant(
                id: participant.id,
                idUtilisateur: participant.idUtilisateur,
                idReservation: participant.idReservation,
                estCreateur: participant.estCreateur,
                utilisateur: user,
                team: participant.team,
                teamIndex:
                    participant.teamIndex, // Preserve numeric slot index (0-3)
              );

              updatedParticipants.add(updatedParticipant);
              print(
                '✅ Fetched user data for participant ${participant.idUtilisateur}: ${userData['nom']} ${userData['prenom']}',
              );
            } else {
              print(
                '⚠️ Failed to fetch user data for participant ${participant.idUtilisateur}: ${userResp.statusCode}',
              );
              updatedParticipants.add(
                participant,
              ); // Keep original if fetch fails
            }
          } catch (e) {
            print(
              '⚠️ Error fetching user data for participant ${participant.idUtilisateur}: $e',
            );
            updatedParticipants.add(participant); // Keep original if error
          }
        }

        participants = updatedParticipants;

        // store participants
        if (!isClosed) {
          reservationParticipants[reservationId] = participants;
        }

        // mark whether current user has joined
        try {
          final storage = FlutterSecureStorage();
          final uid = await storage.read(key: 'userId');
          if (uid != null) {
            final hasJoined = participants.any(
              (p) => p.idUtilisateur.toString() == uid,
            );
            joinedMatches[reservationId] = hasJoined;
            currentUserId.value = uid; // ensure currentUserId is set
          }
        } catch (e) {
          print('⚠️ Error while computing joined state: $e');
        }

        return participants;
      } else {
        print('❌ Error fetching participants for reservation $reservationId');
        print('   Status: ${resp.statusCode}');
        try {
          print('   Response: ${resp.data}');
        } catch (_) {}
        return [];
      }
    } catch (e) {
      print(
        '💥 Exception in fetchParticipantsByReservationId for $reservationId: $e',
      );
      print('   Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Helper that fetches participants for a reservation using stored token
  Future<void> fetchParticipantsForReservation(String reservationId) async {
    final token = await _apiService.getValidAccessToken();
    if (token == null) return;
    await fetchParticipantsByReservationId(reservationId, token);
  }

  // Helper method to get participants for a specific reservation
  List<Participant> getParticipantsForReservation(String reservationId) {
    final participants = reservationParticipants[reservationId] ?? [];
    print(
      '🔍 Getting participants for reservation $reservationId: ${participants.length} found',
    );
    return participants;
  }

  // Helper method to get participant count for a reservation
  int getParticipantCount(String reservationId) {
    final count = getParticipantsForReservation(reservationId).length;
    print('📊 Participant count for reservation $reservationId: $count');
    return count;
  }

  // Helper method to check if current user has joined a reservation
  bool hasUserJoinedReservation(String reservationId, String userId) {
    final participants = getParticipantsForReservation(reservationId);
    final hasJoined = participants.any(
      (participant) => participant.idUtilisateur.toString() == userId,
    );
    print('❓ User $userId joined reservation $reservationId: $hasJoined');
    return hasJoined;
  }

  Future<bool> joinMatch(String reservationId) async {
    try {
      final storage = FlutterSecureStorage();
      final token = await _apiService.getValidAccessToken();
      final uid = await storage.read(key: 'userId');

      if (token == null || uid == null) {
        print('Error joining match: missing token or userId');
        return false;
      }

      final participantsUrl = Uri.parse('http://0.0.0.0:300/api/participants');
      final participantBody = {
        'id_reservation': int.tryParse(reservationId) ?? reservationId,
        'id_utilisateur': int.tryParse(uid) ?? uid,
        'est_createur': false,
        // Default open-match join uses Sur place payment and unpaid state
        'typepaiement': 2,
        'statepaiement': 0,
      };

      final resp = await _apiService.post(
        '/participants',
        data: participantBody,
      );

      if (resp.statusCode == 201) {
        joinedMatches[reservationId] = true;
        await fetchParticipantsForReservation(reservationId);
        return true;
      } else {
        print('Error joining match: ${resp.statusCode}');
        try {
          print('Response: ${resp.data}');
        } catch (_) {}
        return false;
      }
    } catch (e) {
      print('Error joining match: $e');
      return false;
    }
  }

  /// Join a match with explicit team assignment based on tapped slot.
  /// teamNum should be 0 for Club A (slots 0-1) and 1 for Club B (slots 2-3).
  Future<bool> joinMatchWithTeam(String reservationId, int teamNum) async {
    try {
      final storage = FlutterSecureStorage();
      final token = await _apiService.getValidAccessToken();
      final uid = await storage.read(key: 'userId');

      if (token == null || uid == null) {
        print('Error joining match with team: missing token or userId');
        return false;
      }

      // Validate team value range 0–3
      if (teamNum < 0 || teamNum > 3) {
        print('Team must be 0, 1, 2, or 3');
        return false;
      }

      final participantsUrl = Uri.parse(
        'http://154.241.84.117:300/api/participants',
      );
      final participantBody = {
        'id_reservation': int.tryParse(reservationId) ?? reservationId,
        'id_utilisateur': int.tryParse(uid) ?? uid,
        'est_createur': false,
        'team': teamNum,
        // Default open-match join uses Sur place payment and unpaid state
        'typepaiement': 2,
        'statepaiement': 0,
      };

      final resp = await _apiService.post(
        '/participants',
        data: participantBody,
      );

      if (resp.statusCode == 201) {
        joinedMatches[reservationId] = true;
        await fetchParticipantsForReservation(reservationId);
        // If the match reached 4 players, mark it as valid (etat=1)
        await _setReservationValidIfFull(reservationId);
        return true;
      } else {
        print('Error joining match with team: ${resp.statusCode}');
        try {
          print('Response: ${resp.data}');
        } catch (_) {}
        return false;
      }
    } catch (e) {
      print('Error joining match with team: $e');
      return false;
    }
  }

  Future<bool> leaveMatch(String reservationId) async {
    try {
      final resp = await _apiService.get('/leave-match/$reservationId');

      if (resp.statusCode == 200) {
        joinedMatches[reservationId] = false;
        await fetchParticipantsForReservation(reservationId);
        return true;
      } else {
        print('Error leaving match: ${resp.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error leaving match: $e');
      return false;
    }
  }

  bool isMatchJoined(String reservationId) {
    return joinedMatches[reservationId] ?? false;
  }

  List<Reservation> getFilteredReservations(String sportType) {
    return reservations
        .where(
          (reservation) =>
              reservation.terrain?.type.toUpperCase() ==
                  sportType.toUpperCase() &&
              reservation.typer == 2 &&
              reservation.etat == 'En attente',
        )
        .toList();
  }

  /// Mark reservation as valid if participant count is 4
  Future<void> _setReservationValidIfFull(String reservationId) async {
    try {
      final count = getParticipantCount(reservationId);
      if (count >= 4) {
        // Mark reservation as valid in backend when full
        final resp = await _apiService.put(
          '/reservations/$reservationId',
          data: {'etat': 'valid'},
        );
        if (resp.statusCode == 200) {
          final idx = reservations.indexWhere((r) => r.id == reservationId);
          if (idx != -1) {
            final r = reservations[idx];
            reservations[idx] = Reservation(
              id: r.id,
              idUtilisateur: r.idUtilisateur,
              idTerrain: r.idTerrain,
              idPlageHoraire: r.idPlageHoraire,
              date: r.date,
              etat: 'valid',
              prixTotal: r.prixTotal,
              dateCreation: r.dateCreation,
              dateModif: DateTime.now(),
              qrcode: r.qrcode,
              coder: r.coder,
              nombreJoueurs: r.nombreJoueurs,
              terrain: r.terrain,
              utilisateur: r.utilisateur,
              plageHoraire: r.plageHoraire,
              typer: r.typer,
            );
          }
        } else {
          print(
            'Failed to update reservation etat. Status: ${resp.statusCode}',
          );
        }
      }
    } catch (e) {
      print('Error updating reservation etat to valid: $e');
    }
  }

  // Ratings helpers
  List<UserRating> getRatingsForUser(String userId) {
    final ratings = userRatings[userId] ?? [];
    return ratings;
  }

  double getAverageRatingForUser(String userId) {
    final ratings = getRatingsForUser(userId);
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold(0.0, (sum, rating) => sum + rating.note);
    return total / ratings.length;
  }

  Future<void> fetchUserRatings(String userId) async {
    isRatingLoading.value = true;
    try {
      final resp = await _apiService.get('/notes/user/$userId');
      if (resp.statusCode == 200) {
        final List jsonData =
            resp.data is List
                ? (resp.data as List)
                : (resp.data is String ? json.decode(resp.data as String) : []);
        final ratings =
            jsonData.map((data) => UserRating.fromJson(data)).toList();
        userRatings[userId] = ratings;
      }
    } catch (_) {
    } finally {
      isRatingLoading.value = false;
    }
  }

  Future<bool> createUserRating({
    required String idNoteur,
    required String idReservation,
    required int note,
  }) async {
    isRatingLoading.value = true;
    try {
      final requestBody = {
        'id_noteur': idNoteur,
        'id_reservation': idReservation,
        'note': note,
      };
      final resp = await _apiService.post('/notes', data: requestBody);
      if (resp.statusCode == 201) {
        await fetchUserRatings(idNoteur);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      isRatingLoading.value = false;
    }
  }
}

class Reservation {
  final String id;
  final String idUtilisateur;
  final String idTerrain;
  final String idPlageHoraire;
  final String date;
  final String etat;
  final double prixTotal;
  final DateTime? dateCreation;
  final DateTime? dateModif;
  final String? qrcode;
  final String? coder;
  final int? nombreJoueurs;
  final Terrain? terrain;
  final Utilisateur? utilisateur;
  final PlageHoraire? plageHoraire;
  final int? typer;

  Reservation({
    required this.id,
    required this.idUtilisateur,
    required this.idTerrain,
    required this.idPlageHoraire,
    required this.date,
    required this.etat,
    required this.prixTotal,
    required this.dateCreation,
    required this.dateModif,
    this.qrcode,
    this.coder,
    this.nombreJoueurs,
    this.terrain,
    this.utilisateur,
    this.plageHoraire,
    this.typer,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'].toString(),
      idUtilisateur: json['id_utilisateur'].toString(),
      idTerrain: json['id_terrain'].toString(),
      idPlageHoraire: json['id_plage_horaire'].toString(),
      date: json['date'] ?? '',
      etat: json['etat']?.toString() ?? '',
      prixTotal: _parseDouble(json['prix_total']),
      dateCreation: _parseDateTime(json['date_creation']),
      dateModif: _parseDateTime(json['date_modif']),
      qrcode: json['qrcode'],
      coder: json['coder']?.toString(),
      nombreJoueurs: json['nombre_joueurs'],
      terrain:
          json['terrain'] != null ? Terrain.fromJson(json['terrain']) : null,
      utilisateur:
          json['utilisateur'] != null
              ? Utilisateur.fromJson(json['utilisateur'])
              : null,
      plageHoraire:
          json['plageHoraire'] != null
              ? PlageHoraire.fromJson(json['plageHoraire'])
              : null,
      typer:
          json['typer'] != null ? int.tryParse(json['typer'].toString()) : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}

class Terrain {
  final String id;
  final String name;
  final String type;
  final String imageUrl;

  Terrain({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
  });

  factory Terrain.fromJson(Map<String, dynamic> json) {
    return Terrain(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class Utilisateur {
  final String id;
  final String nom;
  final String prenom;
  final String dateNaissance;
  final String email;
  final String numeroTelephone;
  final String motDePasse;
  final double? creditBalance; // Single credit balance field
  final String? points;
  final double? note;
  final String? imageUrl;
  final DateTime? dateCreation;
  final DateTime? dateMisajour;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.email,
    required this.numeroTelephone,
    required this.motDePasse,
    this.creditBalance, // Single credit balance
    this.points,
    this.note,
    this.imageUrl,
    required this.dateCreation,
    required this.dateMisajour,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'].toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      dateNaissance: json['date_naissance'] ?? '',
      email: json['email'] ?? '',
      numeroTelephone: json['numero_telephone'] ?? '',
      motDePasse: json['mot_de_passe'] ?? '',
      creditBalance:
          (json['credit_balance'] ?? json['credit_gold_padel'])
              ?.toDouble(), // Prioritize new field with fallback
      points: json['points']?.toString(),
      note: json['note']?.toDouble(),
      imageUrl: json['image_url'],
      dateCreation: Reservation._parseDateTime(json['date_creation']),
      dateMisajour: Reservation._parseDateTime(json['date_misajour']),
    );
  }
}

class PlageHoraire {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int price;
  final int type;
  final bool disponible;
  final String terrainId;

  PlageHoraire({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.type,
    required this.disponible,
    required this.terrainId,
  });

  // Convert backend time strings to venue-local wall clock without using device tz
  static DateTime _parseVenueTime(String raw) {
    final text = raw.toString().trim();
    // Fixed venue offset in minutes (e.g., UTC+1 => 60)
    const int venueUtcOffsetMinutes = 60;

    // HH:mm or HH:mm:ss
    final hm = RegExp(r'^(\d{2}):(\d{2})(?::(\d{2}))?$');
    final hmMatch = hm.firstMatch(text);
    if (hmMatch != null) {
      final now = DateTime.now();
      final h = int.parse(hmMatch.group(1)!);
      final m = int.parse(hmMatch.group(2)!);
      return DateTime(now.year, now.month, now.day, h, m);
    }

    // If string carries timezone ('Z' or '+hh:mm'), convert deterministically
    final hasExplicitTz = text.endsWith('Z') || RegExp(r'[+-]\\d{2}:\\d{2}$').hasMatch(text);
    if (hasExplicitTz) {
      try {
        final dtUtc = DateTime.parse(text).toUtc();
        final dtVenue = dtUtc.add(Duration(minutes: venueUtcOffsetMinutes));
        return DateTime(dtVenue.year, dtVenue.month, dtVenue.day, dtVenue.hour, dtVenue.minute);
      } catch (_) {
        // Fall through
      }
    }

    // ISO without timezone or fallback
    try {
      final dt = DateTime.parse(text);
      return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    } catch (_) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
  }

  factory PlageHoraire.fromJson(Map<String, dynamic> json) {
    return PlageHoraire(
      id: json['id'].toString(),
      // Parse to venue-local clock
      startTime: _parseVenueTime(json['start_time']),
      endTime: _parseVenueTime(json['end_time']),
      price: json['price'] ?? 0,
      type: json['type'] ?? 0,
      disponible: json['disponible'] ?? false,
      terrainId: json['terrain_id'].toString(),
    );
  }
}
