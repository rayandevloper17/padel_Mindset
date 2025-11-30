import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/Header/header_page.dart';
import 'package:app/modules/Padel/controller/controller_participant.dart'
    show MatchController, Participant;
import 'package:app/modules/Padel/controller_user_padel.dart';
import 'package:app/modules/match_day/ontroller_reserv_match.dart'
    show ReservationMatchController, Reservation, Terrain, PlageHoraire;
import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:app/modules/Padel/widgets/join_confirmation_dialog.dart';

/// Page: Private matches (typer == 1) — join with Crédit or Sur place
class MatchPrvPage extends StatefulWidget {
  const MatchPrvPage({super.key});

  @override
  State<MatchPrvPage> createState() => _MatchPrvPageState();
}

class _MatchPrvPageState extends State<MatchPrvPage> {
  final ReservationMatchController reservationController = Get.put(
    ReservationMatchController(),
  );
  final MatchController matchController = Get.put(MatchController());
  final UserPadelController userPadelController = UserPadelController();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final TextEditingController _codeController = TextEditingController();
  final ApiService _apiService = Get.find<ApiService>();

  // Per-reservation payment selection: 1 => Crédit, 2 => Sur place
  final RxMap<String, int> _selectedPayment = <String, int>{}.obs;

  @override
  void initState() {
    super.initState();
    // Load available reservations and participants
    reservationController.fetchAvailableReservations();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(backgroundColor: Colors.black, elevation: 0),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D0D), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreditHeader(ishowing: true),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  'MATCHS PRIVÉS • PADEL',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primaryTextColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 12),
                // Search by reservation code (coder)
                _buildSearchBar(context),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    // Loading states: when fetching list OR searching by code
                    if (reservationController.isLoading.value ||
                        reservationController.isSearching.value) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accentColor,
                          ),
                        ),
                      );
                    }
                    // If a search was performed, show results (filtered to private matches)
                    if (reservationController.searchResults.isNotEmpty ||
                        reservationController.searchNotFound.value) {
                      if (reservationController.searchNotFound.value) {
                        return _buildNotFoundState();
                      }
                      final List<Reservation> results =
                          reservationController.searchResults
                              .where((r) => (r.typer ?? 0) == 1)
                              .toList();
                      if (results.isEmpty) {
                        return _buildNonPrivateMatchFoundState();
                      }
                      return RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final r = results[index];
                            _selectedPayment.putIfAbsent(r.id, () => 2);
                            return _buildPrivateCard(context, r);
                          },
                        ),
                      );
                    }

                    // Default list: available private padel matches
                    final List<Reservation> base = reservationController
                        .getFilteredReservations('PADEL');
                    final List<Reservation> privateOnly =
                        base.where((r) => (r.typer ?? 0) == 1).toList();

                    if (privateOnly.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshAll,
                      child: ListView.builder(
                        itemCount: privateOnly.length,
                        itemBuilder: (context, index) {
                          final r = privateOnly[index];
                          // default payment: Sur place (2)
                          _selectedPayment.putIfAbsent(r.id, () => 2);
                          return _buildPrivateCard(context, r);
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_tennis,
            size: 64,
            color: const Color(0xFFFFE600).withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucun match privé disponible',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFE600).withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE600).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.qr_code,
            color: const Color(0xFFFFE600).withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _codeController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Entrer le code de réservation (coder)',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onSubmitted: (val) {
                final q = val.trim();
                if (q.isNotEmpty) {
                  print('🔎 [UI] Searching PRIVATE match by code: ' + q);
                  reservationController.searchByCode(q, expectedTyper: 1);
                }
              },
            ),
          ),
          IconButton(
            tooltip: 'Rechercher',
            onPressed: () {
              final q = _codeController.text.trim();
              if (q.isNotEmpty) {
                print('🔎 [UI] Searching PRIVATE match by code: ' + q);
                reservationController.searchByCode(q, expectedTyper: 1);
              }
            },
            icon: const Icon(Icons.search, color: Colors.white70, size: 20),
          ),
          IconButton(
            tooltip: 'Effacer',
            onPressed: _clearSearch,
            icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    reservationController.searchResults.clear();
    reservationController.searchNotFound.value = false;
    reservationController.isSearching.value = false;
    _codeController.clear();
  }

  Future<void> _refreshAll() async {
    final q = _codeController.text.trim();
    if (q.isNotEmpty) {
      print('🔄 [UI] Refresh: searching PRIVATE match by code: ' + q);
      await reservationController.searchByCode(q, expectedTyper: 1);
    } else {
      await reservationController.fetchAvailableReservations();
    }
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search_off, size: 60, color: Colors.white54),
          SizedBox(height: 12),
          Text(
            'Aucun match trouvé pour ce code',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNonPrivateMatchFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_open, size: 60, color: Colors.white54),
          SizedBox(height: 12),
          Text(
            'Ce code correspond à un match non privé',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateCard(BuildContext context, Reservation r) {
    final Terrain? terrain = r.terrain;
    final PlageHoraire? plage = r.plageHoraire;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E0E0E), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE600).withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFE600).withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: terrain + type + reservation code
            Row(
              children: [
                Expanded(
                  child: Text(
                    terrain?.name ?? 'Terrain',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE600).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFE600),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'Code: ${r.coder ?? '—'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      color: const Color(0xFFFFE600).withOpacity(0.6),
                      width: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    terrain?.type ?? 'PADEL',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.date_range, color: Colors.white54, size: 18),
                const SizedBox(width: 4),
                Text(
                  r.date,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer, color: Colors.white54, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_fmtTime(plage?.startTime)} - ${_fmtTime(plage?.endTime)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.white60, size: 18),
                Text(
                  '${r.prixTotal.toInt()} C',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Payment selector
            Obx(() {
              final pay = _selectedPayment[r.id] ?? 2;
              return Row(
                children: [
                  _paymentOption(
                    label: 'Crédit',
                    icon: Icons.credit_card,
                    selected: pay == 1,
                    onTap: () => _selectedPayment[r.id] = 1,
                  ),
                  const SizedBox(width: 12),
                  _paymentOption(
                    label: 'Sur place',
                    icon: Icons.storefront,
                    selected: pay == 2,
                    onTap: () => _selectedPayment[r.id] = 2,
                  ),
                ],
              );
            }),

            const SizedBox(height: 16),

            // Player slots row (4 slots) with participant photo, name, and rating
            Obx(() {
              final participants = reservationController
                  .getParticipantsForReservation(r.id);
              Participant? slot(int idx) {
                for (final p in participants) {
                  if (p.teamIndex != null && p.teamIndex == idx) return p;
                }
                for (final p in participants) {
                  if (p.teamIndex == null && (p.team == 'A' || p.team == 'B')) {
                    if ((p.team == 'A' && (idx == 0 || idx == 1)) ||
                        (p.team == 'B' && (idx == 2 || idx == 3)))
                      return p;
                  }
                }
                return null;
              }

              List<Widget> circles = List.generate(4, (i) {
                final p = slot(i);
                if (p != null) {
                  return _occupiedSlot(p);
                }
                return _emptySlot(() => _handleJoin(r, i));
              });

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: circles,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? const Color(0xFFFFE600).withOpacity(0.2)
                  : Colors.black,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFE600) : Colors.white24,
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFFFFE600) : Colors.white60,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _occupiedSlot(Participant p) {
    final String name =
        ((p.utilisateur?.nom ?? '').trim() +
                ' ' +
                (p.utilisateur?.prenom ?? '').trim())
            .trim();
    final double? note = p.utilisateur?.note;
    final String noteText = note == null ? '-' : note.toStringAsFixed(1);
    final String? rawImg = p.utilisateur?.imageUrl;
    final String resolvedUrl = _resolveImageUrl(rawImg);
    final bool hasImage = resolvedUrl.isNotEmpty;

    return SizedBox(
      width: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE600).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child:
                      hasImage
                          ? Image.network(
                            resolvedUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white70,
                                size: 22,
                              );
                            },
                          )
                          : const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 22,
                          ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFE600),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFE600),
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        noteText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Tooltip(
            message: name.isNotEmpty ? name : 'Joueur',
            child: Text(
              name.isNotEmpty ? name : 'Joueur',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // Compose a full absolute URL for backend-hosted image paths.
  String _resolveImageUrl(String? raw) {
    if (raw == null) return '';
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final base = _apiService.baseUrl;
    final host =
        base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
    if (s.startsWith('/')) return '$host$s';
    return '$host/$s';
  }

  Widget _emptySlot(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white12,
              child: const Icon(Icons.add, color: Colors.white70, size: 20),
            ),
            const SizedBox(height: 6),
            const Text(
              'Libre',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime? d) {
    if (d == null) return '--:--';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleJoin(Reservation r, int slotIndex) async {
    // First, check same-day conflict (based on plageHoraire start date)
    try {
      final DateTime dateSource =
          r.plageHoraire?.startTime ??
          (DateTime.tryParse(r.date) ?? DateTime.now());
      final String dateOnly =
          '${dateSource.year.toString().padLeft(4, '0')}-${dateSource.month.toString().padLeft(2, '0')}-${dateSource.day.toString().padLeft(2, '0')}';

      final hasDateConflict = await reservationController.checkDateConflict(
        dateOnly,
      );
      if (hasDateConflict) {
        Get.snackbar(
          'Conflit',
          'Vous avez déjà un match à cette date',
          backgroundColor: Colors.red.withOpacity(0.85),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    } catch (_) {
      // Ignore network errors and let backend validate later
    }

    // Check date+time conflict using reservationController
    final hasConflict = await reservationController.checkDateTimeConflict(
      date: r.date,
      plageId: r.idPlageHoraire,
    );

    if (hasConflict) {
      Get.snackbar(
        'Conflit',
        'Vous avez déjà un match à la même date et heure',
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Confirmer l'intention de rejoindre avant de poursuivre
    final confirmed = await showJoinConfirmationDialog(
      context,
      title: 'Confirmer la réservation',
      message: 'Voulez-vous confirmer votre participation à ce match ?',
    );
    if (!confirmed) return;
    final payType = _selectedPayment[r.id] ?? 2; // 1 Crédit, 2 Sur place
    final String? uid = await storage.read(key: 'userId');
    if (uid == null) {
      Get.snackbar(
        'Erreur',
        'Utilisateur non authentifié',
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
      );
      return;
    }

    final int? idReservation = int.tryParse(r.id);
    final int? idUser = int.tryParse(uid);
    if (idReservation == null || idUser == null) {
      Get.snackbar(
        'Erreur',
        'Identifiants invalides',
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Refresh participants and validate slot availability just before join
      await reservationController.fetchParticipantsForReservation(r.id);
      final currentParticipants = reservationController
          .getParticipantsForReservation(r.id);
      bool slotOccupied = false;
      for (final p in currentParticipants) {
        if (p.teamIndex != null && p.teamIndex == slotIndex) {
          slotOccupied = true;
          break;
        }
        if (p.teamIndex == null && (p.team == 'A' || p.team == 'B')) {
          if ((p.team == 'A' && (slotIndex == 0 || slotIndex == 1)) ||
              (p.team == 'B' && (slotIndex == 2 || slotIndex == 3))) {
            slotOccupied = true;
            break;
          }
        }
      }
      if (slotOccupied) {
        Get.snackbar(
          'Indisponible',
          'La position sélectionnée est déjà occupée',
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      bool proceed = true;
      int statePaiement = 0; // 0: unpaid (Sur place), 1: paid (Crédit)

      if (payType == 1) {
        // Crédit: deduct before joining
        statePaiement = 1;
        // Pre-check balance to provide clearer error before attempting deduction
        try {
          final balance = await userPadelController.getCreditBalance(
            userId: uid,
          );
          final price =
              r.prixTotal is num
                  ? (r.prixTotal as num).toDouble()
                  : double.tryParse(r.prixTotal.toString()) ?? 0.0;
          if (balance < price) {
            proceed = false;
            Get.snackbar(
              'Solde insuffisant',
              'Votre solde (${balance.toStringAsFixed(2)} C) est inférieur au prix (${price.toStringAsFixed(2)} C).',
              backgroundColor: Colors.red.withOpacity(0.85),
              colorText: Colors.white,
            );
          }
        } catch (_) {
          // If balance fetch fails, fall back to deductCredit which will error explicitly
        }

        if (!proceed) return;
        try {
          final resp = await userPadelController.deductCredit(
            userId: uid,
            creditAmount: r.prixTotal.toString(),
          );
          if (resp['success'] != true) {
            proceed = false;
            Get.snackbar(
              'Crédit',
              'Déduction échouée',
              backgroundColor: Colors.red.withOpacity(0.85),
              colorText: Colors.white,
            );
          }
        } catch (e) {
          proceed = false;
          Get.snackbar(
            'Solde insuffisant',
            e.toString(),
            backgroundColor: Colors.red.withOpacity(0.85),
            colorText: Colors.white,
          );
        }
      } else {
        statePaiement = 0; // Sur place
      }

      if (!proceed) return;

      final ok = await matchController.joinMatchWithTeamIndex(
        idReservation,
        idUser,
        teamIndex: slotIndex,
        typepaiement: payType,
        statepaiement: statePaiement,
      );

      if (ok) {
        // Refresh participants via reservationController for UI consistency
        await reservationController.fetchParticipantsForReservation(r.id);
        Get.snackbar(
          'Succès',
          'Match rejoint • Position ${slotIndex + 1}',
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de rejoindre',
          backgroundColor: Colors.red.withOpacity(0.85),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
  }
}
