import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ProfileView/controller_profile_page.dart';
// Removed unused LocationController import
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreditHeader extends StatefulWidget {
  final bool ishowing;
  const CreditHeader({super.key, required this.ishowing});

  @override
  State<CreditHeader> createState() => _CreditHeaderState();
}

class _CreditHeaderState extends State<CreditHeader>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final ProfileController profileController =
      Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : Get.put(ProfileController());

  // Removed unused LocationController instance

  late AnimationController _animationController;
  late Animation<double> _borderAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer the initial refresh to after the first frame to avoid
    // triggering state changes during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileController.refreshProfile();
    });

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Border glow animation (0 -> 1 -> 0)
    _borderAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_animationController);

    // Scale animation (1 -> 0.95 -> 1)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 80,
      ),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      profileController.refreshProfile();
    }
  }

  void _handleCreditTap() {
    // Start animation
    _animationController.forward(from: 0.0);

    // Trigger refresh
    profileController.refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final ishowing = widget.ishowing;
    return Obx(() {
      final double userBalance =
          double.tryParse(profileController.creditBalance.value) ?? 0.0;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // App logo
          Flexible(
            fit: FlexFit.loose,
            child: Image.asset(
              AppImages.logo_png,
              width: context.width * 0.2,
              height: context.width * 0.2,
              fit: BoxFit.contain,
            ),
          ),

          // Right group: credits and profile
          Flexible(
            fit: FlexFit.loose,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.width * 0.45),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Credit Container
                  if (ishowing)
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap:
                                  profileController.isLoading.value
                                      ? null
                                      : _handleCreditTap,
                              child: Container(
                                width: context.width * 0.14,
                                height: context.width * 0.14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryColor,
                                  border: Border.all(
                                    color:
                                        Color.lerp(
                                          AppTheme.warningColor,
                                          AppTheme.warningColor.withOpacity(
                                            0.3,
                                          ),
                                          1 - _borderAnimation.value,
                                        )!,
                                    width: 1.5 + (_borderAnimation.value * 1.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.warningColor.withOpacity(
                                        _borderAnimation.value * 0.6,
                                      ),
                                      blurRadius: 12 * _borderAnimation.value,
                                      spreadRadius: 2 * _borderAnimation.value,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Main content
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Obx(() {
                                          final loading =
                                              profileController.isLoading.value;
                                          if (loading) {
                                            return SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppTheme.warningColor),
                                              ),
                                            );
                                          }

                                          return Text(
                                            profileController
                                                    .creditBalance
                                                    .value
                                                    .isNotEmpty
                                                ? (userBalance >= 1000
                                                    ? '${(userBalance / 1000).toStringAsFixed(1)}k'
                                                    : userBalance
                                                        .toStringAsFixed(1))
                                                : '0.0',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              color: AppTheme.warningColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }),
                                        Text(
                                          'Crédits',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.primaryTextColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Ripple effect overlay
                                    if (_borderAnimation.value > 0)
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: RipplePainter(
                                            progress: _borderAnimation.value,
                                            color: AppTheme.warningColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(width: 8),

                  // Profile Avatar
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.overlayColor,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: SizedBox(
                              height: context.height * 0.07,
                              width: context.width * 0.14,
                              child: Obx(() {
                                final url = profileController.profileImageUrl;
                                if (url.isNotEmpty) {
                                  return Image.network(url, fit: BoxFit.cover);
                                }
                                return Icon(
                                  Icons.person,
                                  size: context.width * 0.10,
                                  color: AppTheme.primaryTextColor,
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => profileController.editProfilePicture(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white70,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldColor,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.black,
                                size: 9,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                profileController.note.value.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw expanding ripple
    final rippleRadius = maxRadius * progress;
    final ripplePaint =
        Paint()
          ..color = color.withOpacity((1 - progress) * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawCircle(center, rippleRadius, ripplePaint);
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
