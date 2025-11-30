import 'package:get/get.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/services/api_service.dart';

class SplashController extends GetxController {

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await ApiService.instance.getValidAccessToken();

    if (token != null && token.isNotEmpty) {
      print('✅ Token found: $token');
      Get.offAllNamed(Routes.HOME); // go to home
    } else {
      print('🚫 No token found');
      Get.offAllNamed(AppPages.DEFAULT_ROUTE); // go to onboarding/login
    }
  }
}
