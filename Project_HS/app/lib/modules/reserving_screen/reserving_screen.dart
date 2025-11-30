import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ClubeSelct/clube_recomande.dart';
import 'package:app/modules/EnhancedHistoryScreen.dart';
import 'package:app/modules/Header/header_page.dart';
import 'package:app/modules/History_Page/history_Page.dart';
import 'package:app/modules/join_Pages/join_pages.dart';
import 'package:app/modules/reserving_screen/reserving_controller.dart';
import 'package:app/modules/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ReservingScreen extends StatefulWidget {
  const ReservingScreen({super.key});

  @override
  State<ReservingScreen> createState() => _ReservingScreenState();
}

class _ReservingScreenState extends State<ReservingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ReservingController controller = Get.put(ReservingController());

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Image.asset(
            AppImages.home_background,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
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
                      SizedBox(height: context.height * 0.08),
                      _buildTitleSection(context),
                      SizedBox(height: context.height * 0.03),
                      Expanded(child: _buildSelectionButtons(context)),
                      SizedBox(height: context.height * 0.04),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,

      bottomNavigationBar: GetBuilder<ReservingController>(
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          AppImages.logo_png,
          width: context.width * 0.2,
          height: context.width * 0.2,
          fit: BoxFit.contain,
        ),
        Row(
          children: [
            // Obx(() => Container(
            //       padding: EdgeInsets.symmetric(horizontal: context.width * 0.02),
            //       decoration: BoxDecoration(
            //         color: AppTheme.cardColor.withOpacity(0.9),
            //         borderRadius: BorderRadius.circular(25),
            //         border: Border.all(
            //           color: AppTheme.borderColor,
            //           width: 1.5,
            //         ),
            //         boxShadow: [
            //           BoxShadow(
            //             color: AppTheme.overlayColor.withOpacity(0.3),
            //             blurRadius: 8,
            //             offset: const Offset(0, 3),
            //           ),
            //         ],
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Image.asset(
            //             AppImages.coin_icon,
            //             height: context.height * 0.06,
            //             width: context.width * 0.06,
            //           ),
            //           SizedBox(width: context.width * 0.02),
            //           Text(
            //             '${controller.userBalance.value.toStringAsFixed(2)} C',
            //             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            //                   color: AppTheme.primaryTextColor,
            //                   fontWeight: FontWeight.w600,
            //                 ),
            //           ),
            //         ],
            //       ),
            //     )),
            SizedBox(width: context.width * 0.03),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.overlayColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: AppTheme.primaryTextColor,
                    child: null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      children: [
        Text(
          "Réservation de terrain",
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppTheme.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.start,
        ),
        SizedBox(height: context.height * 0.02),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                "Veuillez choisir dans quel centre vous voulez réserver un terrain",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.secondaryTextColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionButtons(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // _buildSelectionButton(
          //   context: context,
          //   icon: AppImages.soccer_icon,
          //   title: "Central Soccer",
          //   subtitle: "Terrain de football professionnel",
          //   onTap: () => Navigator.pushNamed(context, '/soocer'),
          // ),
          SizedBox(height: context.height * 0.03),
          _buildSelectionButton(
            context: context,
            icon: AppImages.padel_icon,
            title: "Central Padel",
            subtitle: "Court de padel moderne",
            onTap: () => Get.toNamed('/padel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionButton({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        // height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardColor.withOpacity(0.8),
              AppTheme.secondaryColor.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.overlayColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(55),
              // decoration: BoxDecoration(
              //   color: AppTheme.accentColor,
              //   borderRadius: BorderRadius.circular(16),
              //   border: Border.all(color: AppTheme.borderColor, width: 1),
              // ),
              child: Image.asset(
                icon,
                height: context.height * 0.07,
                width: context.height * 0.07,
              ),
            ),
            SizedBox(width: context.width * 0.05),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
}
