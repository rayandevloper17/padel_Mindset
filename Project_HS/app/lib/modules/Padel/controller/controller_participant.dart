import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:app/services/api_service.dart';

// ---------------- MODELS ----------------
class Reservation {
  final int id;
  final String date;
  final Terrain terrain;
  final User utilisateur;
  final PlageHoraire plageHoraire;
  final int? nombreJoueurs;
  final String? etat;
  final double? prixTotal;
  final String? dateCreation;
  final String? dateModif;
  final String? qrcode;
  final String? typer;
  final String? coder;

  Reservation({
    required this.id,
    required this.date,
    required this.terrain,
    required this.utilisateur,
    required this.plageHoraire,
    this.nombreJoueurs,
    this.etat,
    this.prixTotal,
    this.dateCreation,
    this.dateModif,
    this.qrcode,
    this.typer,
    this.coder,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: int.tryParse(json['id'].toString()) ?? 0,
      date: json['date'] ?? '',
      nombreJoueurs: int.tryParse(json['nombre_joueurs']?.toString() ?? ''),
      terrain: Terrain.fromJson(json['terrain'] ?? {}),
      utilisateur: User.fromJson(json['utilisateur'] ?? {}),
      plageHoraire: PlageHoraire.fromJson(json['plageHoraire'] ?? {}),
      etat: json['etat']?.toString(),
      prixTotal: double.tryParse(json['prix_total']?.toString() ?? ''),
      dateCreation: json['date_creation']?.toString(),
      dateModif: json['date_modif']?.toString(),
      qrcode: json['qrcode']?.toString(),
      typer: json['typer']?.toString(),
      coder: json['coder']?.toString(),
    );
  }
}

class Terrain {
  final int id;
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
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class PlageHoraire {
  final int id;
  final String startTime;
  final String endTime;
  final double? price;

  PlageHoraire({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.price,
  });

  factory PlageHoraire.fromJson(Map<String, dynamic> json) {
    return PlageHoraire(
      id: int.tryParse(json['id'].toString()) ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? ''),
    );
  }
}

class User {
  final int id;
  final String nom;
  final String prenom;
  final String? dateNaissance;
  final String? email;
  final String? numeroTelephone;
  final double? creditBalance; // Single credit balance field
  final String? points;
  final double? note;
  final String? imageUrl;
  final String? dateCreation;
  final String? dateMisAJour;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.email,
    this.numeroTelephone,
    this.creditBalance, // Single credit balance
    this.points,
    this.note,
    this.imageUrl,
    this.dateCreation,
    this.dateMisAJour,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      dateNaissance: json['date_naissance']?.toString(),
      email: json['email']?.toString(),
      numeroTelephone: json['numero_telephone']?.toString(),
      creditBalance: double.tryParse(
        json['credit_balance']?.toString() ??
            json['credit_gold_padel']?.toString() ??
            '', // Fallback for backward compatibility
      ),
      points: json['points']?.toString(),
      note: double.tryParse(json['note']?.toString() ?? ''),
      imageUrl: json['image_url']?.toString(),
      dateCreation: json['date_creation']?.toString(),
      dateMisAJour: json['date_misajour']?.toString(),
    );
  }
}

class Participant {
  final int id;
  final int idUtilisateur;
  final int idReservation;
  final bool estCreateur;
  final User? utilisateur; // ✅ add this
  final String? team; // Team A or B (label for UI)
  final int? teamIndex; // Raw numeric slot index (0,1,2,3)

