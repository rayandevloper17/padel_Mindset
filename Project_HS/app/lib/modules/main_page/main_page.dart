import 'package:app/modules/ClubeSelct/clube_recomande.dart';
import 'package:app/modules/EnhancedHistoryScreen.dart';
import 'package:app/modules/History_Page/history_Page.dart';
import 'package:app/modules/Padel/match_prv_page.dart';
import 'package:app/modules/join_Pages/join_pages.dart';
import 'package:app/modules/main_page/controller/home_controller.dart';
import 'package:app/modules/reserveing/FieldReservationController.dart';
import 'package:app/modules/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class Hame_page extends StatelessWidget {
  Hame_page({super.key});

  final HomeController controller = Get.put(HomeController());
  final FieldReservationController fieldController = Get.put(
    FieldReservationController(),
  );

  final List<Widget> _pages = [
    EnhancedHistoryScreen(),

    // Jpin_Matches(),
    Clube_recomande_Page(),

    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<HomeController>(
        builder: (controller) => Clube_recomande_Page(),
      ),
      extendBody: true,
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
}
