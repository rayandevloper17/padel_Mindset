import 'package:app/modules/ClubeSelct/clube_recomande.dart';
import 'package:app/modules/EnhancedHistoryScreen.dart';
import 'package:app/modules/HistoryDetailsView/history_details_view.dart';
import 'package:app/modules/History_Page/history_Page.dart';
import 'package:app/modules/OnboardingView/onbouarding_view.dart';
import 'package:app/modules/Padel/Central_padel_page.dart';
import 'package:app/modules/Padel/participant_page.dart';
import 'package:app/modules/Padel/match_prv_page.dart';
import 'package:app/modules/ProfileView/profile_view.dart';
import 'package:app/modules/auth/signup/sign_up_page.dart';
import 'package:app/modules/auth/login/login_main_page.dart';
import 'package:app/modules/auth/signup/signup_screen.dart';
import 'package:app/modules/join_Pages/join_pages.dart';
import 'package:app/modules/main_page/main_page.dart';
import 'package:app/modules/suggestpage/sugest_page.dart';
import 'package:app/controllers/auth_controller.dart';
import 'package:app/pages/token_test_page.dart';
import 'package:app/modules/auth/login/login_binding.dart';
import 'package:app/services/api_service.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const String DEFAULT_ROUTE = Routes.SUGGEST;

  /// Returns initial route based on login status
  static Future<String> getInitialRoute() async {
    try {
      // Try to get the auth controller (it should be initialized by now)
      final authController = Get.find<AuthController>();
      await authController.checkLoginStatus();

      if (authController.isLoggedIn.value) {
        return Routes.CLUBE_RECOMANDE;
      } else {
        return Routes.LOGIN;
      }
    } catch (e) {
      // Fallback to old method if auth controller is not available
      final token = await ApiService.instance.getValidAccessToken();

      if (token != null && token.isNotEmpty) {
        return Routes.CLUBE_RECOMANDE;
      } else {
        return Routes.LOGIN;
      }
    }
  }

  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => LogIn_Page(),
      binding: LogInBinding(),
    ),
    GetPage(name: Routes.HOME, page: () => Hame_page()),
    GetPage(name: Routes.SIGNUP, page: () => const SignupScreend()),
    GetPage(
      name: Routes.HISTORY_DETAILS,
      page: () => HistoryDetailsScreen(reservationId: ''),
    ),
    GetPage(name: Routes.PROFILE, page: () => ProfileScreen()),
    GetPage(name: Routes.ONBOARDING, page: () => OnboardingScreen()),
    GetPage(name: Routes.PADEL, page: () => PadelScreen()),
    // GetPage(name: Routes.SOOCER, page: () => SoocerScreen()),
    GetPage(name: Routes.HISTORY, page: () => EnhancedHistoryScreen()),
    GetPage(name: Routes.RESERVING_Match, page: () => Jpin_Matches()),
    GetPage(name: Routes.SUGGEST, page: () => SuggestPage()),
    GetPage(name: Routes.CLUBE_RECOMANDE, page: () => Clube_recomande_Page()),
    GetPage(name: Routes.JOIN_MATCH, page: () => MatchScreen()),
    GetPage(name: Routes.TOKEN_TEST, page: () => const TokenTestPage()),
    GetPage(name: Routes.MATCH_PRV, page: () => const MatchPrvPage()),
  ];
}
