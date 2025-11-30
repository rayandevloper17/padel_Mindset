import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ClubeSelct/clube_recomande.dart';
import 'package:app/modules/EnhancedHistoryScreen.dart';
import 'package:app/modules/Header/header_page.dart';
import 'package:app/modules/History_Page/history_Page.dart';
import 'package:app/modules/join_Pages/join_pages.dart';
import 'package:app/modules/ProfileView/controller_profile_page.dart';
import 'package:app/modules/settings/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final SettingsController controller = Get.put(SettingsController());

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
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(AppImages.home_background, fit: BoxFit.cover),
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
              ],
            ),
          ),
          // Content
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
                      SizedBox(height: context.height * 0.05),
                      Expanded(child: _buildSettingsOptions(context)),
                      SizedBox(height: context.height * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: GetBuilder<SettingsController>(
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
                      currentIndex: controller.currentIndex ?? 0,
                      iconPath: AppImages.hisoty_icon,
                      label: 'history',
                      onTap: () => controller.changeTab(0),
                    ),
                    _buildNavItem(
                      index: 1,
                      currentIndex: controller.currentIndex ?? 0,
                      iconPath: AppImages.search_icons_btn_bar,
                      label: 'search..',
                      onTap: () => controller.changeTab(1),
                    ),
                    _buildNavItem(
                      index: 2,
                      currentIndex: controller.currentIndex ?? 0,
                      iconPath: AppImages.home_icon,
                      label: 'home',
                      onTap: () => controller.changeTab(2),
                    ),
                    _buildNavItem(
                      index: 3,
                      currentIndex: controller.currentIndex ?? 0,
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
    final ProfileController profileController = Get.put(ProfileController());

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
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.width * 0.02),
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.overlayColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppImages.coin_icon,
                    height: context.height * 0.06,
                    width: context.width * 0.06,
                  ),
                  SizedBox(width: context.width * 0.02),
                  Obx(() {
                    double userBalance = double.tryParse(profileController.creditBalance.value) ?? 0.0;
                    return Text(
                      '${userBalance.toStringAsFixed(2)} C',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(width: context.width * 0.03),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
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
                    color: AppTheme.accentColor,
                    child: Icon(
                      Icons.person,
                      color: AppTheme.secondaryTextColor,
                      size: 28,
                    ),
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
          "PARAMÈTRES",
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppTheme.primaryTextColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.height * 0.03),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
          ),
          child: Text(
            "Configurer ici vos paramètres, préférences, ou vous pouvez vous déconnecter.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.secondaryTextColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOptions(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // _buildSettingsOption(
          //   context: context,
          //   icon: Icons.visibility,
          //   title: "Choisir Thème",
          //   hasDropdown: true,
          //   onTap: () {
          //     // TODO: Handle theme switch
          //   },
          // ),
          SizedBox(height: context.height * 0.02),
          _buildSettingsOption(
            context: context,
            icon: Icons.lock,
            title: "Confidentialité et sécurité",
            hasDropdown: true,
            onTap: () {
              // TODO: Navigate to privacy settings
            },
          ),
          SizedBox(height: context.height * 0.02),
          _buildSettingsOption(
            context: context,
            icon: Icons.info,
            title: "À propos",
            hasDropdown: true,
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.borderColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              AppImages.logo_png,
                              width: 80,
                              height: 80,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Central Club',
                            style: TextStyle(
                              color: AppTheme.primaryTextColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Votre application de réservation de terrains de sport préférée. Rejoignez une communauté passionnée et réservez facilement vos sessions sportives.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialButton(Icons.language, 'Website'),
                              const SizedBox(width: 16),
                              _buildSocialButton(Icons.mail, 'Contact'),
                              const SizedBox(width: 16),
                              _buildSocialButton(Icons.privacy_tip, 'Privacy'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Fermer',
                                style: TextStyle(
                                  color: AppTheme.primaryTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          SizedBox(height: context.height * 0.02),
          _buildSettingsOption(
            context: context,
            icon: Icons.logout,
            title: "Déconnexion",
            hasDropdown: false,
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.borderColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 50,
                            color: AppTheme.primaryTextColor,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Déconnexion',
                            style: TextStyle(
                              color: AppTheme.primaryTextColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Êtes-vous sûr de vouloir vous déconnecter ?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(
                                    color: AppTheme.secondaryTextColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Déconnecter',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool hasDropdown,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.overlayColor.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryTextColor, size: 22),
              ),
              SizedBox(width: context.width * 0.04),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryTextColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (hasDropdown)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppTheme.primaryTextColor.withOpacity(0.7),
                    size: 16,
                  ),
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
}

Widget _buildSocialButton(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.primaryColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppTheme.primaryTextColor, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 12),
        ),
      ],
    ),
  );
}
