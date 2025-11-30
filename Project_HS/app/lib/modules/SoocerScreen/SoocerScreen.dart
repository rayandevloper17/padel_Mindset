// // ✅ Cleaned and corrected version of your code:
// import 'dart:ffi';

// import 'package:app/controllers/plage_hourai_controller.dart';
// import 'package:app/global/constants/images.dart';
// import 'package:app/global/themes/app_theme.dart';
// import 'package:app/modules/Header/header_page.dart';
// import 'package:app/modules/History_Page/history_Page.dart';
// import 'package:app/modules/Padel/controller.dart';
// import 'package:app/modules/ProfileView/controller_profile_page.dart';
// import 'package:app/modules/SoocerScreen/constatns/datepiker_cont.dart';
// import 'package:app/modules/SoocerScreen/controller.dart';
// import 'package:app/modules/SoocerScreen/terrain_model.dart';
// import 'package:app/modules/join_Pages/join_pages.dart';
// import 'package:app/modules/reserveing/reservation_controller.dart';
// import 'package:app/modules/reserving_screen/reserving_screen.dart';
// import 'package:app/modules/settings/settings_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get.dart';
// import 'package:app/modules/SoocerScreen/terrain_controller.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';

// class SoocerScreen extends StatefulWidget {
//   const SoocerScreen({super.key});

//   @override
//   State<SoocerScreen> createState() => _SoocerScreenState();
// }

// class _SoocerScreenState extends State<SoocerScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//   late PageController _pageController;

//   final TerrainController controllerTerrain = Get.put(TerrainController());
//   final Scoorcontroller controller = Get.put(Scoorcontroller());
//   final reservationController = Get.put(ReservationController());

//   final PlageHoraireController controllerhourau = Get.put(
//     PlageHoraireController(),
//   );
//   String? _selectedTime;
//   List<String> timeSlots = [];
//   int _currentImageIndex = 0;
//   int userId = 0; // Store user ID from token
//   int idofterain = 0; // Store the selected terrain ID
//   int plageHoraireId = 0; // Store the selected terrain ID
//   String dateEnddateStart = '';

//   double prixTotal = 0;

//   int selectedTerrainIndex = -1; // -1 = nothing selected yet

//   String _formatTime(DateTime time) {
//     return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
//   }

//   String _formatTimeSlot(PlageHoraire plage) {
//     final startHour = plage.startTime.hour.toString().padLeft(2, '0');
//     final startMinute = plage.startTime.minute.toString().padLeft(2, '0');
//     return '$startHour:$startMinute';
//   }

//   PlageHoraire? get selectedPlageHoraire {
//     if (_selectedTime == null) return null;

//     return controllerhourau.plageHoraires.firstWhereOrNull(
//       (plage) => _formatTimeSlot(plage) == _selectedTime,
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeIn,
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.1),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );

//     _pageController = PageController();

//     // Fetch terrain data
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       print('📡 Post frame callback - fetching terrain data');
//       controllerTerrain.fetchAllTerrains();
//     });

//     // Start animations
//     _animationController.forward();
//     print('✅ Animations started');

//     ever(controllerhourau.plageHoraires, (List<PlageHoraire> plages) {
//       print('👂 PlageHoraires changed - count: ${plages.length}');

//       timeSlots = plages.map((p) => _formatTimeSlot(p)).toList();

//       if (plages.isNotEmpty && _selectedTime == null) {
//         print('🎯 Setting default selected time');
//         setState(() {
//           _selectedTime = timeSlots.first;
//           print('✅ Selected time set to: $_selectedTime');
//         });
//       } else {
//         setState(() {}); // Rebuild timeSlots if already set
//       }
//     });

//     // Also listen to loading state
//     Future.delayed(Duration.zero, () async {
//       await Future.doWhile(() async {
//         await Future.delayed(const Duration(milliseconds: 100));
//         return controllerhourau.isLoading.value;
//       });
//       for (var item in controllerhourau.plageHoraires) {
//         print(
//           "⏱️ Horaire reçu: ${item.startTime} -> ${item.endTime} - ${item.price} C",
//         );
//       }
//     });

//     // Get user ID from secure storage and fetch data
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       final storage = FlutterSecureStorage();

//       // Get the authentication token
//       final token = await storage.read(key: 'token');
//       if (token != null) {
//         Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//         print('🧩 Decoded Token: $decodedToken');

//         // Store user ID in class variable
//         setState(() {
//           userId = int.parse(decodedToken['id'].toString());
//         });
//         print('👤 User ID from token: $userId');
//       }

