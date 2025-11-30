import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/global/services/notification_service.dart';
import 'package:app/global/services/email_validation_service.dart';
import 'package:app/global/services/password_validation_service.dart';
import 'package:app/global/constants/images.dart';
import 'package:app/modules/auth/login/login_main_page.dart';
import 'package:app/modules/auth/signup/controller.dart';

/// Modern and professional signup page with enhanced user experience
/// Features:
/// - Real-time email validation with loading indicator
/// - Modern notification system
/// - Professional loading states
/// - Clean French translations
/// - Responsive design
class SignupScreend extends StatefulWidget {
  const SignupScreend({super.key});

  @override
  State<SignupScreend> createState() => _SignupScreendState();
}

class _SignupScreendState extends State<SignupScreend> {
  // Controllers
  final SignControllerGetx _signupController = Get.put(SignControllerGetx());
  final EmailValidationService _emailValidationService = Get.put(EmailValidationService());
  final PasswordValidationService _passwordValidationService = Get.put(PasswordValidationService());
  
  // Form controllers
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _dateNaissanceController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables
  DateTime? _selectedDate;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _telephoneNormalise;

  // Validation error messages
  String? _nomError;
  String? _prenomError;
  String? _dateNaissanceError;
  String? _telephoneError;
  String? _emailError;
  String? _motDePasseError;

