import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';

class LogInController extends GetxController {
  late final AuthController _authController;

  final email = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize auth controller when the controller is ready
    _authController = Get.find<AuthController>();
  }

  void setEmail(String value) => email.value = value;
  void setPassword(String value) => password.value = value;

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validate inputs
      if (email.trim().isEmpty || password.trim().isEmpty) {
        errorMessage.value = 'Veuillez remplir tous les champs';
        return false;
      }

      final success = await _authController.login(
        email.trim(),
        password,
      );

      if (success) {
        return true;
      } else {
        errorMessage.value = 'Email ou mot de passe incorrect';
        return false;
      }
    } catch (e) {
      // Handle different types of errors with clean messages
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('401') || errorString.contains('unauthorized')) {
        errorMessage.value = 'Email ou mot de passe incorrect';
      } else if (errorString.contains('403') || errorString.contains('forbidden')) {
        errorMessage.value = 'Accès refusé. Vérifiez vos identifiants.';
      } else if (errorString.contains('404') || errorString.contains('not found')) {
        errorMessage.value = 'Service temporairement indisponible';
      } else if (errorString.contains('network') || 
                 errorString.contains('connection') || 
                 errorString.contains('timeout')) {
        errorMessage.value = 'Erreur de connexion. Vérifiez votre réseau.';
      } else if (errorString.contains('500') || errorString.contains('server')) {
        errorMessage.value = 'Erreur serveur. Réessayez plus tard.';
      } else if (errorString.contains('dioerror') || errorString.contains('dio')) {
        // Handle Dio-specific errors
        if (errorString.contains('connection')) {
          errorMessage.value = 'Impossible de se connecter au serveur';
        } else if (errorString.contains('timeout')) {
          errorMessage.value = 'Délai d\'attente dépassé. Réessayez.';
        } else {
          errorMessage.value = 'Erreur de connexion au serveur';
        }
      } else {
        // Generic error message for unexpected errors
        errorMessage.value = 'Une erreur est survenue. Réessayez.';
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authController.logout();
  }
}
