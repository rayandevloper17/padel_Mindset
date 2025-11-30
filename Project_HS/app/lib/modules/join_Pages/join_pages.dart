import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ClubeSelct/clube_recomande.dart';
import 'package:app/modules/Header/header_page.dart';
// history pages not used in this file
// import 'package:app/modules/History_Page/history_Page.dart';
import 'package:app/modules/join_Pages/controller.dart';
import 'package:app/modules/match_day/ontroller_reserv_match.dart'
    show ReservationMatchController;
import 'package:app/modules/Padel/controller/controller_participant.dart'
    show Participant;
// reserving screen imports removed (unused here)
import 'package:app/modules/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:app/modules/Padel/widgets/join_confirmation_dialog.dart';

// Import your ReservationMatchController with all the models

class Jpin_Matches extends StatefulWidget {
  const Jpin_Matches({super.key});

  @override
  State<Jpin_Matches> createState() => _Jpin_MatchesState();
}

class _Jpin_MatchesState extends State<Jpin_Matches>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final JoinController controller = Get.put(JoinController());
  final ReservationMatchController reservationController = Get.put(
    ReservationMatchController(),
  );

  final TextEditingController _searchController = TextEditingController();
  // search visibility not used in this page
  final String _selectedSport = 'PADEL'; // Changed to match terrain type
  DateTime? _selectedDate;
  bool _showOnlyAvailable = true; // Default to showing only available matches

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Load available reservations by default
    _refreshReservations();
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

  void _refreshReservations() {
    if (_selectedDate != null) {
      // Fetch available reservations for the selected date
      final dateStr = _formatDateForApi(_selectedDate!);
      reservationController.fetchAvailableReservationsByDate(dateStr);
    } else if (_showOnlyAvailable) {
      // Fetch all available reservations
      reservationController.fetchAvailableReservations();
    } else {
      // Fetch all reservations (fallback)
      reservationController.fetchReservations();
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentColor,
              onPrimary: Colors.white,
              surface: AppTheme.secondaryColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _refreshReservations();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _refreshReservations();
  }

  List<dynamic> _getFilteredReservations() {
    return reservationController.getFilteredReservations(_selectedSport);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
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
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        CreditHeader(ishowing: false),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                        _buildTitle(context),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Rechercher...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      reservationController.searchResults
                                          .clear();
                                      reservationController
                                          .searchNotFound
                                          .value = false;
                                    },
                                  ),
                                  IconButton(
                                    icon: Image.asset(
                                      'assets/images/searchbar.png',
                                    ),
                                    onPressed: () {
                                      // Trigger search only when user explicitly presses the search icon
                                      final q = _searchController.text.trim();
                                      if (q.isNotEmpty) {
                                        reservationController.searchByCode(q);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Only search when user finishes and submits (or presses search icon)
                            onSubmitted: (value) {
                              final q = value.trim();
                              if (q.isNotEmpty) {
                                reservationController.searchByCode(q);
                              }
                            },
                          ),
                        ),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),

                        // Date filtering section
                        _buildDateFilterSection(),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),

                        // Reservations content (list / search results / not-found)
                        Expanded(child: _buildContent(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GetBuilder<JoinController>(
        builder: (controller) {
          return Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.secondaryTextColor, width: 1),
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
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
                      currentIndex: controller.currentIndex,
                      iconPath: AppImages.hisoty_icon,
                      label: 'history',
                      onTap: () => controller.changeTab(0),
                    ),
                    _buildNavItem(
                      index: 1,
                      currentIndex: controller.currentIndex,
                      iconPath: AppImages.search_icons_btn_bar,
                      label: 'search..',
                      onTap: () => controller.changeTab(1),
                    ),
                    _buildNavItem(
                      index: 2,
                      currentIndex: controller.currentIndex,
                      iconPath: AppImages.home_icon,
                      label: 'home',
                      onTap: () => controller.changeTab(2),
                    ),
                    _buildNavItem(
                      index: 3,
                      currentIndex: controller.currentIndex,
                      iconPath: AppImages.settings_icon,
                      label: 'settings',
                      onTap: () => controller.changeTab(3),
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

  Widget _buildTitle(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "REJOINDRE DES MATCHES",
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppTheme.primaryTextColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 22,
          ),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  // ...existing code...

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      // If currently searching by code
      if (reservationController.isSearching.value) {
        return _buildLoadingState();
      }

      // If search returned results, show them
      if (reservationController.searchResults.isNotEmpty) {
        return _buildReservationsList(
          context,
          reservationController.searchResults,
        );
      }

      // If search returned nothing (not found) show empty-with-action
      if (reservationController.searchNotFound.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Aucun match trouvé pour ce code.'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  reservationController.searchNotFound.value = false;
                },
                child: Text('Actualiser'),
              ),
            ],
          ),
        );
      }

      if (reservationController.isLoading.value) {
        return _buildLoadingState();
      }

      final filteredReservations = _getFilteredReservations();
      if (filteredReservations.isEmpty) {
        return _buildEmptyState();
      }

      return _buildReservationsList(context, filteredReservations);
    });
  }

  Widget _buildLoadingState() => Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.sports_soccer, size: 64, color: AppTheme.secondaryTextColor),
        SizedBox(height: 16),
        Text(
          'Aucun match disponible pour $_selectedSport',
          style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16),
        ),
        SizedBox(height: 8),
        TextButton(
          onPressed: _refreshReservations,
          child: Text(
            'Actualiser',
            style: TextStyle(color: AppTheme.accentColor),
          ),
        ),
      ],
    ),
  );

  Widget _buildReservationsList(BuildContext context, List reservations) {
    return RefreshIndicator(
      onRefresh: () async => _refreshReservations(),
      child: ListView.builder(
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          // Subtle per-card animation on build
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 350 + (index % 6) * 30),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 10),
                child: child,
              ),
            ),
            child: _buildReservationCard(context, reservation),
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, reservation) {
    final terrain = reservation.terrain;
    final plageHoraire = reservation.plageHoraire;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.35),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromARGB(200, 8, 8, 8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field name and type
            Row(
              children: [
                Expanded(
                  child: Text(
                    terrain?.name ?? 'Terrain inconnu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    terrain?.type ?? '',
                    style: TextStyle(
                      color: AppTheme.primaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Date & time row
            Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  color: Color(0x80FFFFFF),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  reservation.date,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Icon(Icons.timer, color: Color(0x80FFFFFF), size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(plageHoraire?.startTime)} - ${_formatTime(plageHoraire?.endTime)}',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Price
            Row(
              children: [
                Icon(Icons.attach_money, color: Color(0x80FFFFFF), size: 18),
                Text(
                  '${reservation.prixTotal.toInt()} C',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Player circles (4 slots). Tapping an empty circle joins; tapping your circle leaves.
            SizedBox(height: 12),
            Obx(() {
              final participants = reservationController
                  .getParticipantsForReservation(reservation.id);
              final currentUserId = reservationController.currentUserId.value;

              // Find participant occupying a specific slot index (0..3)
              Participant? _participantForSlot(int slotIdx) {
                for (final pp in participants) {
                  // Prefer numeric slot mapping
                  if (pp.teamIndex != null && pp.teamIndex == slotIdx) {
                    return pp;
                  }
                }
                // Legacy fallback: if only team label exists (A/B), distribute
                for (final pp in participants) {
                  if (pp.teamIndex == null && (pp.team == 'A' || pp.team == 'B')) {
                    if ((pp.team == 'A' && (slotIdx == 0 || slotIdx == 1)) ||
                        (pp.team == 'B' && (slotIdx == 2 || slotIdx == 3))) {
                      return pp;
                    }
                  }
                }
                return null;
              }

              Widget buildCircle(int idx) {
                final p = _participantForSlot(idx);
                if (p != null) {
                  final isMe = p.idUtilisateur.toString() == currentUserId;
                  final displayName =
                      '${p.utilisateur?.nom ?? ''} ${p.utilisateur?.prenom ?? ''}';
                  return GestureDetector(
                    onTap: () async {
                      if (isMe) {
                        final ok = await reservationController.leaveMatch(
                          reservation.id,
                        );
                        if (ok) {
                          Get.snackbar(
                            'Succès',
                            'Vous avez quitté le match',
                            backgroundColor: Colors.orange.withValues(alpha: 0.9),
                            colorText: Colors.white,
                          );
                        }
                      } else {
                        Get.snackbar(
                          'Joueur',
                          displayName.isNotEmpty ? displayName : 'Joueur',
                          backgroundColor: Colors.blueGrey.withValues(alpha: 0.8),
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: isMe ? Colors.green : Colors.white24,
                      child: Text(
                        (p.utilisateur?.nom ?? 'J').substring(0, 1).toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                // Empty slot: allow join at this exact index
                return GestureDetector(
                  onTap: () async {
                    // Check for date+time conflict first
                    final hasConflict = await reservationController.checkDateTimeConflict(
                      date: reservation.date,
                      plageId: reservation.idPlageHoraire,
                    );
                    if (hasConflict) {
                      Get.snackbar(
                        'Erreur',
                        'Vous avez déjà un match prévu à la même date et heure',
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        colorText: Colors.white,
                        duration: Duration(seconds: 3),
                      );
                      return;
                    }

                    // Demander la confirmation avant de rejoindre
                    final confirmed = await showJoinConfirmationDialog(
                      context,
                      title: 'Confirmer la réservation',
                      message:
                          'Voulez-vous confirmer votre participation à ce match ?',
                    );
                    if (!confirmed) return;

                    final teamNum = idx; // exact slot index 0..3
                    final ok = await reservationController.joinMatchWithTeam(
                      reservation.id,
                      teamNum,
                    );
                    if (ok) {
                      Get.snackbar(
                        'Succès',
                        'Vous avez rejoint le match!',
                        backgroundColor: Colors.green.withValues(alpha: 0.9),
                        colorText: Colors.white,
                      );
                    } else {
                      Get.snackbar(
                        'Erreur',
                        'Impossible de rejoindre',
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.add, color: Colors.white70, size: 18),
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) => buildCircle(i)),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDateFilterSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _selectDate,
                      icon: Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 18,
                      ),
                      label: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Sélectionner une date',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedDate != null)
                    IconButton(
                      onPressed: _clearDateFilter,
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white70,
                        size: 18,
                      ),
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          // Available matches toggle
          Container(
            decoration: BoxDecoration(
              color: _showOnlyAvailable 
                  ? AppTheme.accentColor.withValues(alpha: 0.2)
                  : AppTheme.secondaryColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showOnlyAvailable
                    ? AppTheme.accentColor
                    : AppTheme.accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showOnlyAvailable = !_showOnlyAvailable;
                });
                _refreshReservations();
              },
              icon: Icon(
                _showOnlyAvailable ? Icons.people_outline : Icons.people,
                color: _showOnlyAvailable ? AppTheme.accentColor : Colors.white70,
                size: 20,
              ),
              tooltip: _showOnlyAvailable 
                  ? 'Afficher tous les matchs'
                  : 'Afficher uniquement les matchs disponibles',
            ),
          ),
        ],
      ),
    );
  }
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
            // Navigate using named route to avoid importing the screen here
            Get.toNamed('/history');
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
                      ? Colors.grey.withValues(alpha: 0.3)
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
