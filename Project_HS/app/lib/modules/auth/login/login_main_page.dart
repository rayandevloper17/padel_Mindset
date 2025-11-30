import 'package:app/global/constants/const/text_faild.dart';
import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/auth/login/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../global/controllers/theme_controller.dart';

class LogIn_Page extends StatefulWidget {
  LogIn_Page({super.key});

  @override
  State<LogIn_Page> createState() => _LogIn_PageState();
}

class _LogIn_PageState extends State<LogIn_Page> {
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // State
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  
  final LogInController loginController = Get.put(LogInController());

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Get values from controllers
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic validation
    if (email.isEmpty) {
      setState(() {
        _emailError = "Veuillez entrer votre email";
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = "Veuillez entrer votre mot de passe";
      });
      return;
    }

    if (!GetUtils.isEmail(email)) {
      setState(() {
        _emailError = "Veuillez entrer un email valide";
      });
      return;
    }

    // Call login controller
    final success = await loginController.login(email, password);

    // Handle success or error
    if (success) {
      // Navigate to homepage on successful login
      Get.offAllNamed('/home');
      
      // Show success message
      Get.snackbar(
        'Succès',
        'Connexion réussie!',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      );
    } else if (loginController.errorMessage.value.isNotEmpty) {
      // Show error message
      Get.snackbar(
        'Erreur de connexion',
        loginController.errorMessage.value,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: EdgeInsets.all(16),
      );
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? errorText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: errorText != null ? Colors.red : Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          errorText: errorText,
          errorStyle: TextStyle(color: Colors.red[300], fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildModernLoginButton() {
    return Obx(() => Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: loginController.isLoading.value ? null : _handleLogin,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: loginController.isLoading.value
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                "SE CONNECTER",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    ));
  }

  Widget _buildModernDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "ou",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSocialButtons() {
    return Column(
      children: [
        _buildSocialButton(
          icon: SvgPicture.asset(
            AppImages.google_icon,
            height: 20,
            width: 20,
          ),
          text: "Continuer avec Google",
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          onPressed: () {
            // Handle Google Login
            Get.snackbar(
              'Google Login',
              'Fonctionnalité en cours de développement',
              backgroundColor: Colors.blue.withValues(alpha: 0.8),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              borderRadius: 12,
              margin: EdgeInsets.all(16),
            );
          },
        ),
        SizedBox(height: 12),
        _buildSocialButton(
          icon: Icon(Icons.apple, size: 24, color: Colors.white),
          text: "Continuer avec Apple",
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          onPressed: () {
            // Handle Apple Login
            Get.snackbar(
              'Apple Login',
              'Fonctionnalité en cours de développement',
              backgroundColor: Colors.blue.withValues(alpha: 0.8),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              borderRadius: 12,
              margin: EdgeInsets.all(16),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Pas encore de compte ? ",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/signup');
          },
          child: Text(
            "S'inscrire",
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.auth_background),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Image.asset(
                        AppImages.logo_png,
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Title
                    Text(
                      "Connexion",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Bienvenue de retour",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    // Email Field
                    _buildModernTextField(
                      controller: _emailController,
                      hint: "Adresse email",
                      icon: Icons.email_outlined,
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    
                    // Password Field
                    _buildModernTextField(
                      controller: _passwordController,
                      hint: "Mot de passe",
                      icon: Icons.lock_outline,
                      errorText: _passwordError,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Login Button
                    _buildModernLoginButton(),
                    SizedBox(height: 24),
                    
                    // Divider
                    _buildModernDivider(),
                    SizedBox(height: 24),
                    
                    // Social Login Buttons
                    _buildModernSocialButtons(),
                    SizedBox(height: 24),
                    
                    // Sign Up Link
                    _buildSignUpLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
