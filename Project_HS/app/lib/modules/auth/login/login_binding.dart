import 'package:app/modules/auth/login/login_controller.dart';
import 'package:app/bindings/app_binding.dart';
import 'package:app/services/api_service.dart';
import 'package:get/get.dart';

class LogInBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure core services are initialized first
    if (!Get.isRegistered<ApiService>()) {
      DependencyInjection.init();
    }

    Get.lazyPut<LogInController>(() => LogInController());
  }
}
