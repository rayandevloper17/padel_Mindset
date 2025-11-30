import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ClubeSelct/clube_recomande.dart';
import 'package:app/modules/EnhancedHistoryScreen.dart';
import 'package:app/modules/Header/header_page.dart';
import 'package:app/modules/History_Page/history_Page.dart';
import 'package:app/modules/SoocerScreen/controller.dart';
import 'package:app/modules/join_Pages/join_pages.dart';
import 'package:app/modules/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class SucesPage extends StatefulWidget {
  const SucesPage({super.key});

  @override
  State<SucesPage> createState() => _SucesPageState();
}

class _SucesPageState extends State<SucesPage> {
  final Scoorcontroller controller = Get.put(Scoorcontroller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.home_background),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              CreditHeader(ishowing: false),
              Container(
                margin: const EdgeInsets.only(top: 50),
                alignment: Alignment.topCenter,
                child: SvgPicture.asset(
                  AppImages
                      .truepageicon, // Replace with your desired SVG icon path
                  width: 110,
                  height: 110,
                ),
              ),
              SizedBox(height: 15),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "RESERVATION EFFECTUE \nAVEC SUCCES",
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 15),
                    Text(
                      "Pour consulter, veuillez vérifier \nvotre historique de réservations",
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomNav(),
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
}