  Participant({
    required this.id,
    required this.idUtilisateur,
    required this.idReservation,
    required this.estCreateur,
    this.utilisateur,
    this.team,
    this.teamIndex,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    // Parse raw team value and compute label + index
    final rawTeam = json['team'];
    int? idx;
    String? label;
    if (rawTeam != null) {
      final s = rawTeam.toString();
      final n = int.tryParse(s);
      if (n != null) {
        idx = n;
        if (n == 0 || n == 1) label = 'A';
        if (n == 2 || n == 3) label = 'B';
      } else {
        if (s == 'A' || s == 'B') {
          label = s; // legacy string values, index unknown
        }
      }
    }

    return Participant(
      id: int.tryParse(json['id'].toString()) ?? 0,
      idUtilisateur: int.tryParse(json['id_utilisateur'].toString()) ?? 0,
      idReservation:
          int.tryParse(json['id_reservation']?.toString() ?? '0') ?? 0,
      estCreateur: json['est_createur'] ?? false,
      utilisateur:
          json['utilisateur'] != null
              ? User.fromJson(json['utilisateur'])
              : null,
      team: label,
      teamIndex: idx,
    );
  }
}

// ---------------- CONTROLLER ----------------
class MatchController extends GetxController {
  static const String baseUrl = 'http://127.0.0.1:300/api';
  final storage = const FlutterSecureStorage();

  var isLoading = false.obs;
  var reservations = <Reservation>[].obs;
  var participantsByReservation = <int, List<Participant>>{}.obs;
  var errorMessage = ''.obs;
  var selectedTime = ''.obs; // Added for time slot selection
  var showAvailableHoursOnly =
      false.obs; // Toggle for showing only available hours

  // Flag to track if user has selected a date
  var dateSelected = false.obs;

  // Removed manual HTTP headers; ApiService handles authentication.

  // Fetch all reservations (matches)

  // Observable values for date filtering and filtered reservations
  final selectedDate = DateTime.now().obs;
  final filteredReservations = <Reservation>[].obs;
  final allReservations =
      <Reservation>[].obs; // Store all reservations for filtering

  // Track last update time per reservation to support recency sorting
  final reservationLastUpdated = <int, DateTime>{}.obs;

  // Auto-refresh timer for real-time updates
  Timer? _refreshTimer;

  // Throttle and dedupe participant fetches per reservation
  final Map<int, DateTime> _lastParticipantsFetchAt = {};
  final Set<int> _participantsFetchInFlight = {};

  // Current user ID
  final currentUserId = ''.obs;

  @override
  void onReady() async {
    super.onReady();
    // Load current user id from secure storage
    final uid = await storage.read(key: 'userId');
    currentUserId.value = uid ?? '';

    // Default to today and fetch only today's matches
    final today = DateTime.now();
    selectedDate.value = DateTime(today.year, today.month, today.day);
    dateSelected.value = true;
    await getReservationsByDate(selectedDate.value);
    _startAutoRefresh();
  }

  // Filter reservations by time and availability toggle
  void filterReservationsByTime(String time) {
    // Clear any previous error messages
    errorMessage.value = '';

    // First, filter by time if needed and if the toggle is ON (which means enable time filtering)
    List<Reservation> timeFiltered;
    if (!showAvailableHoursOnly.value ||
        time.isEmpty ||
        time.toLowerCase() == 'all') {
      // If toggle is OFF (disable time filtering) or no time is selected or 'All' is selected, use all reservations
      timeFiltered = List.from(allReservations);
    } else {
      // Filter reservations by the selected time label (supports HH:MM, HH:MM - HH:MM, 9AM-10AM)
      timeFiltered =
          allReservations.where((reservation) {
            final sel = _extractHourMinute(time);
            final res = _extractHourMinute(reservation.plageHoraire.startTime);
            if (sel != null && res != null) {
              return sel.item1 == res.item1 && sel.item2 == res.item2;
            }
            return false;
          }).toList();
    }

    // Enforce showing only Match Ouvert (typer == 2)
    timeFiltered = timeFiltered.where(_isOpenMatch).toList();

    // Update both filtered and main reservations lists
    filteredReservations.value = timeFiltered;
    reservations.value = timeFiltered;

    // If no reservations match the filters, show a message
    if (reservations.isEmpty) {
      if (showAvailableHoursOnly.value) {
        errorMessage.value =
            time.isEmpty ? 'No matches found' : 'No matches available at $time';
      } else {
        errorMessage.value = 'No matches found';
      }
    }

    // Apply recency sorting
    _sortReservations();
  }

