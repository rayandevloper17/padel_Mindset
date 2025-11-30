import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ClubeSelct/clube_recomande.dart';
import 'package:app/modules/Header/header_page.dart';
import 'package:app/modules/HistoryDetailsView/history_details_view.dart';
import 'package:app/modules/History_Page/controller.dart';
import 'package:app/modules/join_Pages/join_pages.dart';
import 'package:app/modules/match_day/ontroller_reserv_match.dart';
import 'package:app/modules/match_day/score_controller.dart';
import 'package:app/modules/settings/settings_page.dart';
import 'package:app/modules/Padel/controller/controller_participant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum ReservationFilter { all, completed, pending, cancelled }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final bool _isSearchVisible = false;
  final ReservationFilter _currentFilter = ReservationFilter.all;
  final bool _isLoading = false;

  // Use your actual ReservationMatchController
  final ReservationMatchController controller = Get.put(
    ReservationMatchController(),
  );
  final ScoreController scoreController = Get.put(ScoreController());
  // Add HistoryController for score submission
  final HistoryController historyController = Get.put(HistoryController());
  // Store inline score inputs per reservation (3 sets x 2 teams)
  final Map<String, List<String>> _scoreInputsByReservation = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.fetchUserReservationHistory();
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Handle navigation based on index
          switch (index) {
            case 0:
              Get.to(() => HistoryScreen());
              break;
            case 1:
              Get.to(() => Jpin_Matches());
              break;
            case 2:
              Get.to(() => Clube_recomande_Page());
              break;
            case 3:
              Get.to(() => SettingsScreen());
              break;
            default:
              onTap(); // Fallback to provided onTap if index not handled
          }
        },
        child: SizedBox(
          height: 70,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 0.4,
                ),
                color:
                    isSelected
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(iconPath, width: 28, height: 28),
            ),
          ),
        ),
      ),
    );
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
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.home_background),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.width * 0.05,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        CreditHeader(ishowing: false),
                        SizedBox(height: context.height * 0.03),
                        _buildTitle(context, 'History'),
                        SizedBox(height: context.height * 0.02),
                        Expanded(
                          child: Obx(() {
                            if (controller.isLoading.value) {
                              return Center(child: CircularProgressIndicator());
                            }
                            return _buildHistoryList(
                              context,
                              controller.reservations,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GetBuilder<ReservationMatchController>(
        builder: (controller) {
          return Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.secondaryTextColor, width: 1),
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      index: 0,
                      currentIndex: 0,
                      iconPath: AppImages.hisoty_icon,
                      label: 'history',
                      onTap: () {},
                    ),
                    _buildNavItem(
                      index: 1,
                      currentIndex: 0,
                      iconPath: AppImages.search_icons_btn_bar,
                      label: 'search..',
                      onTap: () {},
                    ),
                    _buildNavItem(
                      index: 2,
                      currentIndex: 0,
                      iconPath: AppImages.home_icon,
                      label: 'Clubs',
                      onTap: () {},
                    ),
                    _buildNavItem(
                      index: 3,
                      currentIndex: 0,
                      iconPath: AppImages.settings_icon,
                      label: 'Settings',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, reservations) {
    return ListView.builder(
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        final bool isValid = reservation.etat == "valid";

        // Get participants for this reservation
        final participants = controller.getParticipantsForReservation(
          reservation.id,
        );

        print('Building history item for reservation ${reservation.id}');
        print('Participants found: ${participants.length}');

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromARGB(255, 0, 0, 0).withOpacity(0.08),
                  const Color.fromARGB(255, 0, 0, 0).withOpacity(0.02),
                ],
              ),
              border: Border.all(color: Colors.white12, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reservation.terrain?.name ?? 'Unknown Field',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isValid
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isValid
                                  ? Colors.green
                                  : Colors.orange.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        reservation.id,
                        style: TextStyle(
                          color: isValid ? Colors.green : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      reservation.date,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${reservation.plageHoraire?.startTime.hour ?? 0}:00 - ${reservation.plageHoraire?.endTime.hour ?? 0}:00',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),

                // Participants overview removed in favor of inline left-side player grid
                const SizedBox(height: 8),

                const SizedBox(height: 16),
                // SCORE MANAGEMENT SECTION
                Builder(
                  builder: (context) {
                    // Temporary override to always show score UI for design work.
                    // Set to false to restore original gating once logic is wired.
                    const bool debugShowScoreUI = false;
                    final endTime = reservation.plageHoraire?.endTime;
                    final now = DateTime.now();
                    final isMatchDone = endTime != null && now.isAfter(endTime);
                    final within24h =
                        endTime != null &&
                        now.difference(endTime).inHours <= 24;
                    final hasFourPlayers = participants.length >= 4;
                    final bool isParticipant = participants.any(
                      (p) =>
                          (p.idUtilisateur?.toString() ?? '') ==
                          controller.currentUserId.value,
                    );

                    final bool isScoreOpen =
                        debugShowScoreUI ||
                        (isMatchDone &&
                            within24h &&
                            hasFourPlayers &&
                            isParticipant);

                    // Status badge
                    final statusBadge = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isScoreOpen
                                ? Colors.green.withOpacity(0.25)
                                : Colors.grey.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isScoreOpen ? Colors.greenAccent : Colors.grey,
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        isScoreOpen ? 'Active' : 'Closed',
                        style: TextStyle(
                          color: isScoreOpen ? Colors.greenAccent : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );

                    // Fetch status lazily (only when score entry is open)
                    if (isScoreOpen) {
                      scoreController.fetchStatus(reservation.id.toString());
                    }

                    final status =
                        scoreController.statusByReservation[reservation.id
                            .toString()];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sports_tennis, color: Colors.white70),
                            const SizedBox(width: 8),
                            const Text(
                              'Entrer le score du match',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            statusBadge,
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!isScoreOpen && endTime != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              'This match ended ${_humanizeDuration(now.difference(endTime))} ago - score entry closed',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Builder(
                          builder: (_) {
                            final reservationKey = reservation.id.toString();
                            final inputs = _scoreInputsByReservation
                                .putIfAbsent(
                                  reservationKey,
                                  () => List.filled(6, ''),
                                );
                            final grid = Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 0.8,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: _buildInlinePlayersGrid(
                                      participants,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 120,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    color: Colors.white24,
                                  ),
                                  Expanded(
                                    flex: 6,
                                    child: _buildInlineScoreGrid(
                                      reservation: reservation,
                                      inputs: inputs,
                                      participants: participants,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return isScoreOpen
                                ? grid
                                : Opacity(
                                  opacity: 0.5,
                                  child: IgnorePointer(
                                    ignoring: true,
                                    child: grid,
                                  ),
                                );
                          },
                        ),
                      ],
                    );
                    if (controller.isLoading.value) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (controller.historyErrorMessage.value.isNotEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.historyErrorMessage.value,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              controller.fetchUserReservationHistory();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }
                    if (controller.historyEmpty.value ||
                        controller.reservations.isEmpty) {
                      return const Center(
                        child: Text(
                          'No matches found',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return _buildHistoryList(context, controller.reservations);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reservation.prixTotal.toStringAsFixed(2)} C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          isValid
                              ? () {
                                Get.to(
                                  () => HistoryDetailsScreen(
                                    reservationId: reservation.id,
                                  ),
                                );
                              }
                              : null,
                      style: TextButton.styleFrom(
                        backgroundColor:
                            isValid
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Voir Plus',
                            style: TextStyle(
                              color: isValid ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: isValid ? Colors.white : Colors.grey,
                          ),
                        ],
                      ),
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

  // Build participants display with circle avatars
  Widget _buildParticipantsRow(List<Participant> participants) {
    const int maxVisible = 4; // Maximum avatars to show before "+X more"
    final int totalParticipants = participants.length;
    final int visibleCount =
        totalParticipants > maxVisible ? maxVisible : totalParticipants;
    final int hiddenCount = totalParticipants - maxVisible;

    print('Building participants row for ${participants.length} participants');

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          // Display visible participant avatars
          for (int i = 0; i < visibleCount; i++)
            Padding(
              padding: EdgeInsets.only(left: i * 8.0), // Slight overlap
              child: _buildParticipantAvatar(participants[i], i),
            ),

          // Show "+X more" if there are hidden participants
          if (hiddenCount > 0)
            Padding(
              padding: EdgeInsets.only(left: visibleCount * 8.0),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$hiddenCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Spacer and participant names (if space allows)
          const SizedBox(width: 16),
          Expanded(child: _buildParticipantNames(participants, maxVisible)),
        ],
      ),
    );
  }

  // Inline players grid for match card (2 rows x 2 columns)
  Widget _buildInlinePlayersGrid(List<Participant> participants) {
    final items = participants.take(4).toList();
    while (items.length < 4) {
      items.add(
        Participant(
          id: -1,
          idUtilisateur: -1,
          idReservation: -1,
          estCreateur: false,
          utilisateur: null,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _playerTile(items[0])),
            const SizedBox(width: 12),
            Expanded(child: _playerTile(items[1])),
          ],
        ),
        const SizedBox(height: 12),
        Container(height: 1, color: Colors.white24),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _playerTile(items[2])),
            const SizedBox(width: 12),
            Expanded(child: _playerTile(items[3])),
          ],
        ),
      ],
    );
  }

  Widget _playerTile(Participant participant) {
    // Name
    String name = '';
    if (participant.utilisateur != null) {
      final nom = participant.utilisateur!.nom;
      final prenom = participant.utilisateur!.prenom;
      name = ('$prenom $nom').trim();
    } else {
      name =
          participant.idUtilisateur > 0
              ? 'User ${participant.idUtilisateur}'
              : '';
    }

    final initials = _getInitials(name.isEmpty ? '-' : name);
    final rating =
        participant.idUtilisateur > 0
            ? controller.getAverageRatingForUser(
              participant.idUtilisateur.toString(),
            )
            : 0.0;
    final ratingText = _formatRating(rating);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 1),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name.isEmpty ? '—' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.yellowAccent.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            ratingText,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineScoreGrid({
    required dynamic reservation,
    required List<String> inputs,
    required List<Participant> participants,
  }) {
    final dateText = reservation.date;
    final startHour = reservation.plageHoraire?.startTime.hour ?? 0;
    final endHour = reservation.plageHoraire?.endTime.hour ?? 0;

    bool hasResult = inputs.any((v) => v.trim().isNotEmpty);

    Widget scoreBox(int index) {
      return SizedBox(
        width: 34,
        height: 30,
        child: TextFormField(
          initialValue: inputs[index],
          onChanged: (val) {
            setState(() {
              inputs[index] = val.replaceAll(RegExp(r'[^0-9]'), '');
            });
          },
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.white70),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 2,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
            Text(
              dateText,
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
            const Icon(Icons.access_time, color: Colors.white70, size: 16),
            Text(
              '$startHour:00 - $endHour:00',
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Top row: Team A scores (Set1A, Set2A, Set3A)
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            scoreBox(0),
            const SizedBox(width: 18),
            scoreBox(2),
            const SizedBox(width: 18),
            scoreBox(4),
          ],
        ),
        const SizedBox(height: 10),
        // Middle button/banner: 'Sans résultat' opens dialog
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return _ScoreEntryDialog(
                  reservationId: reservation.id.toString(),
                  controller: historyController,
                  participants: participants,
                );
              },
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Update score',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Bottom row: Team B scores (Set1B, Set2B, Set3B)
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            scoreBox(1),
            const SizedBox(width: 18),
            scoreBox(3),
            const SizedBox(width: 18),
            scoreBox(5),
          ],
        ),
      ],
    );
  }

  String _formatRating(double value) {
    return value == 0.0 ? '—' : value.toStringAsFixed(2).replaceAll('.', ',');
  }

  // Build individual participant avatar with rating functionality
  Widget _buildParticipantAvatar(Participant participant, int index) {
    // Generate a color based on the participant's name or ID for consistency
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final color = colors[participant.hashCode % colors.length];

    // Get participant name from the Utilisateur model
    String participantName = '';
    if (participant.utilisateur != null) {
      // Combine nom and prenom for full name
      final nom = participant.utilisateur!.nom;
      final prenom = participant.utilisateur!.prenom;
      participantName = '$prenom $nom'.trim();
    }

    // Fallback to ID if no name available
    if (participantName.isEmpty) {
      participantName = 'User ${participant.idUtilisateur}';
    }

    // Get initials from participant name
    String initials = _getInitials(participantName);

    print(
      'Building avatar for participant: $participantName (ID: ${participant.idUtilisateur})',
    );
    print('   - Nom: ${participant.utilisateur?.nom ?? "N/A"}');
    print('   - Prenom: ${participant.utilisateur?.prenom ?? "N/A"}');
    print('   - Est Createur: ${participant.estCreateur}');

    return GestureDetector(
      onTap: () => _showRatingDialog(participant, participantName),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: participant.estCreateur ? Colors.yellow : Colors.white,
            width:
                participant.estCreateur ? 3 : 2, // Thicker border for creator
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main avatar
            Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Crown icon for creator
            if (participant.estCreateur)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(Icons.star, size: 10, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build participant names text
  Widget _buildParticipantNames(
    List<Participant> participants,
    int maxVisible,
  ) {
    if (participants.isEmpty) return const SizedBox();

    final visibleParticipants = participants.take(maxVisible).toList();
    final names = visibleParticipants
        .map((participant) {
          if (participant.utilisateur != null) {
            final nom = participant.utilisateur!.nom;
            final prenom = participant.utilisateur!.prenom;
            final fullName = '$prenom $nom'.trim();
            return fullName.isNotEmpty
                ? fullName
                : 'User ${participant.idUtilisateur}';
          }
          return 'User ${participant.idUtilisateur}';
        })
        .join(', ');

    final displayText = participants.length > maxVisible ? '$names...' : names;

    print('Displaying participant names: $displayText');

    return Text(
      displayText,
      style: const TextStyle(color: Colors.white70, fontSize: 12),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0][0].toUpperCase();
    }
  }

  // Show rating dialog when participant is clicked
  void _showRatingDialog(Participant participant, String participantName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _RatingDialog(
          participant: participant,
          participantName: participantName,
          controller: controller,
        );
      },
    );
  }
}

