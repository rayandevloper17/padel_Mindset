import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Reservation model
class Reservation {
  final String id;
  final String placeName;
  final DateTime date;
  final double price;

  Reservation({
    required this.id,
    required this.placeName,
    required this.date,
    required this.price,
  });
}
class ProfileController extends GetxController {
  // Observable user profile fields
  final RxString userName = ''.obs;
  final RxString email = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString profileImage = ''.obs;
  final RxBool isLoading = false.obs;

  // Recent reservations
  final RxList<Reservation> recentReservations = <Reservation>[].obs;

  // Static rating for now
  final double userRating = 4.5;

  // Animation Controllers and Animations
  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  late AnimationController slideController;
  late Animation<Offset> slideAnimation;

  // Initialize animations with vsync from widget
  void initAnimations(TickerProvider vsync) {
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );
    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: fadeController,
        curve: Curves.easeInOut,
      ),
    );

    slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: vsync,
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    loadRecentReservations();
  }

  @override
  void onClose() {
    fadeController.dispose();
    slideController.dispose();
    super.onClose();
  }

  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 2));

      // Mock data
      userName.value = 'John Doe';
      email.value = 'john.doe@example.com';
      phoneNumber.value = '+213654987321';
      profileImage.value = 'assets/default_profile.png';
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRecentReservations() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      recentReservations.assignAll([
        Reservation(
          id: '1',
          placeName: 'La Villa Oran',
          date: DateTime.now().subtract(const Duration(days: 2)),
          price: 2500,
        ),
        Reservation(
          id: '2',
          placeName: 'El Bahia Restaurant',
          date: DateTime.now().subtract(const Duration(days: 5)),
          price: 1800,
        ),
        Reservation(
          id: '3',
          placeName: 'Le Gourmet d’Alger',
          date: DateTime.now().subtract(const Duration(days: 8)),
          price: 3000,
        ),
      ]);
    } catch (e) {
      print('Error loading reservations: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? newEmail,
    String? phone,
    String? image,
  }) async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1));

      if (name != null) userName.value = name;
      if (newEmail != null) email.value = newEmail;
      if (phone != null) phoneNumber.value = phone;
      if (image != null) profileImage.value = image;
    } catch (e) {
      print('Error updating profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
