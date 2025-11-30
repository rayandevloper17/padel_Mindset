import 'package:app/global/constants/images.dart';
import 'package:app/modules/OnboardingView/onboarding_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController with GetTickerProviderStateMixin {
  final pageController = PageController();
  final currentIndex = 0.obs;
  
  late final AnimationController fadeController;
  late final AnimationController slideController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;

  final pages = [
    OnboardingPage(
      title: "Central Club Sportif",
      description: "Découvrez nos terrains de football aux normes internationales avec éclairage LED et pelouse synthétique de dernière génération.",
      assetPath: AppImages.onboarding1,
    ),
    OnboardingPage(
      title: "Courts de Padel Modernes", 
      description: "Profitez de nos courts de padel climatisés avec surface professionnelle et équipements haut de gamme pour une expérience unique.",
      assetPath: AppImages.onboarding2,
    ),
    OnboardingPage(
      title: "Réservation Simplifiée",
      description: "Réservez vos créneaux en quelques clics, gérez vos réservations et profitez d'une expérience utilisateur fluide et intuitive.",
      assetPath: AppImages.onboarding3,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Initialize fade controller
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize slide controller
    slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize animations
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeInOut,
    ));

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start initial animations
    fadeController.forward();
    slideController.forward();
  }

  @override
  void onClose() {
    pageController.dispose();
    fadeController.dispose();
    slideController.dispose();
    super.onClose();
  }

  void onNext() {
    if (currentIndex.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Get.offAllNamed('/login');
    }
  }

  void onSkip() {
    Get.offAllNamed('/login');
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
    // Reset and restart slide animation for new page
    slideController.reset();
    slideController.forward();
  }
}

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double containerHeight = size.height * 0.45;

    return Scaffold(
      body: Stack(
        children: [
          // Background PageView with images
          Positioned.fill(
            child: PageView.builder(
              controller: controller.pageController,
              itemCount: controller.pages.length,
              onPageChanged: controller.onPageChanged,
              itemBuilder: (context, index) {
                final page = controller.pages[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      page.assetPath,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Bottom content container
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: containerHeight,
            child: AnimatedBuilder(
              animation: controller.fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: controller.fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xCC1A1A1A), // 80% opacity
                          Color(0xFF1A1A1A),
                          Color(0xFF000000),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      border: Border.all(
                        color: const Color(0xFF333333),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Content area
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
                            child: AnimatedBuilder(
                              animation: controller.slideAnimation,
                              builder: (context, child) {
                                return SlideTransition(
                                  position: controller.slideAnimation,
                                  child: FadeTransition(
                                    opacity: controller.slideController,
                                    child: SingleChildScrollView(
                                      child: _buildPageContent(context),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        // Bottom navigation area
                        Container(
                          padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
                          child: Column(
                            children: [
                              // Page indicators
                              Obx(() => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  controller.pages.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    width: controller.currentIndex.value == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: controller.currentIndex.value == index
                                          ? Colors.white
                                          : const Color(0xFF666666),
                                    ),
                                  ),
                                ),
                              )),
                              const SizedBox(height: 32),
                              
                              // Navigation buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSkipButton(context),
                                  _buildNextButton(context),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(BuildContext context) {
    return Obx(() {
      final page = controller.pages[controller.currentIndex.value];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFB0B0B0),
                  height: 1.6,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Central Club Premium',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSkipButton(BuildContext context) {
    return TextButton(
      onPressed: controller.onSkip,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: Colors.transparent,
      ),
      child: Text(
        'Passer',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF666666),
            ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Obx(() {
      final isLastPage = controller.currentIndex.value == controller.pages.length - 1;
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF333333), Color(0xFF1A1A1A)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF444444),
            width: 1,
          ),
        ),
        child: TextButton(
          onPressed: controller.onNext,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            backgroundColor: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLastPage ? 'Commencer' : 'Suivant',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLastPage ? Icons.check : Icons.arrow_forward,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      );
    });
  }
}