import 'package:app/modules/ScoreEntryDialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/modules/History_Page/controller.dart';
import 'package:app/modules/match_day/ontroller_reserv_match.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:app/services/api_service.dart';


// Simple reservation stub to satisfy ScoreEntryDialog when full reservation is unavailable
class _ReservationStub {
  final String id;
  _ReservationStub(this.id);
}

class EnhancedHistoryScreen extends StatefulWidget {
  const EnhancedHistoryScreen({super.key});

  @override
  State<EnhancedHistoryScreen> createState() => _EnhancedHistoryScreenState();
}

class _EnhancedHistoryScreenState extends State<EnhancedHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HistoryController historyController = Get.put(HistoryController());
  final ReservationMatchController reservationController = Get.find();
  // Track cancel progress per reservation for UI feedback
  final Set<String> _cancelInProgress = <String>{};
  // Keys for pull-to-refresh indicators
  final GlobalKey<RefreshIndicatorState> _matchesRefreshKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _notificationsRefreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      historyController.fetchNotifications();
      reservationController.fetchUserReservationHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: _refreshCurrentTab,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            const Tab(text: 'Matches'),
            Tab(
              child: Obx(
                () => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Notifications'),
                    if (historyController.unreadCount.value > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            '${historyController.unreadCount.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMatchesTab(), _buildNotificationsTab()],
      ),
    );
  }

  Future<void> _refreshCurrentTab() async {
    if (_tabController.index == 0) {
      _matchesRefreshKey.currentState?.show();
      await reservationController.fetchUserReservationHistory();
    } else {
      _notificationsRefreshKey.currentState?.show();
      await historyController.fetchNotifications();
    }
  }

  void _showScoreEntryNotAllowedDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Impossible d'entrer le score"),
          content: Text(reason),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleScoreEntryTap(dynamic reservation, List<dynamic> participants) {
    final enoughParticipants = participants.length == 4;
    final isMatchEnded =
        reservation.plageHoraire?.endTime != null &&
        DateTime.now().isAfter(reservation.plageHoraire.endTime);

    if (enoughParticipants && isMatchEnded) {
      _showScoreEntryDialog(reservation, participants);
    } else {
      String reason = '';
      if (!enoughParticipants) {
        reason = 'Le match doit avoir 4 participants.';
      } else if (!isMatchEnded) {
        reason = 'Le match n\'a pas encore eu lieu.';
      }
      _showScoreEntryNotAllowedDialog(context, reason);
    }
  }

  Widget _buildMatchesTab() {
    return Obx(() {
      // Always provide a scrollable child so pull-to-refresh works even when empty
      if (reservationController.isLoading.value &&
          reservationController.reservations.isEmpty) {
        return RefreshIndicator(
          key: _matchesRefreshKey,
          color: Colors.cyanAccent,
          backgroundColor: Colors.black,
          strokeWidth: 2.5,
          displacement: 64,
          onRefresh: () => reservationController.fetchUserReservationHistory(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              SizedBox(height: 200),
              Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      }

      if (reservationController.reservations.isEmpty) {
        return RefreshIndicator(
          key: _matchesRefreshKey,
          color: Colors.cyanAccent,
          backgroundColor: Colors.black,
          strokeWidth: 2.5,
          displacement: 64,
          onRefresh: () => reservationController.fetchUserReservationHistory(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              SizedBox(height: 140),
              Icon(Icons.history, size: 64, color: Colors.white38),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'No match history',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        key: _matchesRefreshKey,
        color: Colors.cyanAccent,
        backgroundColor: Colors.black,
        strokeWidth: 2.5,
        displacement: 64,
        onRefresh: () => reservationController.fetchUserReservationHistory(),
        child: Builder(
          builder: (context) {
            // Create a locally sorted copy to avoid mutating controller state
            List<dynamic> sortedReservations = List<dynamic>.from(
              reservationController.reservations,
            );
            //
            int? _tryParseNumericId(dynamic id) {
              if (id == null) return null;
              if (id is int) return id;
              final s = id.toString();
              // If the string contains non-digit chraracters, extract the first digit run
              final match = RegExp(r"\d+").firstMatch(s);
              if (match != null) {
                return int.tryParse(match.group(0)!);
              }
              return int.tryParse(s);
            }

            sortedReservations.sort((a, b) {
              final int? aId = _tryParseNumericId(a?.id);
              final int? bId = _tryParseNumericId(b?.id);
              if (aId != null && bId != null) {
                // Descending: larger IDs first
                return bId.compareTo(aId);
              }
              // Fallback to descending lexicographic compare if numeric parse fails
              return (b?.id?.toString() ?? '').compareTo(
                a?.id?.toString() ?? '',
              );
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedReservations.length,
              itemBuilder: (context, index) {
                final reservation = sortedReservations[index];
                return _buildMatchCard(reservation);
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildMatchCard(dynamic reservation) {
    final participants = reservationController.getParticipantsForReservation(
      reservation.id,
    );

    final DateTime? slotEnd = reservation.plageHoraire?.endTime;
    DateTime? matchEnd;
    try {
      if (reservation.date != null && slotEnd != null) {
        final dateOnly = DateTime.parse(reservation.date).toLocal();
        matchEnd = DateTime(
          dateOnly.year,
          dateOnly.month,
          dateOnly.day,
          slotEnd.hour,
          slotEnd.minute,
        );
      } else {
        matchEnd = slotEnd;
      }
    } catch (_) {
      matchEnd = slotEnd;
    }

    final now = DateTime.now();
    final isMatchEnded = matchEnd != null && now.isAfter(matchEnd);
    final within24h =
        matchEnd != null && now.difference(matchEnd).inHours <= 24;
    final enoughParticipants = participants.length == 4;
    final canEnterScore = isMatchEnded && within24h && enoughParticipants;

    // Determine if current user is the creator
    final String currentUserId = reservationController.currentUserId.value;
    final bool isCreator = participants.any(
      (p) =>
          (p.estCreateur == true) &&
          (p.idUtilisateur?.toString() == currentUserId),
    );

    // Compute match start for cancel gating
    final DateTime? startTime = reservation.plageHoraire?.startTime;
    final bool beforeStart = startTime != null && now.isBefore(startTime);

    // Robust cancelled detection: handle numeric and string states
    bool isCancelled = false;
    try {
      final etatStr = reservation.etat?.toString().toLowerCase();
      final etatNum = int.tryParse(reservation.etat?.toString() ?? '');
      isCancelled =
          etatNum == 1 || etatStr == 'annulé' || etatStr == 'cancelled';
    } catch (_) {}

    // Eligibility: reservation scheduled at least thresholdDays ahead
    final int thresholdDays = _getCancelThresholdDays(reservation);
    final bool exceedsDaysThreshold =
        startTime != null && startTime.difference(now).inDays >= thresholdDays;
    final bool canCancel = isCreator && exceedsDaysThreshold && !isCancelled;

    // Map etat and typer according to requirements:
    // - Match Ouvert (typer == 2): show 'Player missing' (only for open matches)
    // - Match Privé (typer == 1): means 'Valid' unless etat maps otherwise
    int? _parseTyper(dynamic typer) {
      try {
        if (typer == null) return null;
        if (typer is int) return typer;
        final t = typer.toString().trim().toLowerCase();
        final asInt = int.tryParse(t);
        if (asInt != null) return asInt;
        if (t.contains('ouvert')) return 2;
        if (t.contains('prv') || t.contains('priv') || t.contains('private')) {
          return 1;
        }
      } catch (_) {}
      return null;
    }

    int? _parseEtat(dynamic etat) {
      try {
        if (etat == null) return null;
        if (etat is int) return etat;
        final s = etat.toString().trim();
        final asInt = int.tryParse(s);
        if (asInt != null) return asInt;
        final lower = s.toLowerCase();
        if (lower.contains('attente') || lower.contains('pending')) return 0;
        if (lower.contains('valid')) return 1;
        if (lower.contains('termin') || lower.contains('over')) return 2;
        if (lower.contains('annul') || lower.contains('cancel')) return 3;
      } catch (_) {}
      return null;
    }

    String? _mapEtatLabel(int? code) {
      switch (code) {
        case 0:
          return 'En attente';
        case 1:
          return 'Valid';
        case 2:
          return 'Terminé';
        case 3:
          return 'Match annulé';
        default:
          return null;
      }
    }

    // Determine type and validity for conditional UI (code reveal, badges)
    final int? typerCode = _parseTyper(reservation.typer);
    final int? etatCode = _parseEtat(reservation.etat);
    final bool isPrivate = typerCode == 1;
    final bool isValidState =
        etatCode == 1 ||
        (reservation.etat?.toString().toLowerCase().contains('valid') ?? false);

    final String? mappedEtat = _mapEtatLabel(etatCode);

    String statusText = 'Closed';
    if (typerCode == 2) {
      // Open match: show Player missing when not full; otherwise map etat or default
      statusText =
          !enoughParticipants ? 'Player missing' : (mappedEtat ?? 'Valid');
    } else if (typerCode == 1) {
      // Private match: default to Valid unless etat provides specific label
      statusText = mappedEtat ?? 'Valid';
    } else if (mappedEtat != null) {
      statusText = mappedEtat;
    } else if (canEnterScore) {
      statusText = 'Score Entry Open';
    } else if (!isMatchEnded) {
      statusText = 'Pending';
    }

    final String timeLabel =
        (startTime != null && slotEnd != null)
            ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${slotEnd.hour.toString().padLeft(2, '0')}:${slotEnd.minute.toString().padLeft(2, '0')}'
            : '--:-- - --:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 0, 0, 0).withOpacity(0.08),
            const Color.fromARGB(255, 6, 6, 6).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.terrain?.name ?? 'Unknown Field',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildReservationIdBadge(reservation),
                  const SizedBox(height: 6),
                  _buildMatchTypeBadge(typerCode),
                ],
              ),
              _buildStatusBadge(canEnterScore, statusText),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                reservation.date,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(timeLabel, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          if (isPrivate && isValidState) ...[
            _buildMatchCodeReveal(reservation),
            const SizedBox(height: 12),
          ],
          if (canEnterScore)
            _buildScoreEntry(reservation, participants)
          else
            _buildClosedScoreMessage(matchEnd, enoughParticipants),
          if (!isCancelled && exceedsDaysThreshold)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildEligibilityBanner(
                thresholdDays: thresholdDays,
                refundAmount: reservation.prixTotal,
              ),
            ),
          const SizedBox(height: 12),
          if (canCancel)
            _buildCancelButton(
              onPressed: () => _confirmCancelReservation(reservation),
              refundAmount: reservation.prixTotal,
              isBusy: _cancelInProgress.contains(
                reservation.id is String
                    ? reservation.id
                    : reservation.id.toString(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchCodeReveal(dynamic reservation) {
    final String? code = reservation.coder ?? reservation.qrcode;
    return GestureDetector(
      onTap: () => _showMatchCodeDialog(code),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withOpacity(0.20),
              const Color(0xFF22D3EE).withOpacity(0.15),
            ],
          ),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
        ),
        child: Row(
          children: const [
            Icon(Icons.vpn_key, color: Colors.white70),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Afficher le code du match',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  void _showMatchCodeDialog(String? code) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.vpn_key, color: Colors.white70),
                    SizedBox(width: 8),
                    Text(
                      'Code du match',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: SelectableText(
                    code ?? 'Code indisponible',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed:
                          code == null
                              ? null
                              : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: code),
                                );
                                Get.snackbar(
                                  'Copié',
                                  'Code du match copié',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green.withOpacity(
                                    0.15,
                                  ),
                                );
                              },
                      icon: const Icon(Icons.copy, color: Colors.white),
                      label: const Text(
                        'Copier',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF6366F1,
                        ).withOpacity(0.25),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isActive, String statusText) {
    // Modern, animated status badge with gradients and icons
    List<Color> colors;
    IconData icon;

    switch (statusText) {
      case 'Valid':
        colors = const [Color(0xFF2ECC71), Color(0xFF27AE60)];
        icon = Icons.check_circle;
        break;
      case 'En attente':
      case 'Pending':
        colors = const [Color(0xFFFFB74D), Color(0xFFFFA726)];
        icon = Icons.schedule;
        break;
      case 'Terminé':
        colors = const [Color(0xFF64B5F6), Color(0xFF42A5F5)];
        icon = Icons.flag;
        break;
      case 'Match annulé':
      case 'Cancelled':
        colors = const [Color(0xFFFF6B6B), Color(0xFFE53935)];
        icon = Icons.cancel;
        break;
      case 'Player missing':
        colors = const [Color(0xFF00BCD4), Color(0xFF26C6DA)];
        icon = Icons.person_add_alt_1;
        break;
      case 'Score Entry Open':
        colors = const [Color(0xFFAB47BC), Color(0xFF8E24AA)];
        icon = Icons.edit;
        break;
      default:
        colors = const [Color(0xFF78909C), Color(0xFF607D8B)];
        icon = Icons.info;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      child: Container(
        key: ValueKey<String>(statusText),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationIdBadge(dynamic reservation) {
    final String id =
        reservation.id is String ? reservation.id : reservation.id.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2023), Color(0xFF2A2C31)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tag_outlined, color: Colors.white70, size: 14),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Match ID ',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                TextSpan(
                  text: '#$id',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTypeBadge(int? typerCode) {
    if (typerCode == null) return const SizedBox.shrink();
    final bool isPrivate = typerCode == 1;
    final String label = isPrivate ? 'Privé' : 'Ouvert';
    final IconData icon = isPrivate ? Icons.lock_outline : Icons.public;
    final List<Color> gradientColors =
        isPrivate
            ? [
              const Color(0xFF3B82F6).withOpacity(0.18),
              const Color(0xFF6366F1).withOpacity(0.14),
            ]
            : [
              const Color(0xFF06B6D4).withOpacity(0.18),
              const Color(0xFF10B981).withOpacity(0.14),
            ];
    final Color borderColor = (isPrivate
            ? const Color(0xFF6366F1)
            : const Color(0xFF06B6D4))
        .withOpacity(0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreEntry(dynamic reservation, List<dynamic> participants) {
    return GestureDetector(
      onTap: () => _handleScoreEntryTap(reservation, participants),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Row(
          children: const [
            Icon(Icons.sports_tennis, color: Colors.blue, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap to enter match score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedScoreMessage(DateTime? endTime, bool enoughParticipants) {
    String message = 'Score entry closed.';
    IconData icon = Icons.lock_clock;
    Color color = Colors.orange;

    if (endTime != null && DateTime.now().isAfter(endTime)) {
      final duration = DateTime.now().difference(endTime);
      message = 'Score entry closed (${_humanizeDuration(duration)} ago)';
    } else if (!enoughParticipants) {
      message = 'Player missing for score entry.';
      icon = Icons.person_off_outlined;
      color = Colors.red;
    } else {
      message = 'Match not played yet.';
      icon = Icons.hourglass_bottom;
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Obx(() {
      if (historyController.isLoading.value &&
          historyController.notifications.isEmpty) {
        return RefreshIndicator(
          key: _notificationsRefreshKey,
          color: Colors.deepPurpleAccent,
          backgroundColor: Colors.black,
          strokeWidth: 2.5,
          displacement: 64,
          onRefresh: () => historyController.fetchNotifications(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              SizedBox(height: 200),
              Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      }

      if (historyController.notifications.isEmpty) {
        return RefreshIndicator(
          key: _notificationsRefreshKey,
          color: Colors.deepPurpleAccent,
          backgroundColor: Colors.black,
          strokeWidth: 2.5,
          displacement: 64,
          onRefresh: () => historyController.fetchNotifications(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              SizedBox(height: 140),
              Icon(Icons.notifications_none, size: 64, color: Colors.white38),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        key: _notificationsRefreshKey,
        color: Colors.deepPurpleAccent,
        backgroundColor: Colors.black,
        strokeWidth: 2.5,
        displacement: 64,
        onRefresh: () => historyController.fetchNotifications(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: historyController.notifications.length,
          itemBuilder: (context, index) {
            final notification = historyController.notifications[index];
            final isUnread = !notification.isRead;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isUnread
                          ? Colors.blueAccent.withOpacity(0.4)
                          : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_tennis, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.submitterName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatTimestamp(notification.createdAt),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.message,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (notification.scoreData != null) ...[
                    const SizedBox(height: 12),
                    _buildScorePreview(notification.scoreData!),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            () => _showScoreValidationDialog(notification),
                        child: const Text('Review Score'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildScorePreview(Map<String, dynamic> scoreData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scoreColumn('Set 1', scoreData['Set1A'], scoreData['Set1B']),
          _scoreColumn('Set 2', scoreData['Set2A'], scoreData['Set2B']),
          if (scoreData['Set3A'] != null)
            _scoreColumn('Set 3', scoreData['Set3A'], scoreData['Set3B']),
        ],
      ),
    );
  }

  Widget _scoreColumn(String label, dynamic scoreA, dynamic scoreB) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '$scoreA - $scoreB',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _handleNotificationTap(dynamic notification) {
    historyController.markNotificationRead(notification.id);
    _showScoreValidationDialog(notification);
  }

  Widget _buildCancelButton({
    required VoidCallback onPressed,
    required double refundAmount,
    bool isBusy = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.credit_score,
                color: Colors.lightBlueAccent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Refund: ${_formatCredits(refundAmount)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: isBusy ? null : onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon:
              isBusy
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  )
                  : const Icon(Icons.cancel, color: Colors.red, size: 18),
          label: Text(
            isBusy ? 'Cancelling...' : 'Cancel Reservation',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showScoreEntryDialog(dynamic reservation, List<dynamic> participants) {
    showDialog(
      context: context,
      builder:
          (context) => ScoreEntryDialog(
            reservation: reservation,
            participants: participants,
            onScoreSubmitted: () {
              reservationController.fetchUserReservationHistory();
              historyController.fetchNotifications();
            },
          ),
    );
  }

  void _confirmCancelReservation(dynamic reservation) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Reservation'),
            content: Text(
              'Are you sure you want to cancel this reservation?\n\n'
              'Refund: ${_formatCredits(reservation.prixTotal)} will be credited.\n'
              'The reserved hours will become available again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _cancelReservation(reservation);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _cancelReservation(dynamic reservation) async {
    try {
      final String reservationId =
          reservation.id is String ? reservation.id : reservation.id.toString();
      setState(() {
        _cancelInProgress.add(reservationId);
      });
      final resp = await ApiService.instance.put(
        '/reservations/$reservationId',
        data: {'etat': 1}, // 1 = cancelled
      );

      if (resp.statusCode == 200) {
        // Refund full reservation price to user's credit
        await _refundUserForReservation(reservation);

        // Free the time slot
        final String? plageId =
            reservation.plageHoraire?.id?.toString() ??
            reservation.idPlageHoraire?.toString();
        if (plageId != null) {
          await _updatePlageHoraireDisponibilite(plageId, true);
        }

        Get.snackbar(
          'Cancelled',
          'Reservation cancelled. Refund ${_formatCredits(reservation.prixTotal)} credited. Slot is available.',
          backgroundColor: Colors.green.withOpacity(0.2),
        );
        // Synchronize history and availability
        await reservationController.fetchUserReservationHistory();
        await reservationController.fetchAvailableReservations();
      } else {
        Get.snackbar(
          'Error',
          'Failed to cancel reservation (${resp.statusCode})',
          backgroundColor: Colors.red.withOpacity(0.2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Exception',
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.2),
      );
    } finally {
      setState(() {
        _cancelInProgress.remove(
          reservation.id is String ? reservation.id : reservation.id.toString(),
        );
      });
    }
  }

  Future<void> _refundUserForReservation(
    dynamic reservation,
  ) async {
    try {
      final String userId =
          (reservationController.currentUserId.value.isNotEmpty)
              ? reservationController.currentUserId.value
              : (reservation.idUtilisateur is String
                  ? reservation.idUtilisateur
                  : reservation.idUtilisateur?.toString() ?? '');

      if (userId.isEmpty) return;

      final String sportType =
          (reservation.terrain?.type?.toString().toLowerCase() ??
              'reservation');

      final resp = await ApiService.instance.put(
        '/utilisateurs/$userId',
        data: {
          'creditOperation': 'add',
          'creditAmount': reservation.prixTotal,
          'creditType': 'reservation',
          'sport': sportType,
        },
      );

      if (resp.statusCode != 200) {
        debugPrint('Refund credit failed: ${resp.statusCode}');
        Get.snackbar(
          'Refund Warning',
          'Could not credit refund automatically.',
          backgroundColor: Colors.orange.withOpacity(0.2),
        );
      }
    } catch (e) {
      debugPrint('Refund error: $e');
    }
  }

  Future<void> _updatePlageHoraireDisponibilite(
    String idPlageHoraire,
    bool disponible,
  ) async {
    try {
      final resp = await ApiService.instance.put(
        '/plage-horaire/$idPlageHoraire',
        data: {'disponible': disponible},
      );
      if (resp.statusCode != 200) {
        debugPrint('Failed to free timeslot: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error freeing timeslot: $e');
    }
  }

  Widget _buildEligibilityBanner({
    required int thresholdDays,
    required double refundAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Eligible for cancellation (≥$thresholdDays days). Refund: ${_formatCredits(refundAmount)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCancelThresholdDays(dynamic reservation) {
    final type = reservation.terrain?.type?.toString().toLowerCase() ?? '';
    // Example policy: Soccer/football requires ≥4 days, others ≥3 days
    if (type.contains('soccer') ||
        type.contains('football') ||
        type.contains('foot')) {
      return 4;
    }
    return 3;
  }

  String _formatCredits(dynamic amount) {
    try {
      final double value =
          (amount is num) ? amount.toDouble() : double.parse(amount.toString());
      return '${value.toStringAsFixed(2)}';
    } catch (_) {
      return amount?.toString() ?? '0.00';
    }
  }

  void _showScoreValidationDialog(dynamic notification) {
    final String reservationId =
        (notification.reservationId is String)
            ? notification.reservationId
            : notification.reservationId.toString();

    dynamic reservation;
    try {
      reservation = reservationController.reservations.firstWhere(
        (r) => r.id == reservationId,
      );
    } catch (_) {
      reservation = null;
    }

    final participants = reservationController.getParticipantsForReservation(
      reservationId,
    );

    showDialog(
      context: context,
      builder:
          (context) => ScoreEntryDialog(
            reservation: reservation ?? _ReservationStub(reservationId),
            participants: participants,
            initialScoreData: notification.scoreData,
            onScoreSubmitted: () {
              historyController.fetchNotifications();
              reservationController.fetchUserReservationHistory();
            },
          ),
    );
  }

  String _humanizeDuration(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