  // Get reservations filtered by date
  Future<void> getReservationsByDate(DateTime date) async {
    try {
      isLoading.value = true;
      // Format date to YYYY-MM-DD
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      // Use date-specific endpoints for speed
      final String path =
          showAvailableHoursOnly.value
              ? '/reservations/available/date/$formattedDate'
              : '/reservations/date/$formattedDate';

      final resp = await ApiService.instance.get(path);

      if (resp.statusCode == 200) {
        final List<dynamic> data =
            resp.data is List
                ? (resp.data as List)
                : (resp.data is String ? json.decode(resp.data as String) : []);
        final List<Reservation> fetchedReservations =
            data
                .where((e) => e != null && e is Map<String, dynamic>)
                .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
                .toList();

        // Keep only Match Ouvert (typer == 2)
        final openReservations =
            fetchedReservations.where(_isOpenMatch).toList();

        // Data is already scoped to the selected date by the backend
        allReservations.value = openReservations;

        // Apply filters based on current toggle state
        if (showAvailableHoursOnly.value) {
          // Only show matches with available spots, for the selected date
          // Endpoint already returns only available for the date
          filteredReservations.value = openReservations;
          reservations.value = openReservations;
        } else {
          // Show all matches for the selected date (open only)
          filteredReservations.value = openReservations;
          reservations.value = openReservations;
        }

        // Reset selected time when date changes
        selectedTime.value = '';

        // Mark that user has selected a date
        dateSelected.value = true;

        // Fetch participants concurrently for each reservation to speed up UI
        await Future.wait(reservations.map((r) => getParticipants(r.id)));

        // Sort after fetching participants
        _sortReservations();

        // Clear error message if successful
        errorMessage.value = '';
      } else {
        // Fallback: server may not support /reservations/date yet
        final bodyText = resp.data?.toString() ?? '';
        final isRouteMissing =
            resp.statusCode == 404 ||
            bodyText.contains('Route non trouvée') ||
            bodyText.contains('n\'existe pas');

        if (isRouteMissing) {
          // Fallback to fetching all reservations and filter client-side
          final allResp = await ApiService.instance.get('/reservations');
          if (allResp.statusCode == 200) {
            final List<dynamic> data =
                allResp.data is List
                    ? (allResp.data as List)
                    : (allResp.data is String
                        ? json.decode(allResp.data as String)
                        : []);
            final List<Reservation> fetchedReservations =
                data
                    .where((e) => e != null && e is Map<String, dynamic>)
                    .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
                    .toList();

            // Filter to the selected calendar day only
            final selectedDateOnly = DateTime(date.year, date.month, date.day);
            final onSelectedDateReservations =
                fetchedReservations.where((reservation) {
                  try {
                    final rd = DateTime.parse(reservation.date);
                    final rdOnly = DateTime(rd.year, rd.month, rd.day);
                    return rdOnly.isAtSameMomentAs(selectedDateOnly);
                  } catch (_) {
                    return false;
                  }
                }).toList();

            // Only open matches
            final openOnSelectedDate =
                onSelectedDateReservations.where(_isOpenMatch).toList();

            // Assign baseline lists
            allReservations.value = openOnSelectedDate;
            filteredReservations.value = openOnSelectedDate;
            reservations.value = openOnSelectedDate;

            // Reset selection flags
            selectedTime.value = '';
            dateSelected.value = true;

            // Fetch participants concurrently
            await Future.wait(reservations.map((r) => getParticipants(r.id)));

            // If showing available only, re-filter after participants fetched
            if (showAvailableHoursOnly.value) {
              final available =
                  reservations
                      .where(
                        (r) =>
                            (participantsByReservation[r.id] ?? []).length < 4,
                      )
                      .toList();
              filteredReservations.value = available;
              reservations.value = available;
            }

            _sortReservations();
            errorMessage.value = '';
          } else {
            print(
              "Fallback body Of getReservationsByDate: ${allResp.data?.toString()}",
            );
            errorMessage.value =
                'Failed to load reservations: ${allResp.statusCode}';
          }
        } else {
          print("Response Of getReservationsByDate: ${resp.data?.toString()}");
          errorMessage.value =
              'Failed to load reservations: ${resp.statusCode}';
        }
      }
    } catch (e) {
      errorMessage.value = 'Error fetching reservations: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getReservations() async {
    try {
      isLoading.value = true;
      final resp = await ApiService.instance.get('/reservations');

      if (resp.statusCode == 200) {
        print("Response body reserv: ${resp.data}");
        final List<dynamic> data =
            resp.data is List
                ? (resp.data as List)
                : (resp.data is String ? json.decode(resp.data as String) : []);
        final List<Reservation> fetchedReservations =
            data
                .where((e) => e != null && e is Map<String, dynamic>)
                .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
                .toList();

        // Filter to show only upcoming matches (today and future)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day); // Start of today

        final upcomingReservations =
            fetchedReservations.where((reservation) {
              try {
                // Parse the reservation date
                final reservationDate = DateTime.parse(reservation.date);
                // Include matches from today onwards
                return reservationDate.isAfter(today) ||
                    reservationDate.isAtSameMomentAs(today);
              } catch (e) {
                // If date parsing fails, include the reservation to be safe
                return true;
              }
            }).toList();

        // Keep only Match Ouvert (typer == 2)
        final openUpcoming = upcomingReservations.where(_isOpenMatch).toList();

        // Store all reservations for filtering
        allReservations.value = openUpcoming;
        reservations.value = openUpcoming;

        // Fetch participants for each reservation
        for (var reservation in reservations) {
          await getParticipants(reservation.id);
        }
      } else {
        errorMessage.value = 'Failed to load reservations: ${resp.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching reservations: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch participants for a specific reservation (throttled, in-flight deduped)
  Future<void> getParticipants(int idReservation) async {
    // Throttle: skip if fetched recently (< 15s)
    final now = DateTime.now();
    final last = _lastParticipantsFetchAt[idReservation];
    if (last != null && now.difference(last) < const Duration(seconds: 15)) {
      return;
    }
    // Dedupe: skip if already fetching for this reservation
    if (_participantsFetchInFlight.contains(idReservation)) {
      return;
    }
    _participantsFetchInFlight.add(idReservation);

    // Don't set isLoading if we're in the middle of a build
    if (!Get.isRegistered<MatchController>()) {
      isLoading.value = true;
    }

    try {
      // Use targeted endpoint for a single reservation to reduce payload
      final resp = await ApiService.instance.get(
        '/participants/reservation/$idReservation',
      );

      if (resp.statusCode == 200) {
        final List<dynamic> data =
            resp.data is List
                ? (resp.data as List)
                : (resp.data is String ? json.decode(resp.data as String) : []);
        final participantsList =
            data
                .where((e) => e != null && e is Map<String, dynamic>)
                .map((e) => Participant.fromJson(e as Map<String, dynamic>))
                .toList();

        // Only update state if data actually changed (avoid churn)
        final current = participantsByReservation[idReservation] ?? [];
        final didChange = !_sameParticipants(current, participantsList);
        _lastParticipantsFetchAt[idReservation] = now;

        if (didChange) {
          participantsByReservation.update(
            idReservation,
            (_) => participantsList,
            ifAbsent: () => participantsList,
          );
          reservationLastUpdated[idReservation] = DateTime.now();
          _sortReservations();
        }
      } else {
        errorMessage.value = 'Failed to load participants: ${resp.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching participants: $e';
    } finally {
      _participantsFetchInFlight.remove(idReservation);
      // Only update isLoading if we set it initially
      if (!Get.isRegistered<MatchController>()) {
        isLoading.value = false;
      }
    }
  }

  // Get number of participants in a reservation
  int getParticipantCount(int idReservation) {
    return participantsByReservation[idReservation]?.length ?? 0;
  }

  // Get number of participants and check if reservation is full
  // Get number of participants and check if reservation is full
  bool isReservationFull(int idReservation) {
    // Get participants for this reservation
    final participants = participantsByReservation[idReservation] ?? [];

    // Count number of participants with same reservation ID
    final currentParticipants = participants.length;

    // Default max players is 4 for padel
    const maxPlayers = 4;

    return currentParticipants >= maxPlayers;
  }

  // Join a match (create participant)
  Future<bool> joinMatch(
    int idReservation,
    int idUtilisateur, {
    bool estCreateur = false,
    String? team,
    int? typepaiement,
    int? statepaiement,
  }) async {
    try {
      isLoading.value = true;
      final Map<String, dynamic> bodyMap = {
        'id_reservation': idReservation,
        'id_utilisateur': idUtilisateur,
        'est_createur': estCreateur,
        'team': team == 'A' ? 0 : (team == 'B' ? 1 : null),
      };

      // Include payment type/state if provided
      if (typepaiement != null) {
        bodyMap['typepaiement'] = typepaiement;
      }
      if (statepaiement != null) {
        bodyMap['statepaiement'] = statepaiement;
      }

      final resp = await ApiService.instance.post(
        '/participants',
        data: bodyMap,
      );

      if (resp.statusCode == 201) {
        await getParticipants(idReservation);
        // If reservation reached 4 players, disable the associated time slot (plage horaire)
        if (isReservationFull(idReservation)) {
          // Mark reservation as valid when full
          await _markReservationValid(idReservation);
          // Find the reservation to extract plage horaire id
          final reservation = reservations.firstWhere(
            (r) => r.id == idReservation,
            orElse:
                () => Reservation(
                  id: idReservation,
                  date: '',
                  terrain: Terrain(id: 0, name: '', type: '', imageUrl: ''),
                  utilisateur: User(id: 0, nom: '', prenom: ''),
                  plageHoraire: PlageHoraire(id: 0, startTime: '', endTime: ''),
                ),
          );

          if (reservation.plageHoraire.id != 0) {
            await _updatePlageHoraireDisponibilite(reservation.plageHoraire.id);
          }
        }
        return true;
      } else {
        final error =
            resp.data is String ? json.decode(resp.data) : (resp.data ?? {});
        errorMessage.value =
            error['error'] ?? 'Failed to join match: ${resp.statusCode}';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error joining match: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> joinMatchWithTeamIndex(
    int idReservation,
    int idUtilisateur, {
    required int teamIndex,
    bool estCreateur = false,
    int? typepaiement,
    int? statepaiement,
  }) async {
    try {
      isLoading.value = true;
      // ✅ Send exact position 0–3 directly in 'team'
      if (teamIndex < 0 || teamIndex > 3) {
        throw Exception("Team must be 0, 1, 2, or 3");
      }

      final Map<String, dynamic> bodyMap = {
        'id_reservation': idReservation,
        'id_utilisateur': idUtilisateur,
        'est_createur': estCreateur,
        'team': teamIndex, // ✅ Send exact slot index: 0, 1, 2, or 3
      };

      if (typepaiement != null) {
        bodyMap['typepaiement'] = typepaiement;
      }
      if (statepaiement != null) {
        bodyMap['statepaiement'] = statepaiement;
      }

      final resp = await ApiService.instance.post(
        '/participants',
        data: bodyMap,
      );

      if (resp.statusCode == 201) {
        await getParticipants(idReservation);
        if (isReservationFull(idReservation)) {
          // Mark reservation as valid when full
          await _markReservationValid(idReservation);
          final reservation = reservations.firstWhere(
            (r) => r.id == idReservation,
            orElse:
                () => Reservation(
                  id: idReservation,
                  date: '',
                  terrain: Terrain(id: 0, name: '', type: '', imageUrl: ''),
                  utilisateur: User(id: 0, nom: '', prenom: ''),
                  plageHoraire: PlageHoraire(id: 0, startTime: '', endTime: ''),
                ),
          );

          if (reservation.plageHoraire.id != 0) {
            await _updatePlageHoraireDisponibilite(reservation.plageHoraire.id);
          }
        }
        return true;
      } else {
        final error =
            resp.data is String ? json.decode(resp.data) : (resp.data ?? {});
        errorMessage.value =
            error['error'] ?? 'Failed to join match: ${resp.statusCode}';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error joining match: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Disable a plage horaire (time slot) by marking it as not available
  Future<void> _updatePlageHoraireDisponibilite(int idPlageHoraire) async {
    try {
      final token = await ApiService.instance.getValidAccessToken();
      if (token == null) throw Exception('No token found');

      final resp = await ApiService.instance.put(
        '/plage-horaire/$idPlageHoraire',
        data: {'disponible': false},
      );

      if (resp.statusCode == 200) {
        // Optional: log success
        // print('✅ Plage horaire $idPlageHoraire disabled (not available)');
      } else {
        // Optional: log failure
        // print('❌ Failed to disable plage horaire: ${resp.statusCode}');
      }
    } catch (e) {
      // Optional: log error
      // print('❌ Error updating plage horaire: $e');
    }
  }

  // Helper: Check if a user is already a participant
  // Compare consistently using string user IDs to avoid int/String mismatches
  bool isUserInReservation(String userId, int idReservation) {
    return participantsByReservation[idReservation]?.any(
          (p) => p.idUtilisateur.toString() == userId,
        ) ??
        false;
  }

  // Get participants by team
  List<Participant> getParticipantsByTeam(int idReservation, String team) {
    final participants = participantsByReservation[idReservation] ?? [];
    return participants.where((p) => p.team == team).toList();
  }

  // Check if a team is full (max 2 players per team)
  bool isTeamFull(int idReservation, String team) {
    final teamParticipants = getParticipantsByTeam(idReservation, team);
    return teamParticipants.length >= 2;
  }

  // Check if a specific slot index is occupied
  bool isSlotOccupied(int idReservation, int slotIndex) {
    final participants = participantsByReservation[idReservation] ?? [];
    return participants.any((p) => p.teamIndex == slotIndex);
  }

  // Compare participants lists by IDs and slot indices (order-insensitive)
  bool _sameParticipants(List<Participant> a, List<Participant> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    final Map<int, int?> ai = {for (final p in a) p.id: p.teamIndex};
    for (final p in b) {
      if (!ai.containsKey(p.id)) return false;
      if (ai[p.id] != p.teamIndex) return false;
    }
    return true;
  }

  @override
  void onClose() {
    // Stop auto-refresh when controller is disposed
    _refreshTimer?.cancel();
    super.onClose();
  }

  // Start periodic auto-refresh for real-time updates on today's matches
  void _startAutoRefresh() {
    // Auto-refresh disabled per request; users will refresh manually.
    _refreshTimer?.cancel();
  }

  // Extract hour/minute tuple in 24h from strings like "09:00", "09:00 - 10:00", "9AM-10AM", or API "09:00:00"
  _HM? _extractHourMinute(String s) {
    try {
      final String src = s.trim();
      final String first = src.split(RegExp(r"\s*-\s*"))[0];
      final RegExp re = RegExp(r"(?i)^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?");
      final match = re.firstMatch(first);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2) ?? '00');
        final meridian = match.group(3)?.toLowerCase();
        if (meridian == 'pm' && hour < 12) hour += 12;
        if (meridian == 'am' && hour == 12) hour = 0;
        final hh = hour.toString().padLeft(2, '0');
        final mm = minute.toString().padLeft(2, '0');
        return _HM(hh, mm);
      }
      final parts = first.split(':');
      if (parts.length >= 2) {
        return _HM(parts[0].padLeft(2, '0'), parts[1].padLeft(2, '0'));
      }
    } catch (_) {}
    return null;
  }

  // Sort reservations by last update desc, then by start datetime asc
  void _sortReservations() {
    int compare(Reservation a, Reservation b) {
      final au = reservationLastUpdated[a.id];
      final bu = reservationLastUpdated[b.id];
      if (au != null && bu != null) {
        final byUpd = bu.compareTo(au); // desc
        if (byUpd != 0) return byUpd;
      } else if (au != null || bu != null) {
        // Item with update comes first
        return bu != null ? 1 : -1;
      }
      final ad = _startDateTime(a);
      final bd = _startDateTime(b);
      return ad.compareTo(bd);
    }

    reservations.sort(compare);
    filteredReservations.sort(compare);
    reservations.refresh();
    filteredReservations.refresh();
  }

  DateTime _startDateTime(Reservation r) {
    DateTime date;
    try {
      date = DateTime.parse(r.date);
    } catch (_) {
      final now = DateTime.now();
      date = DateTime(now.year, now.month, now.day);
    }
    final hm = _extractHourMinute(r.plageHoraire.startTime);
    final h = int.tryParse(hm?.item1 ?? '00') ?? 0;
    final m = int.tryParse(hm?.item2 ?? '00') ?? 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  // --- Helpers: typer and etat updates ---
  bool _isOpenMatch(Reservation r) {
    final t = r.typer;
    if (t == null) return false;
    final s = t.toString().trim().toLowerCase();
    if (s == '2') return true;
    if (int.tryParse(s) == 2) return true;
    return s.contains('ouvert');
  }

  Future<void> _markReservationValid(int idReservation) async {
    try {
      final resp = await ApiService.instance.put(
        '/reservations/$idReservation',
        data: {'etat': 'valid'},
      );
      if (resp.statusCode == 200) {
        _updateReservationEtatLocal(idReservation, 'valid');
      } else {
        // Non-blocking: keep UI going even if backend update failed
      }
    } catch (_) {
      // Swallow to avoid breaking join flow
    }
  }

  void _updateReservationEtatLocal(int idReservation, String newEtat) {
    // Update in reservations
    final idx = reservations.indexWhere((r) => r.id == idReservation);
    if (idx != -1) {
      final r = reservations[idx];
      reservations[idx] = Reservation(
        id: r.id,
        date: r.date,
        terrain: r.terrain,
        utilisateur: r.utilisateur,
        plageHoraire: r.plageHoraire,
        nombreJoueurs: r.nombreJoueurs,
        etat: newEtat,
        prixTotal: r.prixTotal,
        dateCreation: r.dateCreation,
        dateModif: r.dateModif,
        qrcode: r.qrcode,
        typer: r.typer,
        coder: r.coder,
      );
      reservations.refresh();
    }
    // Update in filteredReservations
    final idxF = filteredReservations.indexWhere((r) => r.id == idReservation);
    if (idxF != -1) {
      final r = filteredReservations[idxF];
      filteredReservations[idxF] = Reservation(
        id: r.id,
        date: r.date,
        terrain: r.terrain,
        utilisateur: r.utilisateur,
        plageHoraire: r.plageHoraire,
        nombreJoueurs: r.nombreJoueurs,
        etat: newEtat,
        prixTotal: r.prixTotal,
        dateCreation: r.dateCreation,
        dateModif: r.dateModif,
        qrcode: r.qrcode,
        typer: r.typer,
        coder: r.coder,
      );
      filteredReservations.refresh();
    }
  }
}

// Simple HH/MM tuple
class _HM {
  final String item1;
  final String item2;
  _HM(this.item1, this.item2);
}
