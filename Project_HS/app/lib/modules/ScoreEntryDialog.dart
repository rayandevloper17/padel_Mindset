import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app/modules/History_Page/controller.dart';
import 'package:app/modules/Padel/controller/controller_participant.dart'
    as padel;
import 'package:app/modules/reservation_module/reservation_module.dart'
    as resmod;
import 'package:app/services/api_service.dart';
import 'package:app/modules/match_day/ontroller_reserv_match.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ScoreEntryDialog extends StatefulWidget {
  final dynamic reservation;
  final List<dynamic> participants;
  final VoidCallback onScoreSubmitted;
  final Map<String, dynamic>? initialScoreData;

  const ScoreEntryDialog({
    Key? key,
    required this.reservation,
    required this.participants,
    required this.onScoreSubmitted,
    this.initialScoreData,
  }) : super(key: key);

  @override
  State<ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends State<ScoreEntryDialog> {
  final TextEditingController set1TeamA = TextEditingController();
  final TextEditingController set1TeamB = TextEditingController();
  final TextEditingController set2TeamA = TextEditingController();
  final TextEditingController set2TeamB = TextEditingController();
  final TextEditingController set3TeamA = TextEditingController();
  final TextEditingController set3TeamB = TextEditingController();

  bool submitting = false;
  bool superTieBreak = false; // deprecated by auto detection
  int?
  selectedWinner; // deprecated by auto calculation (1 = Team A, 2 = Team B)

  // Live participants for this reservation within the dialog
  List<dynamic> _participants = const [];

  final HistoryController controller = Get.find();

  @override
  void initState() {
    super.initState();

    // Refresh participants when dialog opens
    _refreshParticipants();

    // Initialize local participants from widget
    _participants = List<dynamic>.from(widget.participants);

    final data = widget.initialScoreData;
    if (data != null) {
      set1TeamA.text = _toText(data['Set1A']);
      set1TeamB.text = _toText(data['Set1B']);
      set2TeamA.text = _toText(data['Set2A']);
      set2TeamB.text = _toText(data['Set2B']);
      set3TeamA.text = _toText(data['Set3A']);
      set3TeamB.text = _toText(data['Set3B']);
      // Ignore incoming manual flags; we compute automatically at submit
    }
  }

  Future<void> _refreshParticipants() async {
    print(
      '🔄 Refreshing participants for reservation ${widget.reservation.id}',
    );
    try {
      final controller = Get.find<ReservationMatchController>();
      await controller.fetchParticipantsForReservation(widget.reservation.id);
      var refreshedParticipants = controller.getParticipantsForReservation(
        widget.reservation.id,
      );

      print('✅ Refreshed participants count: ${refreshedParticipants.length}');
      for (int i = 0; i < refreshedParticipants.length; i++) {
        final p = refreshedParticipants[i];
        print(
          '   Participant $i: ID=${p.idUtilisateur}, Name=${p.utilisateur?.prenom ?? "N/A"} ${p.utilisateur?.nom ?? "N/A"}',
        );
      }

      // Inject reservation creator if missing and space available
      try {
        final creatorUser = widget.reservation.utilisateur;
        if (creatorUser != null) {
          final int creatorId = int.tryParse(creatorUser.id.toString()) ?? 0;
          final bool isCreatorPresent = refreshedParticipants.any(
            (p) => p.idUtilisateur == creatorId,
          );
          if (!isCreatorPresent && refreshedParticipants.length < 4) {
            final int reservationIdInt =
                int.tryParse(widget.reservation.id.toString()) ?? 0;
            // Build a User instance for avatar/name fields
            final dynamic cu = creatorUser;
            final syntheticUser = padel.User(
              id: creatorId,
              nom: (cu?.nom ?? '').toString(),
              prenom: (cu?.prenom ?? '').toString(),
              imageUrl: (cu?.imageUrl ?? cu?.image_url)?.toString(),
              note: double.tryParse((cu?.note)?.toString() ?? ''),
              email: (cu?.email)?.toString(),
              numeroTelephone:
                  (cu?.numeroTelephone ?? cu?.numero_telephone)?.toString(),
            );

            final syntheticCreator = padel.Participant(
              id: -1,
              idUtilisateur: creatorId,
              idReservation: reservationIdInt,
              estCreateur: true,
              utilisateur: syntheticUser,
            );
            // Prefer Team A slots first (indices 0-1), then Team B (2-3)
            if (refreshedParticipants.length < 2) {
              refreshedParticipants.insert(
                refreshedParticipants.length,
                syntheticCreator,
              );
            } else {
              refreshedParticipants.add(syntheticCreator);
            }
            print('👑 Injected reservation creator into dialog participants');
          }
        }
      } catch (e) {
        print('⚠️ Failed to inject reservation creator: $e');
      }

      // Check if current user is in participants
      final storage = FlutterSecureStorage();
      final currentUserId = await storage.read(key: 'userId');
      if (currentUserId != null) {
        final isCurrentUserInParticipants = refreshedParticipants.any(
          (p) => p.idUtilisateur.toString() == currentUserId,
        );
        print(
          '👤 Current user ID: $currentUserId, Is in participants: $isCurrentUserInParticipants',
        );

        if (!isCurrentUserInParticipants) {
          print('⚠️ Current user is NOT in participants list!');
        }
      }

      // Update local participants for display
      if (mounted) {
        setState(() {
          _participants = refreshedParticipants;
        });
      }
    } catch (e) {
      print('❌ Error refreshing participants: $e');
    }
  }

  String _toText(dynamic v) => v == null ? '' : v.toString();

  @override
  void dispose() {
    set1TeamA.dispose();
    set1TeamB.dispose();
    set2TeamA.dispose();
    set2TeamB.dispose();
    set3TeamA.dispose();
    set3TeamB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 950, maxHeight: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side - Players section
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Players Grid
                    Expanded(child: _buildPlayersGrid()),
                  ],
                ),
              ),
            ),

            // Vertical divider
            Container(width: 1, color: Color(0xFFFFD54F)),

            // Right side - Score input section
            Expanded(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and close button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getFormattedDate(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Sets Input - 3 columns in a row
                    Expanded(
                      child: Column(
                        children: [
                          // Team A scores (top row)
                          Row(
                            children: [
                              _buildScoreInput(set1TeamA, ''),
                              const SizedBox(width: 12),
                              _buildScoreInput(set2TeamA, ''),
                              const SizedBox(width: 12),
                              _buildScoreInput(set3TeamA, ''),
                            ],
                          ),

                          const SizedBox(height: 50),

                          // Submit button in center
                          _buildSubmitButton(),

                          const SizedBox(height: 16),

                          // Team B scores (bottom row)
                          Row(
                            children: [
                              _buildScoreInput(set1TeamB, ''),
                              const SizedBox(width: 12),
                              _buildScoreInput(set2TeamB, ''),
                              const SizedBox(width: 12),
                              _buildScoreInput(set3TeamB, ''),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Auto summary (Super Tie-Break + Winner)
                    _buildAutoComputedSummary(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate() {
    try {
      // Format: "12 avr. | 21:00 - 22:30"
      final reservation = widget.reservation;

      // Use the plageHoraire for time information
      if (reservation.plageHoraire != null) {
        final plage = reservation.plageHoraire!;
        final date = DateTime.parse(reservation.date); // Parse the date string
        final months = [
          'jan.',
          'fév.',
          'mar.',
          'avr.',
          'mai',
          'juin',
          'juil.',
          'août',
          'sept.',
          'oct.',
          'nov.',
          'déc.',
        ];

        final startTime = plage.startTime;
        final endTime = plage.endTime;

        final timeStart =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final timeEnd =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
        return '${date.day} ${months[date.month - 1]} | $timeStart - $timeEnd';
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return 'Date non disponible';
  }

  Widget _buildPlayersGrid() {
    // Create a list of 4 elements, initialized to null
    final players = List<dynamic>.filled(4, null);

    // Fill the list with actual participants
    for (int i = 0; i < _participants.length && i < 4; i++) {
      players[i] = _participants[i];
    }

    final teamA = players.sublist(0, 2);
    final teamB = players.sublist(2, 4);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Team A with winner checkbox
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPlayerCard(teamA[0]),
            const SizedBox(width: 6),
            _buildPlayerCard(teamA[1]),
          ],
        ),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(height: 1, color: Colors.white12),
        ),

        // Team B with winner checkbox
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPlayerCard(teamB[0]),
            const SizedBox(width: 12),
            _buildPlayerCard(teamB[1]),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerCard(dynamic participant) {
    final hasData = participant != null && participant.utilisateur != null;
    final prenom = hasData ? (participant.utilisateur.prenom ?? '') : '';
    final nom = hasData ? (participant.utilisateur.nom ?? '') : '';
    final initials =
        hasData
            ? '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
                .toUpperCase()
            : 'ES';

    // Get rating from participant
    final rating =
        hasData && (participant.utilisateur?.note != null)
            ? participant.utilisateur!.note.toString()
            : '-';

    return Expanded(
      child: Column(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: hasData ? const Color(0xFF2A2A2A) : Colors.grey.shade800,
              shape: BoxShape.circle,
              image:
                  hasData &&
                          (participant.utilisateur?.imageUrl?.isNotEmpty ??
                              false)
                      ? DecorationImage(
                        image: NetworkImage(
                          _fullImageUrl(participant.utilisateur!.imageUrl!),
                        ),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                hasData &&
                        !(participant.utilisateur?.imageUrl?.isNotEmpty ??
                            false)
                    ? Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : !hasData
                    ? Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            hasData ? prenom : 'Empty',
            style: TextStyle(
              color: hasData ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Rating badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: hasData ? const Color(0xFFFFD54F) : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rating,
              style: TextStyle(
                color: hasData ? Colors.black87 : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fullImageUrl(String url) {
    try {
      final raw = url.trim();
      if (raw.isEmpty) return '';
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return raw;
      }

      // Normalize file scheme or bare paths to server URL
      String path = raw;
      if (raw.startsWith('file://')) {
        path = raw.substring('file://'.length);
      }
      if (!path.startsWith('/')) {
        path = '/$path';
      }

      final api = Get.find<ApiService>();
      final base = api.baseUrl;
      final host =
          base.endsWith('/api') ? base.substring(0, base.length - 4) : base;

      final normalizedHost =
          host.endsWith('/') ? host.substring(0, host.length - 1) : host;
      return '$normalizedHost$path';
    } catch (_) {
      // Fallback to local backend host if ApiService is unavailable
      final fallbackHost = 'http://127.0.0.1:300';
      final raw = url.trim();
      String path =
          raw.startsWith('file://') ? raw.substring('file://'.length) : raw;
      if (!path.startsWith('/')) path = '/$path';
      return '$fallbackHost$path';
    }
  }

  Widget _buildScoreInput(TextEditingController controller, String hint) {
    return Expanded(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD54F)),
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '-',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 18),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  // Auto-computed summary replacing manual checkboxes
  Widget _buildAutoComputedSummary() {
    final a1 = int.tryParse(set1TeamA.text);
    final b1 = int.tryParse(set1TeamB.text);
    final a2 = int.tryParse(set2TeamA.text);
    final b2 = int.tryParse(set2TeamB.text);
    final a3 = int.tryParse(set3TeamA.text);
    final b3 = int.tryParse(set3TeamB.text);

    final autoSuper = _detectSuperTieBreak([a1, b1, a2, b2, a3, b3]);
    final win = _computeWinner([a1, a2, a3], [b1, b2, b3]);

    String winnerText;
    if (win == 1) {
      winnerText = 'Vainqueur: Équipe A';
    } else if (win == 2) {
      winnerText = 'Vainqueur: Équipe B';
    } else {
      winnerText = 'Vainqueur: Indéterminé';
    }

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  autoSuper ? 'Super Tie-Break: Oui' : 'Super Tie-Break: Non',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              winnerText,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  bool _detectSuperTieBreak(List<int?> values) {
    // Auto-detect: any two-digit or >=10 value indicates super tie-break
    for (final v in values) {
      if (v != null && v >= 10) return true;
    }
    return false;
  }

  int? _computeWinner(List<int?> aSets, List<int?> bSets) {
    int winsA = 0;
    int winsB = 0;
    for (int i = 0; i < aSets.length; i++) {
      final a = aSets[i];
      final b = bSets[i];
      if (a == null || b == null) continue;
      if (a == b) continue;
      if (a > b) {
        winsA++;
      } else {
        winsB++;
      }
    }
    if (winsA == winsB) return null;
    return winsA > winsB ? 1 : 2;
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: submitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child:
            submitting
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Sans résultat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  // Removed manual checkbox UI (auto-computed summary is shown instead)

  String _getPlayerId(int index) {
    print(
      '🎾 _getPlayerId called for index: $index, total participants: ${_participants.length}',
    );
    if (index < _participants.length) {
      final p = _participants[index];
      print(
        '   Participant at index $index: ${p.runtimeType}, ID: ${p.idUtilisateur}',
      );
      if (p is padel.Participant) {
        final idStr = p.idUtilisateur?.toString() ?? '';
        print('   Using participant ID: $idStr');
        return idStr;
      } else {
        print('   Wrong participant type');
      }
    }
    return '';
  }

  Future<void> _handleSubmit() async {
    setState(() => submitting = true);

    final set1A = int.tryParse(set1TeamA.text);
    final set1B = int.tryParse(set1TeamB.text);
    final set2A = int.tryParse(set2TeamA.text);
    final set2B = int.tryParse(set2TeamB.text);
    final set3A = int.tryParse(set3TeamA.text);
    final set3B = int.tryParse(set3TeamB.text);

    final p1A = _getPlayerId(0);
    final p2A = _getPlayerId(1);
    final p1B = _getPlayerId(2);
    final p2B = _getPlayerId(3);

    // Auto compute flags
    final autoSuper = _detectSuperTieBreak([
      set1A,
      set1B,
      set2A,
      set2B,
      set3A,
      set3B,
    ]);
    final autoWinner = _computeWinner(
      [set1A, set2A, set3A],
      [set1B, set2B, set3B],
    );

    final result = await controller.submitDirectScore(
      reservationId: widget.reservation.id,
      set1A: set1A,
      set1B: set1B,
      set2A: set2A,
      set2B: set2B,
      set3A: set3A,
      set3B: set3B,
      superTieBreak: autoSuper,
      teamWin: autoWinner,
      p1A: p1A,
      p2A: p2A,
      p1B: p1B,
      p2B: p2B,
    );

    setState(() => submitting = false);

    if (!mounted) return;

    if (result) {
      widget.onScoreSubmitted();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score submitted successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to submit score')));
    }
  }
}

// Score Validation Dialog remains the same as your original implementation
class ScoreValidationDialog extends StatefulWidget {
  final dynamic notification;
  final VoidCallback onValidated;

  const ScoreValidationDialog({
    Key? key,
    required this.notification,
    required this.onValidated,
  }) : super(key: key);

  @override
  State<ScoreValidationDialog> createState() => _ScoreValidationDialogState();
}

class _ScoreValidationDialogState extends State<ScoreValidationDialog> {
  bool showAlternativeForm = false;
  bool submitting = false;

  final TextEditingController altSet1A = TextEditingController();
  final TextEditingController altSet1B = TextEditingController();
  final TextEditingController altSet2A = TextEditingController();
  final TextEditingController altSet2B = TextEditingController();
  final TextEditingController altSet3A = TextEditingController();
  final TextEditingController altSet3B = TextEditingController();

  final HistoryController controller = Get.find();

  @override
  void dispose() {
    altSet1A.dispose();
    altSet1B.dispose();
    altSet2A.dispose();
    altSet2B.dispose();
    altSet3A.dispose();
    altSet3B.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreData = widget.notification.scoreData ?? {};

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.rate_review, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Validate Score',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.notification.submitterName} suggested this score:',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreColumn(
                        'Set 1',
                        scoreData['Set1A'],
                        scoreData['Set1B'],
                      ),
                      _buildScoreColumn(
                        'Set 2',
                        scoreData['Set2A'],
                        scoreData['Set2B'],
                      ),
                      if (scoreData['Set3A'] != null)
                        _buildScoreColumn(
                          'Set 3',
                          scoreData['Set3A'],
                          scoreData['Set3B'],
                        ),
                    ],
                  ),
                ),

                if (scoreData['supertiebreak'] == 1) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        0,
                        0,
                        0,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.stars,
                          color: Color.fromARGB(255, 228, 221, 229),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Super Tie-Break',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                if (!showAlternativeForm) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: submitting ? null : () => _handleAccept(),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              () => setState(() => showAlternativeForm = true),
                          icon: const Icon(Icons.edit),
                          label: const Text('Suggest Different'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Enter Your Suggested Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAltSetRow('Set 1', altSet1A, altSet1B),
                  const SizedBox(height: 12),
                  _buildAltSetRow('Set 2', altSet2A, altSet2B),
                  const SizedBox(height: 12),
                  _buildAltSetRow('Set 3', altSet3A, altSet3B, optional: true),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              () => setState(() => showAlternativeForm = false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              submitting ? null : _handleSuggestAlternative,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              submitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Submit Alternative'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreColumn(String label, dynamic scoreA, dynamic scoreB) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          '${scoreA ?? '-'}',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text('vs', style: TextStyle(color: Colors.white54, fontSize: 12)),
        Text(
          '${scoreB ?? '-'}',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAltSetRow(
    String label,
    TextEditingController controllerA,
    TextEditingController controllerB, {
    bool optional = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controllerA,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              hintText: 'A',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controllerB,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              hintText: 'B',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAccept() async {
    setState(() => submitting = true);

    final success = await controller.validateScore(
      reservationId: widget.notification.reservationId,
      accept: true,
    );

    setState(() => submitting = false);

    if (!mounted) return;

    if (success) {
      Get.snackbar(
        'Score Accepted',
        'You have validated this score',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      Navigator.pop(context);
      widget.onValidated();
    } else {
      Get.snackbar(
        'Validation Failed',
        'Unable to validate score. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleSuggestAlternative() async {
    if (altSet1A.text.isEmpty ||
        altSet1B.text.isEmpty ||
        altSet2A.text.isEmpty ||
        altSet2B.text.isEmpty) {
      Get.snackbar(
        'Incomplete Score',
        'Please enter scores for at least the first two sets',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => submitting = true);

    final success = await controller.validateScore(
      reservationId: widget.notification.reservationId,
      accept: false,
      alternativeSet1A: int.tryParse(altSet1A.text),
      alternativeSet1B: int.tryParse(altSet1B.text),
      alternativeSet2A: int.tryParse(altSet2A.text),
      alternativeSet2B: int.tryParse(altSet2B.text),
      alternativeSet3A:
          altSet3A.text.isNotEmpty ? int.tryParse(altSet3A.text) : null,
      alternativeSet3B:
          altSet3B.text.isNotEmpty ? int.tryParse(altSet3B.text) : null,
    );

    setState(() => submitting = false);

    if (!mounted) return;

    if (success) {
      Get.snackbar(
        'Alternative Submitted',
        'Other players will be notified of your suggested score',
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
      );
      Navigator.pop(context);
      widget.onValidated();
    } else {
      Get.snackbar(
        'Submission Failed',
        'Unable to submit alternative score. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}
