// ✅ Cleaned and corrected version of your code:
// Note: Removed 'dart:ffi' import for web compatibility.

import 'package:app/controllers/plage_hourai_controller.dart';
import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ClubeSelct/clube_recomande.dart';
import 'package:app/modules/EnhancedHistoryScreen.dart';
import 'package:app/modules/Header/header_page.dart';
import 'package:app/modules/History_Page/history_Page.dart';
import 'package:app/modules/Padel/controller.dart';
import 'package:app/modules/Padel/controller_user_padel.dart';
import 'package:app/modules/Padel/info_clube.dart';
import 'package:app/modules/Padel/participant_page.dart';
import 'package:app/modules/ProfileView/controller_profile_page.dart';
import 'package:app/modules/SoocerScreen/constatns/datepiker_cont.dart';
import 'package:app/modules/SoocerScreen/controller.dart';
import 'package:app/modules/SoocerScreen/terrain_model.dart';
import 'package:app/modules/join_Pages/join_pages.dart'
    hide ReservationController;
import 'package:app/modules/reserveing/reservation_controller.dart';
import 'package:app/modules/reserving_screen/reserving_screen.dart';
import 'package:app/modules/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:app/modules/SoocerScreen/terrain_controller.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:app/services/api_service.dart';

class PadelScreen extends StatefulWidget {
  const PadelScreen({super.key});

  @override
  State<PadelScreen> createState() => _SoocerScreenState();
}

