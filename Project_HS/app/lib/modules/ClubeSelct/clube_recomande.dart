// Removed 'dart:ffi' import for web compatibility.

import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ClubeSelct/tab_selcet_clube_page.dart';
import 'package:app/modules/ClubeSelct/tabe_sugestion_page.dart';
import 'package:app/modules/EnhancedHistoryScreen.dart';
import 'package:app/modules/Header/header_page.dart';
import 'package:app/modules/History_Page/history_Page.dart';
import 'package:app/modules/Padel/info_clube.dart';
import 'package:app/modules/Padel/match_prv_page.dart';
import 'package:app/modules/SoocerScreen/controller.dart';
import 'package:app/modules/join_Pages/join_pages.dart';
import 'package:app/modules/reserving_screen/reserving_screen.dart';
import 'package:app/modules/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class Clube_recomande_Page extends StatefulWidget {
  const Clube_recomande_Page({super.key});

  @override
  State<Clube_recomande_Page> createState() => _Clube_recomande_PageState();
}

class _Clube_recomande_PageState extends State<Clube_recomande_Page> {
  final Scoorcontroller controller = Get.put(Scoorcontroller());

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(screenSize.height * 0.18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                decoration: BoxDecoration(color: Colors.transparent),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: screenSize.height * 0.04),
                      CreditHeader(ishowing: true),
                      // _buildHeader(context),
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
                            Tab(text: 'SUGGESTIONS'),
                            Tab(text: 'CHOISIR UN CLUB'),
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
            TabeSugestionPage(),

            // Reservations Tab Content
            TabSelectClubePage(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
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
              Get.to(() => MatchPrvPage());
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
}
