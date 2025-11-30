import 'package:get/get.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';
import '../modules/rating_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize API Service first (as a service that persists)
    Get.put<ApiService>(ApiService(), permanent: true);

    // Initialize Auth Controller first (RatingController references AuthController)
    Get.put<AuthController>(AuthController(), permanent: true);

    // Initialize Rating Controller after AuthController
    Get.put<RatingController>(RatingController(), permanent: true);
  }
}

// Alternative way to initialize services
class DependencyInjection {
  static void init() {
    Get.put<ApiService>(ApiService(), permanent: true);
    // Register AuthController first so RatingController can resolve it
    Get.put<AuthController>(AuthController(), permanent: true);
    // Then register RatingController
    Get.put<RatingController>(RatingController(), permanent: true);
  }
}