class _SoocerScreenState extends State<PadelScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;

  final TerrainController controllerTerrain = Get.put(TerrainController());
  final Scoorcontroller controller = Get.put(Scoorcontroller());
  final reservationController = Get.put(ReservationController());
  final UserPadelController controllerUser = Get.put(UserPadelController());
  final ProfileController profileController = Get.put(ProfileController());

  final PlageHoraireController controllerhourau = Get.put(
    PlageHoraireController(),
  );

  String? _selectedTime;
  List<String> timeSlots = [];
  int _currentImageIndex = 0;
  int userId = 0; // Store user ID from token
  int idofterain = 0; // Store the selected terrain ID
  int plageHoraireId = 0; // Store the selected terrain ID
  // String dateEnddateStart = '';
  int typer = 1;

  double prixTotal = 0;
  int selectedTerrainIndex = -1; // -1 = nothing selected yet
  String dateEnddateStart = DateTime.now().toString();

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String _formatTimeSlot(PlageHoraire plage) {
    final startHour = plage.startTime.hour.toString().padLeft(2, '0');
    final startMinute = plage.startTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute';
  }

  PlageHoraire? get selectedPlageHoraire {
    if (_selectedTime == null) return null;

    return controllerhourau.plageHoraires.firstWhereOrNull(
      (plage) => _formatTimeSlot(plage) == _selectedTime,
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _pageController = PageController();

    // Fetch terrain data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📡 Post frame callback - fetching terrain data');
      controllerTerrain.fetchAllTerrains();
    });
    if (dateEnddateStart.isEmpty) {
      dateEnddateStart = DateTime.now().toString();
    }

    // Load initial plage horaires without using refresh() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controllerhourau.plageHoraires.value =
          controllerhourau.plageHoraires.value;
    });
    // Start animations
    _animationController.forward();
    print('✅ Animations started');

    // Handle plageHoraires changes without setState during build
    ever(controllerhourau.plageHoraires, (List<PlageHoraire> plages) {
      print('👂 PlageHoraires changed - count: ${plages.length}');

      timeSlots = plages.map((p) => _formatTimeSlot(p)).toList();

      // Only update _selectedTime if needed, outside of build
      if (plages.isNotEmpty && _selectedTime == null) {
        print('🎯 Setting default selected time');
        _selectedTime = timeSlots.first;
        print('✅ Selected time set to: $_selectedTime');
      }
    });

    // Also listen to loading state
    Future.delayed(Duration.zero, () async {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return controllerhourau.isLoading.value;
      });
      for (var item in controllerhourau.plageHoraires) {
        print(
          "⏱️ Horaire reçu: ${item.startTime} -> ${item.endTime} - ${item.price} C",
        );
      }
    });

    void fetchPrice() {
      if (dateEnddateStart.isNotEmpty && plageHoraireId > 0) {
        controllerTerrain
            .fetchPriceByPlageHoraireId(plageHoraireId)
            .then((price) {
              setState(() {
                prixTotal = price ?? 0.0; // Handle null safely
              });
            })
            .catchError((error) {
              print('Error fetching price: $error');
              setState(() {
                prixTotal = 0.0;
              });
            });
      }
    }

    // Get user ID from secure storage and fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Get a valid access token via ApiService
      final token = await ApiService.instance.getValidAccessToken();
      if (token != null && token.isNotEmpty) {
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        print('🧩 Decoded Token: $decodedToken');

        // Store user ID in class variable
        setState(() {
          userId = int.parse(decodedToken['id'].toString());
        });
        print('👤 User ID from token: $userId');
      }

      print('📡 Post frame callback - fetching terrain data with auth token');
    });

    print('🏁 InitState finished');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    int currentTerrainId = 0;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(screenSize.height * 0.18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: screenSize.height * 0.04),
                      CreditHeader(ishowing: true),
                      _buildHeader(context),
                      SizedBox(height: screenSize.height * 0.02),
                      SizedBox(
                        width: screenSize.width,

                        child: TabBar(
                          indicatorColor: Colors.white,
                          indicatorWeight: screenSize.width * 0.0010,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white60,
                          labelStyle: TextStyle(
                            fontSize: screenSize.width * 0.026,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: const [
                            Tab(text: 'CLUB'),

                            Tab(text: 'RESERVATIONS'),
                            Tab(text: 'MATCHES OUVERTS'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        body: TabBarView(
          children: [
            // Padel Tab Content

            // Club Info Tab Content
            ClubInfoPage(),

            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppImages.home_background),
                  fit: BoxFit.cover,
                ),
              ),
              child: Obx(() {
                if (controllerTerrain.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final terrains = controllerTerrain.terrains;

                if (terrains.isEmpty) {
                  return Center(
                    child: Text(
                      "Aucun terrain trouvé",
                      style: TextStyle(
                        fontSize: screenSize.width * 0.045,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                return SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.overlayColor,
                                AppTheme.primaryColor.withOpacity(0.7),
                                AppTheme.primaryColor.withOpacity(0.9),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(height: screenSize.height * 0.01),
                          _buildTitleSection(context),
                          SizedBox(height: screenSize.height * 0.010),
                          Expanded(
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: _buildTerrainPageView(terrains),
                              ),
                            ),
                          ),
                          _buildBottomSection(),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
            // Reservations Tab Content
            MatchScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildTerrainPageView(List<Terrain> terrains) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PageView.builder(
          controller: _pageController,
          itemCount: terrains.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
              idofterain = terrains[index].id;
              selectedTerrainIndex = index;
            });
            // Rafraîchir automatiquement les créneaux en fonction de la date sélectionnée
            final parsedDate = DateTime.tryParse(dateEnddateStart);
            controllerhourau.getPlageHorairesForTerrain(
              terrains[index].id,
              selectedDate: parsedDate ?? DateTime.now(),
            );
          },
          itemBuilder: (context, index) {
            final terrain = terrains[index];
            final isSelected = index == selectedTerrainIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedTerrainIndex = index;
                  idofterain = terrain.id;
                });
                // Refresh available slots for the selected terrain, using current selected date if available
                final parsedDate = DateTime.tryParse(dateEnddateStart);
                controllerhourau.getPlageHorairesForTerrain(
                  terrain.id,
                  selectedDate: parsedDate ?? DateTime.now(),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isSelected ? 6 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Color(0xFFd1e301) : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? Color(0xFFd1e301) : Colors.black)
                          .withOpacity(isSelected ? 0.35 : 0.20),
                      blurRadius: isSelected ? 18 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.02 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Full-width, full-height image with graceful loading
                        buildTerrainImage(
                          terrain,
                          height: constraints.maxHeight,
                          width: constraints.maxWidth,
                        ),

                        // Stylish gradient overlay for legibility
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: isSelected ? 0.18 : 0.35,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.20),
                                    Colors.black.withOpacity(0.45),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom label with terrain name and type
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.sports_tennis,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${terrain.name} \u2022 ${terrain.type}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Animated check badge for selection
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child:
                                    isSelected
                                        ? Container(
                                          key: const ValueKey('selected-badge'),
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Colors.black,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0x55FFD700),
                                                blurRadius: 12,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Color(0xFFd1e301),
                                            size: 18,
                                          ),
                                        )
                                        : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeSelectorResponsive(),

          _buildReserveButton(
            userId: userId,
            terrainId: idofterain,
            plageHoraireId: plageHoraireId,
            date: dateEnddateStart,
            prixTotal: prixTotal,
            onSuccess: () {
              print("Reservation created!");
            },
          ),
        ],
      ),
    );
  }

  // === Reusable Widgets ===

  Widget _navArrow(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.5),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: Colors.white, size: 24),
  );

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: context.height * 0.01),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Informations sur le club",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryTextColor,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.width * 0.02),
          child: GestureDetector(
            onTap: () => Get.back(),
            child: const Row(
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  color: Color.fromARGB(255, 255, 255, 255),
                  size: 18,
                ),
                SizedBox(width: 4),
                Text("Retourner", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel(List<String> images, String label) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.24,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.isNotEmpty ? images.length : 1,
            itemBuilder: (context, index) {
              return Container(
                height: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    children: [
                      images.isNotEmpty
                          ? _buildImageWithErrorHandling(
                            images[index],
                            280,
                            double.infinity,
                          )
                          : _buildPlaceholder(280, double.infinity, label),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Navigation arrows - Show only when there are multiple images
          if (images.length > 1) ...[
            // Left arrow - Show only if not on first image
            if (_currentImageIndex > 0)
              Positioned(
                left: 5,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_pageController.hasClients) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            // Right arrow - Show only if not on last image
            if (_currentImageIndex < images.length - 1)
              Positioned(
                right: 5,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_pageController.hasClients) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          // Page indicator dots (optional)
          if (images.length > 1)
            Positioned(
              bottom: 10,
              right: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTerrainDetails(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeSelectorResponsive() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Réservation terrain central',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DatePickerContainer(
            initialDate: DateTime.now(), // Optional - will default to today
            onDateSelected: (DateTime selectedDate) {
              // Use addPostFrameCallback to avoid setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  // Update date
                  dateEnddateStart = selectedDate.toString();

                  // Reset selected time when date changes
                  _selectedTime = null;
                  plageHoraireId = 0;
                  prixTotal = 0.0;
                });

                final selectedDateOnly = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                );

                // Refresh plage horaires
                controllerhourau.plageHoraires.refresh();

                // Fetch price when date is selected and time slot is available
                if (plageHoraireId > 0) {
                  controllerTerrain
                      .fetchPriceByPlageHoraireId(plageHoraireId)
                      .then((price) {
                        setState(() {
                          prixTotal = price ?? 0.0;
                        });
                      })
                      .catchError((error) {
                        print('Error fetching price: $error');
                        setState(() {
                          prixTotal = 0.0;
                        });
                      });
                }
              });
            },
            onMatchOpenChanged: (bool isOpen) {
              // typer: 1 => private (valid directly), 2 => open (pending)
              setState(() {
                typer = isOpen ? 2 : 1;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Choisir votre créneau",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.3),
                  border: Border.all(color: Color(0xFFFFB800), width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$prixTotal C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          Center(
            child: Obx(() {
              if (controllerhourau.isLoading.value) {
                return const SizedBox(
                  height: 25,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }

              // if (controllerhourau.errorMessage.value.isNotEmpty) {
              //   return Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: Container(
              //       width: double.infinity,

              //       margin: const EdgeInsets.symmetric(horizontal: 20),
              //       decoration: BoxDecoration(
              //         borderRadius: BorderRadius.circular(20),

              //         boxShadow: [
              //           BoxShadow(
              //             color: const Color.fromARGB(
              //               255,
              //               15,
              //               15,
              //               16,
              //             ).withOpacity(0.2),
              //             blurRadius: 15,
              //             spreadRadius: 2,
              //           ),
              //         ],
              //       ),
              //       child: Column(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: [
              //           Icon(
              //             Icons.calendar_today,
              //             color: const Color.fromARGB(255, 255, 255, 255),
              //             size: 32,
              //           ),
              //           const SizedBox(height: 12),
              //           Text(
              //             'Select a Date',
              //             style: TextStyle(
              //               color: Colors.white,
              //               fontSize: 15,
              //               fontWeight: FontWeight.bold,
              //               shadows: [
              //                 Shadow(
              //                   color: Colors.purple.withOpacity(0.5),
              //                   blurRadius: 8,
              //                 ),
              //               ],
              //             ),
              //           ),
              //           const SizedBox(height: 8),
              //           Text(
              //             'Choose a date to see available time slots',
              //             style: TextStyle(
              //               color: Colors.grey[400],
              //               fontSize: 10,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   );
              // }
              // Get selected date or default to today
              // Determine selected date: prefer explicit selection; otherwise use first available slot date
              final selectedDate = () {
                if (dateEnddateStart.isNotEmpty) {
                  final parsed = DateTime.tryParse(dateEnddateStart);
                  if (parsed != null) return parsed;
                }
                if (controllerhourau.plageHoraires.isNotEmpty) {
                  final first = controllerhourau.plageHoraires.first.startTime;
                  return DateTime(first.year, first.month, first.day);
                }
                return DateTime.now();
              }();

              // Filter slots for the selected date (today by default)
              final availableSlots =
                  controllerhourau.plageHoraires.where((horaire) {
                    final horaireDate = DateTime(
                      horaire.startTime.year,
                      horaire.startTime.month,
                      horaire.startTime.day,
                    );
                    final selectedDateOnly = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                    );
                    return horaireDate.isAtSameMomentAs(selectedDateOnly);
                  }).toList();

              if (availableSlots.isEmpty) {
                // No slots for this selected date: show inline empty-state message
                return Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFd1e301).withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Cette date n\'a pas de créneaux horaires correspondants (plage horaire).',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableSlots.length,
                  itemBuilder: (context, index) {
                    final horaire = availableSlots[index];
                    final formattedSlot =
                        "${_formatTime(horaire.startTime)} - ${_formatTime(horaire.endTime)}";
                    final isSelected = formattedSlot == _selectedTime;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTime = null;
                            plageHoraireId = 0;
                            prixTotal = 0;
                          } else {
                            _selectedTime = formattedSlot;
                            plageHoraireId = horaire.id;
                            prixTotal = horaire.price;

                            // Update dateEnddateStart with the selected time slot's start time
                            dateEnddateStart = horaire.startTime.toString();
                          }
                        });
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected
                                    ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFB800),
                                      ],
                                    )
                                    : null,
                            color: isSelected ? null : const Color(0xFF2A2A3E),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: const Color(0x66FFD700),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Center(
                            child: Text(
                              formattedSlot,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.black
                                        : Colors.grey[300],
                                fontSize: 12,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveButton({
    required int userId,
    required int terrainId,
    required int plageHoraireId,
    required String date,
    required double prixTotal,
    required VoidCallback onSuccess,
  }) {
    bool isPayForAll = false; // Track if paying for all players
    final currentTime = DateTime.now();
    final bookingTime = DateTime.parse(date);
    final isWeekend =
        bookingTime.weekday == DateTime.friday ||
        bookingTime.weekday == DateTime.saturday;

    double userBalance =
        double.tryParse(profileController.creditBalance.value) ?? 0.0;

    // Helper function to determine available payment methods
    List<PaymentMethod> getAvailablePaymentMethods() {
      final hour = bookingTime.hour;

      // If match is open (typer == 2), enforce onsite payment only.
      // We will also bypass the dialog in the tap handler, but this keeps
      // the method consistent wherever it's referenced.
      if (typer == 2) {
        return [PaymentMethod.onsite];
      }

      if (isWeekend) {
        return [PaymentMethod.gold, PaymentMethod.onsite];
      }

      if (hour >= 8 && hour < 17) {
        return [PaymentMethod.silver, PaymentMethod.gold, PaymentMethod.onsite];
      }

      return [PaymentMethod.gold, PaymentMethod.onsite];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          // Info icon button
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white70),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Reservation Rules'),
                        content: const Text(
                          '• Off-Peak credits: Available 8:00-17:00 on weekdays\n'
                          '• Premium credits: Available anytime\n'
                          '• Weekend bookings: Premium credits or onsite payment only\n'
                          '• Pay for all option: Deducts 4x credits from your account',
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Got it'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                );
              },
            ),
          ),

          // Main reservation button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Obx(() {
              if (reservationController.isLoading.value) {
                return const CircularProgressIndicator(color: Colors.white);
              }

              return InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () async {
                  // Get user info first
                  try {
                    final userInfo = await controllerUser.getUserInfo(
                      userId: userId.toString(),
                    );
                    final userCredits =
                        userInfo['credit_balance'] is num
                            ? (userInfo['credit_balance'] as num).toDouble()
                            : double.tryParse(
                                  userInfo['credit_balance']?.toString() ??
                                      userInfo['credit_gold_padel']
                                          ?.toString() ??
                                      '',
                                ) ??
                                0.0;

                    // New rule: when "Match Ouvert" is selected (typer == 2),
                    // require credit balance to cover the per-person price before allowing reservation.
                    // Also, do not show payment options; auto-select Sur place.
                    if (typer == 2) {
                      // Match Ouvert: show French confirmation, then debit credit and create
                      if (userCredits < prixTotal) {
                        _showNeonDialog(
                          context,
                          title: 'Solde insuffisant',
                          message:
                              'Vous n\'avez pas assez de crédits pour couvrir votre part du Match Ouvert. Veuillez recharger votre solde.',
                        );
                        return;
                      }

                      if (terrainId == 0 ||
                          plageHoraireId == 0 ||
                          date.isEmpty) {
                        _showNeonDialog(
                          context,
                          title: 'Informations manquantes',
                          message:
                              'Veuillez sélectionner ${terrainId == 0
                                  ? "un terrain"
                                  : plageHoraireId == 0
                                  ? "un créneau horaire"
                                  : "une date"} avant de continuer.',
                        );
                        return;
                      }

                      final confirmed = await _showModernConfirmDialog(
                        context,
                        title: 'Confirmer la création',
                        message:
                            'Confirmez-vous la création de ce Match Ouvert ?\nLe montant de ${prixTotal.toStringAsFixed(2)} C sera débité de votre crédit.',
                        confirmLabel: 'Confirmer',
                        cancelLabel: 'Annuler',
                      );

                      if (!confirmed) return;

                      try {
                        final resp = await controllerUser.deductCredit(
                          userId: userId.toString(),
                          creditAmount: prixTotal.toString(),
                        );

                        if (resp['success'] == true) {
                          await reservationController.createReservationWithData(
                            etat: 1, // Crédit débité => réservation validée
                            typer: typer,
                            idUtilisateur: userId,
                            idTerrain: terrainId,
                            idPlageHoraire: plageHoraireId,
                            date: date,
                            prixTotal: prixTotal,
                            typepaiementForCreator: 1,
                          );

                          await _showModernStatusDialog(
                            context,
                            title: 'Réservation confirmée',
                            message:
                                'Votre match a été créé et votre crédit a été débité avec succès.',
                            success: true,
                          );

                          onSuccess();
                        } else {
                          await _showModernStatusDialog(
                            context,
                            title: 'Déduction échouée',
                            message:
                                (resp['message']?.toString() ??
                                    'Impossible de débiter votre crédit. Réessayez ou contactez le support.'),
                            success: false,
                          );
                        }
                      } catch (e) {
                        await _showModernStatusDialog(
                          context,
                          title: 'Erreur',
                          message: e.toString(),
                          success: false,
                        );
                      }

                      return;
                    }

                    _showPaymentMethodDialog(
                      context,
                      availableMethods: getAvailablePaymentMethods(),
                      onPaymentSelected: (method, payForAll) async {
                        final totalAmount =
                            payForAll ? prixTotal * 4 : prixTotal;

                        switch (method) {
                          case PaymentMethod.silver:
                            if (userCredits < totalAmount) {
                              _showNeonDialog(
                                context,
                                title: 'Crédits insuffisants',
                                message:
                                    'Vous n\'avez pas assez de crédits pour terminer cette transaction.',
                              );
                              return;
                            }
                            // Calculate new balance after deduction
                            if (terrainId == 0 ||
                                plageHoraireId == 0 ||
                                date.isEmpty) {
                              _showNeonDialog(
                                context,
                                title: 'Informations manquantes',
                                message:
                                    'Veuillez sélectionner ${terrainId == 0
                                        ? "un terrain"
                                        : plageHoraireId == 0
                                        ? "un créneau horaire"
                                        : "une date"} avant de continuer.',
                              );
                              return;
                            }

                            // Deduct the amount paid (not the new balance)
                            final success = await controllerUser.deductCredit(
                              userId: userId.toString(),
                              creditAmount: totalAmount.toString(),
                            );
                            if (success['success'] == true) {
                              await reservationController
                                  .createReservationWithData(
                                    etat: 1, // Credit payment => valid
                                    typer: typer,
                                    idUtilisateur: userId,
                                    idTerrain: terrainId,
                                    idPlageHoraire: plageHoraireId,
                                    date: date,
                                    prixTotal: totalAmount,
                                    typepaiementForCreator: 1,
                                  );
                              onSuccess();
                            }
                            break;

                          case PaymentMethod.gold:
                            if (terrainId == 0 ||
                                plageHoraireId == 0 ||
                                date.isEmpty) {
                              _showNeonDialog(
                                context,
                                title: 'Informations manquantes',
                                message:
                                    'Veuillez sélectionner ${terrainId == 0
                                        ? "un terrain"
                                        : plageHoraireId == 0
                                        ? "un créneau horaire"
                                        : "une date"} avant de continuer.',
                              );
                              return;
                            }

                            if (userCredits < totalAmount) {
                              _showNeonDialog(
                                context,
                                title: 'Crédits insuffisants',
                                message:
                                    'Vous n\'avez pas assez de crédits silver pour terminer cette transaction.',
                              );
                              return;
                            }
                            // Deduct the amount paid (not the new balance)
                            final success = await controllerUser.deductCredit(
                              userId: userId.toString(),
                              creditAmount: totalAmount.toString(),
                            );
                            if (success['success'] == true) {
                              await reservationController
                                  .createReservationWithData(
                                    etat: 1, // Credit payment => valid
                                    typer: typer,
                                    idUtilisateur: userId,
                                    idTerrain: terrainId,
                                    idPlageHoraire: plageHoraireId,
                                    date: date,
                                    prixTotal: totalAmount,
                                    typepaiementForCreator: 1,
                                  );
                              onSuccess();
                            }
                            break;

                          case PaymentMethod.onsite:
                            if (terrainId == 0 ||
                                plageHoraireId == 0 ||
                                date.isEmpty) {
                              _showNeonDialog(
                                context,
                                title: 'Informations manquantes',
                                message:
                                    'Veuillez sélectionner ${terrainId == 0
                                        ? "un terrain"
                                        : plageHoraireId == 0
                                        ? "un créneau horaire"
                                        : "une date"} avant de continuer.',
                              );
                              return;
                            }

                            await reservationController
                                .createReservationWithData(
                                  etat: 0, // Sur place => pending (en attente)
                                  typer:
                                      typer, // Determined by Match Ouvert toggle
                                  idUtilisateur: userId,
                                  idTerrain: terrainId,
                                  idPlageHoraire: plageHoraireId,
                                  date: date,
                                  prixTotal: totalAmount,
                                  typepaiementForCreator: 2,
                                );
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E2E),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(0xFF2A2A3E),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFFC107),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.hourglass_bottom,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'Pending Confirmation',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Please wait for confirmation from the Administration to confirm your order reservation. Thank you.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF6366F1,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'OK',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                            onSuccess();
                            break;

                          case PaymentMethod.online:
                            if (terrainId == 0 ||
                                plageHoraireId == 0 ||
                                date.isEmpty) {
                              _showNeonDialog(
                                context,
                                title: 'Missing Information',
                                message:
                                    'Please select a ${terrainId == 0
                                        ? "terrain"
                                        : plageHoraireId == 0
                                        ? "time slot"
                                        : "date"} before proceeding.',
                              );
                              return;
                            }

                            Get.snackbar(
                              'Information',
                              'Paiement en ligne bientôt disponible',
                            );
                            break;
                        }
                      },
                    );
                  } catch (e) {
                    Get.snackbar('Error', 'Failed to get user information');
                    print('Error fetching user info: $e');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF171717), Color(0xFF0E0E0E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFFd1e301),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFd1e301).withOpacity(0.25),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: const Color(0xFFd1e301).withOpacity(0.1),
                        blurRadius: 48,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_tennis,
                          color: Color(0xFFd1e301),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'RÉSERVER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Payment method selection dialog – modern glass-morphic style
  void _showPaymentMethodDialog(
    BuildContext context, {
    required List<PaymentMethod> availableMethods,
    required Function(PaymentMethod, bool) onPaymentSelected,
  }) {
    bool payForAll = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black87, // darker backdrop for padel vibe
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF121212), // solid dark padel court feel
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFFd1e301).withOpacity(0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                ),
                BoxShadow(
                  color: const Color(0xFFd1e301).withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Choisir un paiement',
                        style: TextStyle(
                          color: Color(0xFFd1e301),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 40, 43, 42),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color.fromARGB(255, 235, 234, 234),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Payment options
                  ...availableMethods.map(
                    (method) => _buildPaymentOption(
                      method: method,
                      onTap: () {
                        Navigator.pop(context);
                        onPaymentSelected(method, payForAll);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required VoidCallback onTap,
  }) {
    final methodData =
        {
          PaymentMethod.gold: ('Crédits', Icons.star, const Color(0xFFFFB800)),
          PaymentMethod.silver: (
            'Espèces',
            Icons.payments,
            const Color(0xFFC0C0C0),
          ),
          PaymentMethod.onsite: (
            'Sur place',
            Icons.location_on,
            const Color(0xFF34D399), // padel green
          ),
          PaymentMethod.online: (
            'En ligne',
            Icons.credit_card,
            const Color(0xFF60A5FA),
          ),
        }[method]!;

    final enabled = method != PaymentMethod.online;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        splashColor: methodData.$3.withOpacity(0.25),
        highlightColor: methodData.$3.withOpacity(0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [const Color(0xFF1E1E1E), const Color(0xFF121212)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: enabled ? methodData.$3.withOpacity(0.7) : Colors.white24,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: methodData.$3.withOpacity(enabled ? 0.2 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(methodData.$2, color: methodData.$3, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  methodData.$1,
                  style: TextStyle(
                    color: enabled ? const Color(0xFFE0E0E0) : Colors.white38,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: enabled ? const Color(0xFFE0E0E0) : Colors.white24,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF8B8B9A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? const Color(0xFF6366F1) : Colors.white,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Neon dark popup helper for unified alerts
  void _showNeonDialog(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.warning_amber_rounded,
    String actionLabel = 'OK',
  }) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFd1e301).withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFd1e301).withOpacity(0.2),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFd1e301),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.black, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFFd1e301),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFFd1e301),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<bool> _showModernConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD1E301), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD1E301).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD1E301), Color(0xFFB8C802)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD1E301).withOpacity(0.6),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_tennis,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFD1E301)),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFD1E301),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

    return result ?? false;
  }

  Future<void> _showModernStatusDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool success,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final Color start =
            success ? const Color(0xFF0EA5E9) : const Color(0xFFEF4444);
        final Color end =
            success ? const Color(0xFF10B981) : const Color(0xFFDC2626);
        final IconData icon =
            success ? Icons.check_circle : Icons.error_outline;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [start.withOpacity(0.15), end.withOpacity(0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: const Color(0xFF1E1F2B).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3A3D5C), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [start, end]),
                    boxShadow: [
                      BoxShadow(color: end.withOpacity(0.5), blurRadius: 18),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        success
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 28,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
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
              Get.to(() => EnhancedHistoryScreen());
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

  String? getValidImageUrl(Terrain terrain) {
    if (terrain.imageUrl.isNotEmpty == true &&
        terrain.imageUrl.startsWith('http')) {
      // Optional: Filter out known test/placeholder domains to reduce 404 errors
      final String url = terrain.imageUrl;
      if (url.contains('example.com')) {
        return null; // Skip example.com URLs as they're typically not real
      }
      return url;
    }
    return null; // Return null for invalid URLs
  }

  // Simpler widget that handles errors gracefully without pre-checking URLs
  Widget buildTerrainImage(
    Terrain terrain, {
    double height = double.infinity,
    double width = double.infinity,
  }) {
    final String? imageUrl = getValidImageUrl(terrain);

    if (imageUrl != null) {
      // Valid HTTP URL - try to load it with error handling
      return SizedBox(
        height: height,
        width: width,
        child: Image.network(
          imageUrl,
          height: height,
          width: width,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Handle 404s, network errors, etc.
            return _buildPlaceholder(height, width, terrain.name ?? 'Sans nom');
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              child: child,
            );
          },
        ),
      );
    } else {
      // No valid URL - show placeholder immediately
      return _buildPlaceholder(height, width, terrain.name ?? 'Sans nom');
    }
  }

  // Local placeholder widget (no internet required)
  Widget _buildPlaceholder(double height, double width, String terrainName) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(color: Colors.grey[400]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey[600], size: 50),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              terrainName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithErrorHandling(
    String imageUrl,
    double height,
    double width,
  ) {
    // Filter out example.com URLs to prevent 404s
    if (imageUrl.contains('example.com')) {
      return _buildPlaceholder(height, width, 'Image non disponible');
    }

    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(height, width, 'Image non disponible');
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(seconds: 1),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }
}

class ClubInfo {
  final String name;
  final String phone;
  final String website;
  final String coverImageUrl;
  final String clubImageUrl;
  final String address;
  final double latitude;
  final double longitude;
  final String description;
  final List<String> amenities;

  ClubInfo({
    required this.name,
    required this.phone,
    required this.website,
    required this.coverImageUrl,
    required this.clubImageUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.amenities,
  });
}

enum PaymentMethod { silver, gold, onsite, online }
