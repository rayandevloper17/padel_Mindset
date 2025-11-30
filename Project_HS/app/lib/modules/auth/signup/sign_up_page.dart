import 'package:app/global/constants/const/text_faild.dart';
import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/auth/login/login_main_page.dart';
import 'package:app/modules/auth/signup/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final SignControllerGetx _signupController = Get.put(SignControllerGetx());
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _prenomeController = TextEditingController();

  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? numeroTelephone;

  String? _fullNameError;
  String? _birthdayError;
  String? _phoneNumberError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _prenomeController.dispose();
    _birthdayController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate Algerian phone numbers: 0XXXXXXXXX, +213XXXXXXXXX, or 213XXXXXXXXX
  bool _isValidAlgerianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (RegExp(r'^0[567]\d{8}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^\+213[567]\d{8}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^213[567]\d{8}$').hasMatch(cleaned)) return true;
    return false;
  }

  // Normalize various inputs to a backend-friendly format
  // Rules: keep leading 0 local format, convert 213XXXXXXXXX -> +213XXXXXXXXX, prefix 0 for 9-digit starting [5-7]
  String _normalizeAlgerianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (RegExp(r'^0[567]\d{8}$').hasMatch(cleaned)) {
      return cleaned; // already local format
    }
    if (RegExp(r'^\+213[567]\d{8}$').hasMatch(cleaned)) {
      return cleaned; // already international with +
    }
    if (RegExp(r'^213[567]\d{8}$').hasMatch(cleaned)) {
      return '+$cleaned'; // add plus to match backend regex
    }
    if (RegExp(r'^[567]\d{8}$').hasMatch(cleaned)) {
      return '0$cleaned'; // normalize 9-digit local into 0XXXXXXXXX
    }
    return cleaned; // fallback, will be rejected by validator
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  bool _validateForm() {
    setState(() {
      _fullNameError = null;
      _birthdayError = null;
      _phoneNumberError = null;
      _emailError = null;
      _passwordError = null;
    });

    bool isValid = true;

    if (_fullNameController.text.trim().isEmpty) {
      _fullNameError = "Le nom complet est requis";
      isValid = false;
    } else if (_fullNameController.text.trim().length < 2) {
      _fullNameError = "Le nom doit contenir au moins 2 caractères";
      isValid = false;
    }

    if (_prenomeController.text.trim().isEmpty) {
      _fullNameError = "Le prenome complet est requis";
      isValid = false;
    } else if (_fullNameController.text.trim().length < 2) {
      _fullNameError = "Le prenome doit contenir au moins 2 caractères";
      isValid = false;
    }

    if (_birthdayController.text.trim().isEmpty || _selectedDate == null) {
      _birthdayError = "La date de naissance est requise";
      isValid = false;
    } else {
      final now = DateTime.now();
      int age = now.year - _selectedDate!.year;
      if (now.month < _selectedDate!.month ||
          (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
        age--;
      }
      if (age < 13) {
        _birthdayError = "Vous devez avoir au moins 13 ans";
        isValid = false;
      }
    }

    if (_phoneNumberController.text.trim().isEmpty) {
      _phoneNumberError = "Le numéro de téléphone est requis";
      isValid = false;
    } else if (!_isValidAlgerianPhone(_phoneNumberController.text.trim())) {
      _phoneNumberError = "Numéro invalide. Format: 05xxxxxxxx, 06xxxxxxxx, ou 07xxxxxxxx";
      isValid = false;
    }

    if (_emailController.text.trim().isEmpty) {
      _emailError = "L'email est requis";
      isValid = false;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      _emailError = "Veuillez entrer un email valide";
      isValid = false;
    }

    if (_passwordController.text.trim().isEmpty) {
      _passwordError = "Le mot de passe est requis";
      isValid = false;
    } else if (!_isValidPassword(_passwordController.text.trim())) {
      _passwordError = "Le mot de passe doit contenir au moins 6 caractères";
      isValid = false;
    }
    final phoneText = _phoneNumberController.text.trim();
    numeroTelephone = phoneText.isNotEmpty ? _normalizeAlgerianPhone(phoneText) : null;

    setState(() {}); // Refresh UI for errors
    return isValid;
  }

  Future<void> _handleSignup() async {
    try {
      if (_validateForm()) {
        // int? numeroTelephone;
        // final phoneText = _phoneNumberController.text.trim();
        // try {
        //   numeroTelephone = phoneText.isNotEmpty ? int.parse(phoneText) : null;
        // } catch (_) {
        //   numeroTelephone = null;
        // }

        final userData = {
          'nom': _fullNameController.text.trim(),
          'prenom': _prenomeController.text.trim(),
          // Send as string to preserve leading zeros and +213 format
          'numero_telephone': numeroTelephone,
          'email': _emailController.text.trim(),
          'mot_de_passe': _passwordController.text.trim(),
        };

        print('The info send id : $userData');

        final user = await _signupController.createUser(userData);

        if (user != null) {
          Get.snackbar(
            'Success',
            'Account created successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.offAll(() =>  LogIn_Page());
        } else {
          print(_signupController.errorMessage.value);
          Get.snackbar(
            'Error',
            _signupController.errorMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('Error during signup: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred during signup. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.buttonColor,
              onPrimary: AppTheme.primaryTextColor,
              onSurface: AppTheme.primaryTextColor,
              surface: AppTheme.secondaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryTextColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _selectedDate = picked;
      _birthdayController.text =
          "${picked.day.toString().padLeft(2, '0')} / ${picked.month.toString().padLeft(2, '0')} / ${picked.year}";
      _birthdayError = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(AppImages.auth_background, fit: BoxFit.cover),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.width * 0.08),
                child: Column(
                  children: [
                    SizedBox(height: context.height * 0.04),
                    Image.asset(
                      AppImages.logo_png,
                      width: context.width * 0.2,
                      height: context.width * 0.2,
                    ),
                    Text(
                      "CREER UN COMPTE",
                      style: AppTheme.darkTheme.textTheme.displaySmall,
                    ),
                    SizedBox(height: context.height * 0.04),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Nom ",
                            style: AppTheme.darkTheme.textTheme.titleMedium,
                          ),
                          SizedBox(height: context.height * 0.01),
                          MyTextField(
                            hintText: "Entrer votre nom complet...",
                            controller: _fullNameController,
                            keyboardType: TextInputType.name,
                            obscureText: false,
                            errorText: _fullNameError,
                          ),

                          Text(
                            "prenome",
                            style: AppTheme.darkTheme.textTheme.titleMedium,
                          ),
                          SizedBox(height: context.height * 0.01),
                          MyTextField(
                            hintText: "Entrer votre prenome complet...",
                            controller: _prenomeController,
                            keyboardType: TextInputType.name,
                            obscureText: false,
                            errorText: _fullNameError,
                          ),
                          SizedBox(height: context.height * 0.03),
                          Text(
                            "Date de naissance",
                            style: AppTheme.darkTheme.textTheme.titleMedium,
                          ),
                          SizedBox(height: context.height * 0.01),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    _birthdayError != null
                                        ? Colors.red
                                        : Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _birthdayController,
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                  style:
                                      AppTheme.darkTheme.textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: "JJ / MM / AAAA",
                                    hintStyle:
                                        AppTheme
                                            .darkTheme
                                            .textTheme
                                            .labelMedium,
                                    filled: true,
                                    fillColor: AppTheme.accentColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.calendar_today,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 15,
                                    ),
                                  ),
                                ),
                                if (_birthdayError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 15,
                                      top: 5,
                                      bottom: 5,
                                    ),
                                    child: Text(
                                      _birthdayError!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: context.height * 0.03),
                          Text(
                            "Numéro de téléphone",
                            style: AppTheme.darkTheme.textTheme.titleMedium,
                          ),
                          SizedBox(height: context.height * 0.01),
                          MyTextField(
                            hintText: "Entrer votre numéro de téléphone...",
                            controller: _phoneNumberController,
                            keyboardType: TextInputType.phone,
                            obscureText: false,
                            errorText: _phoneNumberError,
                          ),
                          SizedBox(height: context.height * 0.03),
                          Text(
                            "Email",
                            style: AppTheme.darkTheme.textTheme.titleMedium,
                          ),
                          SizedBox(height: context.height * 0.01),
                          MyTextField(
                            hintText: "Entrer votre email...",
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            obscureText: false,
                            errorText: _emailError,
                          ),
                          SizedBox(height: context.height * 0.03),
                          Text(
                            "Mot de passe",
                            style: AppTheme.darkTheme.textTheme.titleMedium,
                          ),
                          SizedBox(height: context.height * 0.01),
                          MyTextField(
                            hintText: "Entrer votre mot de passe...",
                            controller: _passwordController,
                            obscureText: true,
                            errorText: _passwordError,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.height * 0.04),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: MaterialButton(
                        onPressed: _handleSignup,
                        color: AppTheme.buttonColor,
                        minWidth: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "CREER COMPTE",
                          style: AppTheme.darkTheme.textTheme.labelLarge!
                              .copyWith(color: AppTheme.primaryTextColor),
                        ),
                      ),
                    ),
                    SizedBox(height: context.height * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Vous avez deja un compte ? ",
                          style: AppTheme.darkTheme.textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.to(() =>  LogIn_Page());
                          },
                          child: Text(
                            "Connectez ici",
                            style: AppTheme.darkTheme.textTheme.bodyMedium!
                                .copyWith(decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.height * 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