//       print('📡 Post frame callback - fetching terrain data with auth token');
//     });

//     print('🏁 InitState finished');
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     int currentTerrainId = 0;

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       extendBody: true,
//       extendBodyBehindAppBar: true,
//       body: Container(
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage(AppImages.home_background),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: Obx(() {
//           if (controllerTerrain.isLoading.value) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final terrains = controllerTerrain.terrains;

//           if (terrains.isEmpty) {
//             return const Center(child: Text("Aucun terrain trouvé"));
//           }

//           return SafeArea(
//             child: Stack(
//               children: [
//                 Positioned.fill(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           AppTheme.overlayColor,
//                           AppTheme.primaryColor.withOpacity(0.7),
//                           AppTheme.primaryColor.withOpacity(0.9),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 Column(
//                   children: [
//                     CreditHeader(ishowing: true),
//                     _buildHeader(context),
//                     SizedBox(height: context.height * 0.01),

//                     _buildTitleSection(context),

//                     const SizedBox(height: 10),
//                     Expanded(
//                       child: FadeTransition(
//                         opacity: _fadeAnimation,
//                         child: SlideTransition(
//                           position: _slideAnimation,
//                           child: PageView.builder(
//                             controller: _pageController,
//                             itemCount: terrains.length,
//                             onPageChanged: (index) {
//                               final terrainId = terrains[index].id;
//                               controllerhourau.getPlageHorairesForTerrain(
//                                 terrainId,
//                               );
//                             },

//                             itemBuilder: (context, index) {
//                               final terrain = terrains[index];
//                               final imageList = <String>[];

//                               if (terrain.imageUrl != null &&
//                                   terrain.imageUrl!.isNotEmpty) {
//                                 final fullImageUrl =
//                                     terrain.imageUrl!.startsWith('http')
//                                         ? terrain.imageUrl!
//                                         : 'http://127.0.0.1:300${terrain.imageUrl}';
//                                 imageList.add(fullImageUrl);
//                               }

//                               return Column(
//                                 children: [
//                                   const SizedBox(height: 10),
//                                   _buildCarousel(
//                                     imageList,
//                                     terrain.name ?? 'Terrain',
//                                   ),
//                                 ],
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//                     ),
//                     // Fixed bottom section
//                     Container(
//                       padding: const EdgeInsets.symmetric(vertical: 20),
//                       decoration: BoxDecoration(
//                         color: AppTheme.primaryColor.withOpacity(0.9),
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(30),
//                           topRight: Radius.circular(30),
//                         ),
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           _buildTimeSelectorResponsive(),
//                           const SizedBox(height: 20),
//                           _buildReserveButton(
//                             userId: userId,
//                             terrainId: idofterain,
//                             plageHoraireId: plageHoraireId,
//                             date: dateEnddateStart,
//                             prixTotal: prixTotal,
//                             onSuccess: () {
//                               // Optional: Show toast, navigate, etc.
//                               print("Reservation created!");
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           );
//         }),
//       ),
//       bottomNavigationBar: _buildBottomNav(),
//     );
//   }

//   // === Reusable Widgets ===

//   Widget _navArrow(IconData icon) => Container(
//     width: 40,
//     height: 40,
//     decoration: BoxDecoration(
//       color: Colors.black.withOpacity(0.5),
//       shape: BoxShape.circle,
//     ),
//     child: Icon(icon, color: Colors.white, size: 24),
//   );

//   Widget _buildTitleSection(BuildContext context) {
//     return Column(
//       children: [
//         Text(
//           "CENTRAL SOCCER",
//           style: Theme.of(context).textTheme.displaySmall?.copyWith(
//             color: AppTheme.primaryTextColor,
//             fontWeight: FontWeight.bold,
//           ),
//           textAlign: TextAlign.start,
//         ),
//         SizedBox(height: context.height * 0.02),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 30),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Text(
//                   "Choisir Votre Type de Terrain",
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: AppTheme.primaryTextColor,
//                     height: 1.2,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     return Row(
//       children: [
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: context.width * 0.02),
//           child: GestureDetector(
//             onTap: () => Get.back(),
//             child: const Row(
//               children: [
//                 Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
//                 SizedBox(width: 4),
//                 Text("Retourner", style: TextStyle(color: Colors.white)),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCarousel(List<String> images, String label) {
//     return SizedBox(
//       height:
//           MediaQuery.of(context).size.height *
//           0.2, // Responsive height based on screen size
//       child: Stack(
//         children: [
//           PageView.builder(
//             controller: _pageController,
//             itemCount: images.isNotEmpty ? images.length : 1,
//             onPageChanged: (index) {
//               setState(() {
//                 _currentImageIndex = index;
//                 final terrain = controllerTerrain.terrains[index];
//                 // Store the terrain ID in class variable
//                 idofterain = terrain.id;
//                 print('🟢 Swiped to Terrain ID: $idofterain');
//               });
//             },
//             itemBuilder: (context, index) {
//               final terrain = controllerTerrain.terrains[index];
//               final isSelected = index == selectedTerrainIndex;