  @override
  void initState() {
    super.initState();
    // Add email validation listener
    _emailController.addListener(_onEmailChanged);
    // Add password validation listener
    _motDePasseController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nomController.dispose();
    _prenomController.dispose();
    _dateNaissanceController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  /// Handle email changes for real-time validation
  void _onEmailChanged() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && _isValidEmail(email)) {
      _emailValidationService.checkEmailAvailability(email);
    }
  }

  /// Handle password changes for real-time validation
  void _onPasswordChanged() {
    final password = _motDePasseController.text;
    _passwordValidationService.validatePassword(password);
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Validate Algerian phone number
  bool _isValidAlgerianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (RegExp(r'^0[567]\d{8}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^\+213[567]\d{8}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^213[567]\d{8}$').hasMatch(cleaned)) return true;
    return false;
  }

  /// Normalize phone number to backend format
  String _normalizeAlgerianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (RegExp(r'^0[567]\d{8}$').hasMatch(cleaned)) {
      return cleaned; // Already local format
    }
    if (RegExp(r'^\+213[567]\d{8}$').hasMatch(cleaned)) {
      return cleaned; // Already international with +
    }
    if (RegExp(r'^213[567]\d{8}$').hasMatch(cleaned)) {
      return '+$cleaned'; // Add plus
    }
    if (RegExp(r'^[567]\d{8}$').hasMatch(cleaned)) {
      return '0$cleaned'; // Normalize 9-digit local
    }
    return cleaned;
  }

  /// Validate all form fields
  bool _validateForm() {
    setState(() {
      _nomError = null;
      _prenomError = null;
      _dateNaissanceError = null;
      _telephoneError = null;
      _emailError = null;
      _motDePasseError = null;
    });

    bool isValid = true;

    // Validate nom
    if (_nomController.text.trim().isEmpty) {
      _nomError = 'Le nom est requis';
      isValid = false;
    } else if (_nomController.text.trim().length < 2) {
      _nomError = 'Le nom doit contenir au moins 2 caractères';
      isValid = false;
    }

    // Validate prenom
    if (_prenomController.text.trim().isEmpty) {
      _prenomError = 'Le prénom est requis';
      isValid = false;
    } else if (_prenomController.text.trim().length < 2) {
      _prenomError = 'Le prénom doit contenir au moins 2 caractères';
      isValid = false;
    }

    // Validate date de naissance
    if (_selectedDate == null) {
      _dateNaissanceError = 'La date de naissance est requise';
      isValid = false;
    } else {
      final now = DateTime.now();
      int age = now.year - _selectedDate!.year;
      if (now.month < _selectedDate!.month ||
          (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
        age--;
      }
      if (age < 13) {
        _dateNaissanceError = 'Vous devez avoir au moins 13 ans';
        isValid = false;
      }
    }

    // Validate telephone
    if (_telephoneController.text.trim().isEmpty) {
      _telephoneError = 'Le numéro de téléphone est requis';
      isValid = false;
    } else if (!_isValidAlgerianPhone(_telephoneController.text.trim())) {
      _telephoneError = 'Numéro invalide. Format: 05xxxxxxxx, 06xxxxxxxx, ou 07xxxxxxxx';
      isValid = false;
    }

    // Validate email
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailError = 'L\'email est requis';
      isValid = false;
    } else if (!_isValidEmail(email)) {
      _emailError = 'Veuillez entrer un email valide';
      isValid = false;
    } else if (!_emailValidationService.isEmailAvailable.value) {
      _emailError = 'Cet email est déjà utilisé';
      isValid = false;
    }

    // Validate mot de passe (real-time validation with detailed requirements)
    if (_motDePasseController.text.trim().isEmpty) {
      _motDePasseError = 'Le mot de passe est requis';
      isValid = false;
    } else if (!_passwordValidationService.isPasswordValid.value) {
      _motDePasseError = 'Le mot de passe ne répond pas aux critères de sécurité';
      isValid = false;
    }

    // Normalize phone number
    if (isValid) {
      _telephoneNormalise = _normalizeAlgerianPhone(_telephoneController.text.trim());
    }

    setState(() {});
    return isValid;
  }

  /// Handle signup submission
  Future<void> _handleSignup() async {
    if (!_validateForm()) {
      NotificationService.showWarning(
        title: 'Formulaire incomplet',
        message: 'Veuillez corriger les erreurs dans le formulaire',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'numero_telephone': _telephoneNormalise,
        'email': _emailController.text.trim(),
        'mot_de_passe': _motDePasseController.text.trim(),
      };

      final user = await _signupController.createUser(userData);

      if (user != null) {
        NotificationService.showSuccess(
          title: 'Compte créé',
          message: 'Votre compte a été créé avec succès!',
        );
        Get.offAll(() =>  LogIn_Page());
      } else {
        // Error message is already handled by controller
        final errorMessage = _signupController.errorMessage.value;
        NotificationService.showError(
          title: 'Erreur d\'inscription',
          message: errorMessage.isNotEmpty ? errorMessage : 'Une erreur s\'est produite lors de la création du compte',
        );
      }
    } catch (e) {
      developer.log('❌ Signup error: $e', name: 'Signup');
      NotificationService.showConnectionFailed(
        message: 'Impossible de créer le compte. Veuillez réessayer.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show date picker for birth date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.white,
              surface: Colors.grey[800]!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateNaissanceController.text = "${picked.day.toString().padLeft(2, '0')} / ${picked.month.toString().padLeft(2, '0')} / ${picked.year}";
        _dateNaissanceError = null;
      });
    }
  }

  /// Build email validation widget
  Widget _buildEmailValidationWidget() {
    return Obx(() {
      if (_emailValidationService.isCheckingEmail.value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
              ),
              const SizedBox(width: 8),
              Text(
                'Vérification de l\'email...',
                style: TextStyle(
                  color: Colors.orange.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      if (_emailValidationService.emailValidationMessage.value.isNotEmpty) {
        final color = _emailValidationService.getValidationColor();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                _emailValidationService.getValidationIcon(),
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _emailValidationService.emailValidationMessage.value,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }

  /// Build password validation widget with strength indicator
  Widget _buildPasswordValidationWidget() {
    final password = _motDePasseController.text;
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Password strength indicator
          Row(
            children: [
              Text(
                'Force du mot de passe: ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Obx(() => Text(
                _passwordValidationService.getStrengthText(),
                style: TextStyle(
                  color: _passwordValidationService.getStrengthColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ],
          ),
          SizedBox(height: 8),
          // Requirements checklist
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordRequirement(
                'Au moins 10 caractères',
                _passwordValidationService.hasMinLength.value,
              ),
              SizedBox(height: 4),
              _buildPasswordRequirement(
                'Au moins une lettre majuscule (A-Z)',
                _passwordValidationService.hasUpperCaseChar.value,
              ),
              SizedBox(height: 4),
              _buildPasswordRequirement(
                'Au moins une lettre minuscule (a-z)',
                _passwordValidationService.hasLowerCaseChar.value,
              ),
              SizedBox(height: 4),
              _buildPasswordRequirement(
                'Au moins un chiffre (0-9)',
                _passwordValidationService.hasNumber.value,
              ),
              SizedBox(height: 4),
              _buildPasswordRequirement(
                'Au moins un caractère spécial (!@#\$%^&*(),.?:{}|<>)',
                _passwordValidationService.hasSpecialChar.value,
              ),
            ],
          )),
        ],
      ),
    );
  }

  /// Build individual password requirement item
  Widget _buildPasswordRequirement(String text, bool isFulfilled) {
    return Row(
      children: [
        Icon(
          isFulfilled ? Icons.check_circle : Icons.circle_outlined,
          color: isFulfilled ? Colors.green : Colors.grey,
          size: 14,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isFulfilled 
              ? Colors.green.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: isFulfilled ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(AppImages.auth_background, fit: BoxFit.cover),
            ),
            
            // Content
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.width * 0.08),
                child: Column(
                  children: [
                    SizedBox(height: context.height * 0.06),
                    
                    // Logo
                    Image.asset(
                      AppImages.logo_png,
                      width: context.width * 0.2,
                      height: context.width * 0.2,
                    ),
                    
                    SizedBox(height: context.height * 0.02),
                    
                    // Title
                    Text(
                      "Créer un compte",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    SizedBox(height: context.height * 0.04),
                    
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nom
                          _buildLabel("Nom"),
                          _buildTextField(
                            controller: _nomController,
                            hint: "Entrez votre nom",
                            error: _nomError,
                            icon: Icons.person_outline,
                          ),
                          SizedBox(height: context.height * 0.02),
                          
                          // Prénom
                          _buildLabel("Prénom"),
                          _buildTextField(
                            controller: _prenomController,
                            hint: "Entrez votre prénom",
                            error: _prenomError,
                            icon: Icons.person_outline,
                          ),
                          SizedBox(height: context.height * 0.02),
                          
                          // Date de naissance
                          _buildLabel("Date de naissance"),
                          _buildDateField(),
                          SizedBox(height: context.height * 0.02),
                          
                          // Téléphone
                          _buildLabel("Numéro de téléphone"),
                          _buildTextField(
                            controller: _telephoneController,
                            hint: "Entrez votre numéro (05xxxxxxxx)",
                            error: _telephoneError,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: context.height * 0.02),
                          
                          // Email
                          _buildLabel("Email"),
                          _buildEmailField(),
                          SizedBox(height: 8),
                          _buildEmailValidationWidget(),
                          SizedBox(height: context.height * 0.02),
                          
                          // Mot de passe
                          _buildLabel("Mot de passe"),
                          _buildPasswordField(),
                          SizedBox(height: 8),
                          _buildPasswordValidationWidget(),
                          SizedBox(height: context.height * 0.04),
                          
                          // Submit button
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: context.height * 0.03),
                    
                    // Login link
                    _buildLoginLink(),
                    
                    SizedBox(height: context.height * 0.03),
                  ],
                ),
              ),
            ),
            
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build form label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Build text field with modern design
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? error,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error != null ? Colors.red : Colors.white24,
          width: error != null ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white60, fontSize: 16),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// Build date field
  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800]?.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dateNaissanceError != null ? Colors.red : Colors.white24,
            width: _dateNaissanceError != null ? 2 : 1,
          ),
        ),
        child: AbsorbPointer(
          child: TextField(
            controller: _dateNaissanceController,
            style: TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: "JJ / MM / AAAA",
              hintStyle: TextStyle(color: Colors.white60, fontSize: 16),
              prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  /// Build email field
  Widget _buildEmailField() {
    return _buildTextField(
      controller: _emailController,
      hint: "Entrez votre email",
      error: _emailError,
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
    );
  }

  /// Build password field
  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _motDePasseController,
      hint: "Entrez votre mot de passe",
      error: _motDePasseError,
      icon: Icons.lock_outline,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: Colors.white70,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }

  /// Build submit button
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                "Créer mon compte",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /// Build login link
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Vous avez déjà un compte ? ",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Get.to(() => LogIn_Page());
          },
          child: Text(
            "Se connecter",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}