// Modern score entry dialog with button-based selection
class _ScoreEntryDialog extends StatefulWidget {
  final String reservationId;
  final HistoryController controller;
  final List<Participant> participants;

  const _ScoreEntryDialog({
    Key? key,
    required this.reservationId,
    required this.controller,
    required this.participants,
  }) : super(key: key);

  @override
  State<_ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends State<_ScoreEntryDialog> {
  final TextEditingController set1TeamA = TextEditingController();
  final TextEditingController set1TeamB = TextEditingController();
  final TextEditingController set2TeamA = TextEditingController();
  final TextEditingController set2TeamB = TextEditingController();
  final TextEditingController set3TeamA = TextEditingController();
  final TextEditingController set3TeamB = TextEditingController();

  bool submitting = false;
  bool superTieBreak = false;
  int? selectedWinner; // 1 -> Team A, 2 -> Team B

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

  Future<void> _handleSubmit() async {
    setState(() => submitting = true);
    final set1A = int.tryParse(set1TeamA.text);
    final set1B = int.tryParse(set1TeamB.text);
    final set2A = int.tryParse(set2TeamA.text);
    final set2B = int.tryParse(set2TeamB.text);
    final set3A = int.tryParse(set3TeamA.text);
    final set3B = int.tryParse(set3TeamB.text);

    final items = widget.participants.take(4).toList();
    while (items.length < 4) {
      items.add(
        Participant(
          id: -1,
          idUtilisateur: -1,
          idReservation: -1,
          estCreateur: false,
          utilisateur: null,
        ),
      );
    }

    String p1A = items[0].idUtilisateur > 0 ? '${items[0].idUtilisateur}' : '';
    String p2A = items[1].idUtilisateur > 0 ? '${items[1].idUtilisateur}' : '';
    String p1B = items[2].idUtilisateur > 0 ? '${items[2].idUtilisateur}' : '';
    String p2B = items[3].idUtilisateur > 0 ? '${items[3].idUtilisateur}' : '';

    final ok = await widget.controller.submitDirectScore(
      reservationId: widget.reservationId,
      set1A: set1A,
      set1B: set1B,
      set2A: set2A,
      set2B: set2B,
      set3A: set3A,
      set3B: set3B,
      superTieBreak: superTieBreak,
      teamWin: selectedWinner,
      p1A: p1A,
      p2A: p2A,
      p1B: p1B,
      p2B: p2B,
    );

    setState(() => submitting = false);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Score envoyé'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de l\'envoi du score'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _scoreDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white10,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFF6C63FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.sports_tennis, color: Colors.white70),
          SizedBox(width: 8),
          Text(
            'Entrer le résultat du match',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.groups, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Équipe A vs Équipe B',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  _setRow('Set 1', set1TeamA, set1TeamB),
                  const SizedBox(height: 12),
                  _setRow('Set 2', set2TeamA, set2TeamB),
                  const SizedBox(height: 12),
                  _setRow('Set 3 (si nécessaire)', set3TeamA, set3TeamB),

                  const SizedBox(height: 16),
                  // Super tie-break toggle
                  Row(
                    children: [
                      Checkbox(
                        value: superTieBreak,
                        onChanged:
                            (v) => setState(() => superTieBreak = v ?? false),
                        activeColor: const Color(0xFF6C63FF),
                      ),
                      const Text(
                        'Super tie-break',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  // Winner selection chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        selected: selectedWinner == 1,
                        onSelected: (_) => setState(() => selectedWinner = 1),
                        label: Row(
                          children: const [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Équipe A',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        selectedColor: const Color(0xFF6C63FF),
                        backgroundColor: Colors.white12,
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        selected: selectedWinner == 2,
                        onSelected: (_) => setState(() => selectedWinner = 2),
                        label: Row(
                          children: const [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Équipe B',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        selectedColor: const Color(0xFF6C63FF),
                        backgroundColor: Colors.white12,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: submitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      backgroundColor: const Color(0xFF6C63FF),
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
                            : const Text(
                              'Envoyer le score',
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: const [],
    );
  }

  Widget _setRow(
    String label,
    TextEditingController a,
    TextEditingController b,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: a,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            decoration: _scoreDecoration('A'),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: b,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            decoration: _scoreDecoration('B'),
          ),
        ),
      ],
    );
  }
}

// Rating Dialog Widget
class _RatingDialog extends StatefulWidget {
  final Participant participant;
  final String participantName;
  final ReservationMatchController controller;

  const _RatingDialog({
    required this.participant,
    required this.participantName,
    required this.controller,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog>
    with TickerProviderStateMixin {
  int selectedRating = 0;
  bool isSubmitting = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.grey[900]!.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with participant info
                  Row(
                    children: [
                      _buildParticipantAvatarForDialog(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rate Player',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.participantName,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.participant.estCreateur)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.yellow,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.yellow,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Creator',
                                      style: TextStyle(
                                        color: Colors.yellow,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Rating section
                  Text(
                    'How was this player?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRating = starIndex;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            selectedRating >= starIndex
                                ? Icons.star
                                : Icons.star_border,
                            color:
                                selectedRating >= starIndex
                                    ? Colors.amber
                                    : Colors.white38,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Rating labels
                  if (selectedRating > 0)
                    Text(
                      _getRatingLabel(selectedRating),
                      style: TextStyle(
                        color: _getRatingColor(selectedRating),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              selectedRating > 0 && !isSubmitting
                                  ? _submitRating
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                selectedRating > 0 ? Colors.blue : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              isSubmitting
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    'Submit Rating',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticipantAvatarForDialog() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final color = colors[widget.participant.hashCode % colors.length];

    String participantName = '';
    if (widget.participant.utilisateur != null) {
      final nom = widget.participant.utilisateur!.nom;
      final prenom = widget.participant.utilisateur!.prenom;
      participantName = '$prenom $nom'.trim();
    }

    if (participantName.isEmpty) {
      participantName = 'User ${widget.participant.idUtilisateur}';
    }

    String initials =
        participantName.isNotEmpty
            ? (participantName.split(' ').length >= 2
                ? '${participantName.split(' ')[0][0]}${participantName.split(' ')[1][0]}'
                    .toUpperCase()
                : participantName
                    .substring(0, participantName.length >= 2 ? 2 : 1)
                    .toUpperCase())
            : 'U';

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.participant.estCreateur ? Colors.yellow : Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  Future<void> _submitRating() async {
    if (selectedRating == 0) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      // Get current user ID (you might need to adjust this based on your auth system)
      final token = await FlutterSecureStorage().read(key: 'token');
      // You might need to decode the token to get current user ID
      // For now, using a placeholder - adjust based on your auth implementation
      final currentUserId = '1'; // Replace with actual current user ID

      print(
        '🌟 Submitting rating for user ${widget.participant.idUtilisateur}',
      );
      print('   Rating: $selectedRating stars');
      print('   Reservation: ${widget.participant.idReservation}');

      final success = await widget.controller.createUserRating(
        idNoteur: currentUserId,
        idReservation: widget.participant.idReservation.toString(),
        note: selectedRating,
      );

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred while submitting rating.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }
}

String _humanizeDuration(Duration d) {
  if (d.inDays >= 1) {
    return '${d.inDays} day${d.inDays == 1 ? '' : 's'}';
  }
  if (d.inHours >= 1) {
    return '${d.inHours} hour${d.inHours == 1 ? '' : 's'}';
  }
  return '${d.inMinutes} minute${d.inMinutes == 1 ? '' : 's'}';
}