//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     selectedTerrainIndex = index;
//                   });
//                   idofterain = terrain.id;
//                   print('✅ Tapped Terrain ID: ${terrain.id}');
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: Stack(
//                       children: [
//                         images.isNotEmpty
//                             ? _buildImageWithErrorHandling(
//                               images[index],
//                               280,
//                               double.infinity,
//                             )
//                             : _buildPlaceholder(280, double.infinity, label),
//                         Positioned(
//                           bottom: 20,
//                           left: 20,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.7),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               label,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//           if (images.length > 1) ...[
//             Positioned(
//               left: 10,
//               top: 0,
//               bottom: 0,
//               child: Center(
//                 child: GestureDetector(
//                   onTap: () {
//                     if (_pageController.hasClients && _currentImageIndex > 0) {
//                       _pageController.previousPage(
//                         duration: const Duration(milliseconds: 300),
//                         curve: Curves.easeInOut,
//                       );
//                     }
//                   },
//                   child: _navArrow(Icons.chevron_left),
//                 ),
//               ),
//             ),
//             Positioned(
//               right: 10,
//               top: 0,
//               bottom: 0,
//               child: Center(
//                 child: GestureDetector(
//                   onTap: () {
//                     if (_pageController.hasClients &&
//                         _currentImageIndex < images.length - 1) {
//                       _pageController.nextPage(
//                         duration: const Duration(milliseconds: 300),
//                         curve: Curves.easeInOut,
//                       );
//                     }
//                   },
//                   child: _navArrow(Icons.chevron_right),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildTerrainDetails(String name) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Text(
//         name,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 24,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildTimeSelectorResponsive() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Choisir Votre Crénau',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 14),

//           DatePickerContainer(
//             onDateSelected: (DateTime selectedDate) {
//               setState(() {
//                 dateEnddateStart = selectedDate.toString();
//                 print('Selected date: $dateEnddateStart');

//                 // Filter plage horaires for selected date
//                 final selectedDateOnly = DateTime(
//                   selectedDate.year,
//                   selectedDate.month,
//                   selectedDate.day,
//                 );

//                 // Update available time slots based on selected date
//                 controllerhourau.plageHoraires.refresh();
//               });
//             },
//           ),

//           Obx(() {
//             // 🌀 Loading
//             if (controllerhourau.isLoading.value) {
//               return const SizedBox(
//                 height: 60,
//                 child: Center(
//                   child: CircularProgressIndicator(color: Colors.white),
//                 ),
//               );
//             }

//             // ❌ Error
//             if (controllerhourau.errorMessage.value.isNotEmpty) {
//               return const SizedBox(
//                 height: 60,
//                 child: Center(
//                   child: Text(
//                     'Erreur de connexion',
//                     style: TextStyle(color: Colors.white, fontSize: 14),
//                   ),
//                 ),
//               );
//             }

//             // Filter plage horaires for selected date
//             final selectedDate = DateTime.tryParse(dateEnddateStart);
//             final availableSlots =
//                 controllerhourau.plageHoraires.where((horaire) {
//                   if (selectedDate == null) return true;

//                   final horaireDate = DateTime(
//                     horaire.startTime.year,
//                     horaire.startTime.month,
//                     horaire.startTime.day,
//                   );

//                   final selectedDateOnly = DateTime(
//                     selectedDate.year,
//                     selectedDate.month,
//                     selectedDate.day,
//                   );

//                   return horaireDate.isAtSameMomentAs(selectedDateOnly);
//                 }).toList();

//             // 📭 No Data for selected date
//             if (availableSlots.isEmpty) {
//               return const SizedBox(
//                 height: 60,
//                 child: Center(
//                   child: Text(
//                     'Aucun créneau disponible pour cette date',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               );
//             }

//             // ✅ Data Available
//             return SizedBox(
//               height: 60,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: availableSlots.length,
//                 itemBuilder: (context, index) {
//                   final horaire = availableSlots[index];

//                   final formattedSlot =
//                       "${_formatTime(horaire.startTime)} - ${_formatTime(horaire.endTime)}";

//                   final isSelected = formattedSlot == _selectedTime;

//                   return GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _selectedTime = formattedSlot;
//                         dateEnddateStart = horaire.startTime.toString();
//                         plageHoraireId = horaire.id;
//                         prixTotal = horaire.price;
//                         print('Selected Horaire ID: ${horaire.id}');
//                         print('Selected Price: ${horaire.price} C');
//                       });
//                     },
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       margin: const EdgeInsets.only(right: 15),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 14,
//                       ),
//                       decoration: BoxDecoration(
//                         color: isSelected ? Colors.white : Colors.transparent,
//                         borderRadius: BorderRadius.circular(30),
//                         border: Border.all(
//                           color:
//                               isSelected
//                                   ? Colors.white
//                                   : Colors.white.withOpacity(0.3),
//                           width: 2,
//                         ),
//                       ),
//                       child: Center(
//                         child: Text(
//                           formattedSlot,
//                           style: TextStyle(
//                             color: isSelected ? Colors.black : Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildReserveButton({
//     required int userId,
//     required int terrainId,
//     required int plageHoraireId,
//     required String date,
//     required double prixTotal,
//     required VoidCallback onSuccess,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: SizedBox(
//         width: double.infinity,
//         height: 56,
//         child: Obx(() {
//           if (reservationController.isLoading.value) {
//             return const CircularProgressIndicator(color: Colors.white);
//           }

//           return ElevatedButton(
//             onPressed: () {
//               // Show reservation details popup
//               showDialog(
//                 context: context,
//                 barrierDismissible: true,
//                 barrierColor: Colors.black.withOpacity(0.7),
//                 builder: (BuildContext context) {
//                   bool silverSelected = false;
//                   bool goldSelected = false;

//                   return StatefulBuilder(
//                     builder: (context, setState) {
//                       return Dialog(
//                         backgroundColor: Colors.transparent,
//                         elevation: 0,
//                         child: Container(
//                           margin: const EdgeInsets.all(2),
//                           padding: const EdgeInsets.all(5),
//                           decoration: BoxDecoration(
//                             color: const Color(
//                               0xFF1E1E2E,
//                             ), // Deep dark background
//                             borderRadius: BorderRadius.circular(24),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.3),
//                                 blurRadius: 20,
//                                 spreadRadius: 0,
//                                 offset: const Offset(0, 8),
//                               ),
//                             ],
//                             border: Border.all(
//                               color: const Color(0xFF2A2A3E),
//                               width: 1,
//                             ),
//                           ),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               // Header with close button
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   const Text(
//                                     'Choose Credit Package',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.w700,
//                                       letterSpacing: 0.5,
//                                     ),
//                                   ),
//                                   GestureDetector(
//                                     onTap: () => Navigator.pop(context),
//                                     child: Container(
//                                       padding: const EdgeInsets.all(8),
//                                       decoration: BoxDecoration(
//                                         color: const Color(0xFF2A2A3E),
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: const Icon(
//                                         Icons.close,
//                                         color: Color(0xFF8B8B9A),
//                                         size: 20,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 24),

//                               // Credit Options with modern cards
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: GestureDetector(
//                                       onTap: () {
//                                         setState(() {
//                                           silverSelected = true;
//                                           goldSelected = false;
//                                         });
//                                       },
//                                       child: AnimatedContainer(
//                                         duration: const Duration(
//                                           milliseconds: 200,
//                                         ),
//                                         padding: const EdgeInsets.all(20),
//                                         decoration: BoxDecoration(
//                                           gradient:
//                                               silverSelected
//                                                   ? LinearGradient(
//                                                     begin: Alignment.topLeft,
//                                                     end: Alignment.bottomRight,
//                                                     colors: [
//                                                       const Color(0xFF6B7280),
//                                                       const Color(0xFF4B5563),
//                                                     ],
//                                                   )
//                                                   : null,
//                                           color:
//                                               silverSelected
//                                                   ? null
//                                                   : const Color(0xFF2A2A3E),
//                                           border: Border.all(
//                                             color:
//                                                 silverSelected
//                                                     ? const Color(0xFF9CA3AF)
//                                                     : const Color(0xFF3A3A4E),
//                                             width: silverSelected ? 2 : 1,
//                                           ),
//                                           borderRadius: BorderRadius.circular(
//                                             16,
//                                           ),
//                                           boxShadow:
//                                               silverSelected
//                                                   ? [
//                                                     BoxShadow(
//                                                       color: const Color(
//                                                         0xFF6B7280,
//                                                       ).withOpacity(0.3),
//                                                       blurRadius: 12,
//                                                       spreadRadius: 0,
//                                                     ),
//                                                   ]
//                                                   : null,
//                                         ),
//                                         child: Column(
//                                           children: [
//                                             Container(
//                                               padding: const EdgeInsets.all(8),
//                                               decoration: BoxDecoration(
//                                                 color: const Color(0xFF374151),
//                                                 borderRadius:
//                                                     BorderRadius.circular(8),
//                                               ),
//                                               child: const Icon(
//                                                 Icons.stars_rounded,
//                                                 color: Color(0xFF9CA3AF),
//                                                 size: 24,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 12),
//                                             const Text(
//                                               'SILVER',
//                                               style: TextStyle(
//                                                 color: Color(0xFF9CA3AF),
//                                                 fontWeight: FontWeight.w700,
//                                                 fontSize: 14,
//                                                 letterSpacing: 1,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             const Text(
//                                               '34 C',
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 24,
//                                                 fontWeight: FontWeight.w800,
//                                               ),
//                                             ),
//                                             if (silverSelected)
//                                               Container(
//                                                 margin: const EdgeInsets.only(
//                                                   top: 8,
//                                                 ),
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                       horizontal: 8,
//                                                       vertical: 4,
//                                                     ),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.white
//                                                       .withOpacity(0.2),
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                 ),
//                                                 child: const Text(
//                                                   'Selected',
//                                                   style: TextStyle(
//                                                     color: Colors.white,
//                                                     fontSize: 10,
//                                                     fontWeight: FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     child: GestureDetector(
//                                       onTap: () {
//                                         setState(() {
//                                           goldSelected = true;
//                                           silverSelected = false;
//                                         });
//                                       },
//                                       child: AnimatedContainer(
//                                         duration: const Duration(
//                                           milliseconds: 200,
//                                         ),
//                                         padding: const EdgeInsets.all(20),
//                                         decoration: BoxDecoration(
//                                           gradient:
//                                               goldSelected
//                                                   ? LinearGradient(
//                                                     begin: Alignment.topLeft,
//                                                     end: Alignment.bottomRight,
//                                                     colors: [
//                                                       const Color(0xFFFFB800),
//                                                       const Color(0xFFFF8F00),
//                                                     ],
//                                                   )
//                                                   : null,
//                                           color:
//                                               goldSelected
//                                                   ? null
//                                                   : const Color(0xFF2A2A3E),
//                                           border: Border.all(
//                                             color:
//                                                 goldSelected
//                                                     ? const Color(0xFFFFB800)
//                                                     : const Color(0xFF3A3A4E),
//                                             width: goldSelected ? 2 : 1,
//                                           ),
//                                           borderRadius: BorderRadius.circular(
//                                             16,
//                                           ),
//                                           boxShadow:
//                                               goldSelected
//                                                   ? [
//                                                     BoxShadow(
//                                                       color: const Color(
//                                                         0xFFFFB800,
//                                                       ).withOpacity(0.4),
//                                                       blurRadius: 12,
//                                                       spreadRadius: 0,
//                                                     ),
//                                                   ]
//                                                   : null,
//                                         ),
//                                         child: Column(
//                                           children: [
//                                             Container(
//                                               padding: const EdgeInsets.all(8),
//                                               decoration: BoxDecoration(
//                                                 color:
//                                                     goldSelected
//                                                         ? Colors.white
//                                                             .withOpacity(0.2)
//                                                         : const Color(
//                                                           0xFF374151,
//                                                         ),
//                                                 borderRadius:
//                                                     BorderRadius.circular(8),
//                                               ),
//                                               child: Icon(
//                                                 Icons.diamond_rounded,
//                                                 color:
//                                                     goldSelected
//                                                         ? Colors.white
//                                                         : const Color(
//                                                           0xFFFFB800,
//                                                         ),
//                                                 size: 24,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 12),
//                                             Text(
//                                               'GOLD',
//                                               style: TextStyle(
//                                                 color:
//                                                     goldSelected
//                                                         ? Colors.white
//                                                         : const Color(
//                                                           0xFFFFB800,
//                                                         ),
//                                                 fontWeight: FontWeight.w700,
//                                                 fontSize: 14,
//                                                 letterSpacing: 1,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               '34 C',
//                                               style: TextStyle(
//                                                 color:
//                                                     goldSelected
//                                                         ? Colors.white
//                                                         : Colors.white,
//                                                 fontSize: 24,
//                                                 fontWeight: FontWeight.w800,
//                                               ),
//                                             ),
//                                             if (goldSelected)
//                                               Container(
//                                                 margin: const EdgeInsets.only(
//                                                   top: 8,
//                                                 ),
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                       horizontal: 8,
//                                                       vertical: 4,
//                                                     ),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.white
//                                                       .withOpacity(0.2),
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                 ),
//                                                 child: const Text(
//                                                   'Selected',
//                                                   style: TextStyle(
//                                                     color: Colors.white,
//                                                     fontSize: 10,
//                                                     fontWeight: FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 32),

//                               // Reservation Details with modern styling
//                               Container(
//                                 padding: const EdgeInsets.all(20),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFF252538),
//                                   borderRadius: BorderRadius.circular(16),
//                                   border: Border.all(
//                                     color: const Color(0xFF3A3A4E),
//                                     width: 1,
//                                   ),
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       children: [
//                                         Container(
//                                           padding: const EdgeInsets.all(6),
//                                           decoration: BoxDecoration(
//                                             color: const Color(0xFF3A3A4E),
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                           child: const Icon(
//                                             Icons.receipt_long_rounded,
//                                             color: Color(0xFF8B8B9A),
//                                             size: 16,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 12),
//                                         const Text(
//                                           'Reservation Details',
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 16),

//                                     _detailRow('Date', date),
//                                     const Divider(
//                                       color: Color(0xFF3A3A4E),
//                                       height: 24,
//                                     ),
//                                     _detailRow('Total Price', '$prixTotal C'),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 32),

//                               // Confirm Button with modern styling
//                               Container(
//                                 width: double.infinity,
//                                 height: 56,
//                                 child: ElevatedButton(
//                                   onPressed: () {
//                                     if (!silverSelected && !goldSelected) {
//                                       showDialog(
//                                         context: context,
//                                         builder: (BuildContext context) {
//                                           return Dialog(
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(20),
//                                             ),
//                                             elevation: 0,
//                                             backgroundColor: Colors.transparent,
//                                             child: Container(
//                                               padding: const EdgeInsets.all(20),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.white,
//                                                 borderRadius:
//                                                     BorderRadius.circular(20),
//                                                 boxShadow: [
//                                                   BoxShadow(
//                                                     color: Colors.black
//                                                         .withOpacity(0.1),
//                                                     blurRadius: 10,
//                                                     offset: const Offset(0, 4),
//                                                   ),
//                                                 ],
//                                               ),
//                                               child: Column(
//                                                 mainAxisSize: MainAxisSize.min,
//                                                 children: [
//                                                   const Icon(
//                                                     Icons
//                                                         .credit_card_off_outlined,
//                                                     size: 48,
//                                                     color: Color(0xFF6366F1),
//                                                   ),
//                                                   const SizedBox(height: 16),
//                                                   Text(
//                                                     'No Credit Selected',
//                                                     style: TextStyle(
//                                                       fontSize: 24,
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                       color: Colors.grey[800],
//                                                     ),
//                                                   ),
//                                                   const SizedBox(height: 12),
//                                                   Text(
//                                                     'You have not selected any credit option. Do you want to proceed without using credits?',
//                                                     textAlign: TextAlign.center,
//                                                     style: TextStyle(
//                                                       fontSize: 16,
//                                                       color: Colors.grey[600],
//                                                     ),
//                                                   ),
//                                                   const SizedBox(height: 24),
//                                                   Row(
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment
//                                                             .spaceEvenly,
//                                                     children: [
//                                                       TextButton(
//                                                         onPressed:
//                                                             () => Navigator.pop(
//                                                               context,
//                                                             ),
//                                                         style: TextButton.styleFrom(
//                                                           padding:
//                                                               const EdgeInsets.symmetric(
//                                                                 horizontal: 24,
//                                                                 vertical: 12,
//                                                               ),
//                                                           shape: RoundedRectangleBorder(
//                                                             borderRadius:
//                                                                 BorderRadius.circular(
//                                                                   12,
//                                                                 ),
//                                                           ),
//                                                         ),
//                                                         child: Text(
//                                                           'Cancel',
//                                                           style: TextStyle(
//                                                             fontSize: 16,
//                                                             color:
//                                                                 Colors
//                                                                     .grey[700],
//                                                             fontWeight:
//                                                                 FontWeight.w600,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       ElevatedButton(
//                                                         onPressed: () {
//                                                           Navigator.pop(
//                                                             context,
//                                                           );
//                                                           Navigator.pop(
//                                                             context,
//                                                           );
//                                                           reservationController
//                                                               .createReservationWithData(
//                                                                 idUtilisateur:
//                                                                     userId,
//                                                                 idTerrain:
//                                                                     terrainId,
//                                                                 idPlageHoraire:
//                                                                     plageHoraireId,
//                                                                 date: date,
//                                                                 prixTotal:
//                                                                     prixTotal,
//                                                               );
//                                                           onSuccess();
//                                                         },
//                                                         style: ElevatedButton.styleFrom(
//                                                           backgroundColor:
//                                                               const Color(
//                                                                 0xFF6366F1,
//                                                               ),
//                                                           padding:
//                                                               const EdgeInsets.symmetric(
//                                                                 horizontal: 24,
//                                                                 vertical: 12,
//                                                               ),
//                                                           shape: RoundedRectangleBorder(
//                                                             borderRadius:
//                                                                 BorderRadius.circular(
//                                                                   12,
//                                                                 ),
//                                                           ),
//                                                           elevation: 0,
//                                                         ),
//                                                         child: const Text(
//                                                           'Confirm',
//                                                           style: TextStyle(
//                                                             fontSize: 16,
//                                                             color: Colors.white,
//                                                             fontWeight:
//                                                                 FontWeight.w600,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                       );
//                                     } else {
//                                       Navigator.pop(context);
//                                       reservationController
//                                           .createReservationWithData(
//                                             idUtilisateur: userId,
//                                             idTerrain: terrainId,
//                                             idPlageHoraire: plageHoraireId,
//                                             date: date,
//                                             prixTotal: prixTotal,
//                                           );
//                                       onSuccess();
//                                     }
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFF6366F1),
//                                     foregroundColor: Colors.white,
//                                     elevation: 0,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(16),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       if (silverSelected || goldSelected) ...[
//                                         const Icon(
//                                           Icons.check_circle_outline,
//                                           size: 20,
//                                         ),
//                                         const SizedBox(width: 8),
//                                       ],
//                                       Text(
//                                         (silverSelected || goldSelected)
//                                             ? 'CONFIRM RESERVATION'
//                                             : 'PROCEED WITHOUT CREDITS',
//                                         style: TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w600,
//                                           letterSpacing: 0.5,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.transparent,
//               foregroundColor: Colors.white,
//               side: const BorderSide(color: Colors.white, width: 2),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(28),
//               ),
//               elevation: 0,
//             ),
//             child: const Text(
//               'RÉSERVER',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 letterSpacing: 1.2,
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }

//   Widget _detailRow(String label, String value, {bool isTotal = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: const Color(0xFF8B8B9A),
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               color: isTotal ? const Color(0xFF6366F1) : Colors.white,
//               fontSize: isTotal ? 16 : 14,
//               fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomNav() {
//     return Container(
//       margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
//       decoration: BoxDecoration(
//         border: Border.all(color: AppTheme.secondaryTextColor, width: 1),
//         color: AppTheme.secondaryColor,
//         borderRadius: BorderRadius.circular(100),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(25),
//         child: SizedBox(
//           height: 70,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildNavItem(
//                 index: 0,
//                 currentIndex: controller.currentIndex,
//                 iconPath: AppImages.hisoty_icon,
//                 label: 'history',
//                 onTap: () => controller.changeTab(0),
//               ),
//               _buildNavItem(
//                 index: 1,
//                 currentIndex: controller.currentIndex,
//                 iconPath: AppImages.search_icons_btn_bar,
//                 label: 'search..',
//                 onTap: () => controller.changeTab(1),
//               ),
//               _buildNavItem(
//                 index: 2,
//                 currentIndex: controller.currentIndex,
//                 iconPath: AppImages.home_icon,
//                 label: 'home',
//                 onTap: () => controller.changeTab(2),
//               ),
//               _buildNavItem(
//                 index: 3,
//                 currentIndex: controller.currentIndex,
//                 iconPath: AppImages.settings_icon,
//                 label: 'settings',
//                 onTap: () => controller.changeTab(3),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem({
//     required int index,
//     required int currentIndex,
//     required String iconPath,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     final isSelected = currentIndex == index;

//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           // Handle navigation based on index
//           switch (index) {
//             case 0:
//               Get.to(() => HistoryScreen());
//               break;
//             case 1:
//               Get.to(() => Jpin_Matches());
//               break;
//             case 2:
//               Get.to(() => Clube_recomande_Page());
//               break;
//             case 3:
//               Get.to(() => SettingsScreen());
//               break;
//             default:
//               onTap(); // Fallback to provided onTap if index not handled
//           }
//         },
//         child: SizedBox(
//           height: 70,
//           child: Center(
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeInOut,
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: isSelected ? Colors.white : Colors.transparent,
//                   width: 0.4,
//                 ),
//                 color:
//                     isSelected
//                         ? Colors.grey.withOpacity(0.3)
//                         : Colors.transparent,
//                 shape: BoxShape.circle,
//               ),
//               child: SvgPicture.asset(iconPath, width: 28, height: 28),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   String? getValidImageUrl(Terrain terrain) {
//     if (terrain.imageUrl?.isNotEmpty == true &&
//         terrain.imageUrl!.startsWith('http')) {
//       // Optional: Filter out known test/placeholder domains to reduce 404 errors
//       final String url = terrain.imageUrl!;
//       if (url.contains('example.com')) {
//         return null; // Skip example.com URLs as they're typically not real
//       }
//       return url;
//     }
//     return null; // Return null for invalid URLs
//   }

//   // Simpler widget that handles errors gracefully without pre-checking URLs
//   Widget buildTerrainImage(
//     Terrain terrain, {
//     double height = 200,
//     double width = 300,
//   }) {
//     final String? imageUrl = getValidImageUrl(terrain);

//     if (imageUrl != null) {
//       // Valid HTTP URL - try to load it with error handling
//       return Container(
//         height: height,
//         width: width,
//         child: Image.network(
//           imageUrl,
//           height: height,
//           width: width,
//           fit: BoxFit.cover,
//           loadingBuilder: (context, child, loadingProgress) {
//             if (loadingProgress == null) return child;
//             return Container(
//               color: Colors.grey[200],
//               child: const Center(child: CircularProgressIndicator()),
//             );
//           },
//           errorBuilder: (context, error, stackTrace) {
//             // This will handle 404s, network errors, etc.
//             return _buildPlaceholder(height, width, terrain.name ?? 'No Name');
//           },
//           // Add these properties to handle network issues better
//           frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
//             if (wasSynchronouslyLoaded) return child;
//             return AnimatedOpacity(
//               opacity: frame == null ? 0 : 1,
//               duration: const Duration(seconds: 1),
//               curve: Curves.easeOut,
//               child: child,
//             );
//           },
//         ),
//       );
//     } else {
//       // No valid URL - show placeholder immediately
//       return _buildPlaceholder(height, width, terrain.name ?? 'No Name');
//     }
//   }

//   // Local placeholder widget (no internet required)
//   Widget _buildPlaceholder(double height, double width, String terrainName) {
//     return Container(
//       height: height,
//       width: width,
//       decoration: BoxDecoration(
//         color: Colors.grey[300],
//         border: Border.all(color: Colors.grey[400]!, width: 1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.image_not_supported, color: Colors.grey[600], size: 50),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Text(
//               terrainName,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildImageWithErrorHandling(
//     String imageUrl,
//     double height,
//     double width,
//   ) {
//     // Filter out example.com URLs to prevent 404s
//     if (imageUrl.contains('example.com')) {
//       return _buildPlaceholder(height, width, 'Image non disponible');
//     }

//     return Image.network(
//       imageUrl,
//       height: height,
//       width: width,
//       fit: BoxFit.cover,
//       loadingBuilder: (context, child, loadingProgress) {
//         if (loadingProgress == null) return child;
//         return Container(
//           height: height,
//           width: width,
//           color: Colors.grey[200],
//           child: const Center(child: CircularProgressIndicator()),
//         );
//       },
//       errorBuilder: (context, error, stackTrace) {
//         return _buildPlaceholder(height, width, 'Image non disponible');
//       },
//       frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
//         if (wasSynchronouslyLoaded) return child;
//         return AnimatedOpacity(
//           opacity: frame == null ? 0 : 1,
//           duration: const Duration(seconds: 1),
//           curve: Curves.easeOut,
//           child: child,
//         );
//       },
//     );
//   }
// }
