import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ProfileView/controller_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class CreditHeader extends StatefulWidget {
  final bool ishowing;
  const CreditHeader({super.key, required this.ishowing});

  @override
  State<CreditHeader> createState() => _CreditHeaderState();
}

class _CreditHeaderState extends State<CreditHeader>
    with WidgetsBindingObserver {
  final ProfileController profileController =
      Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    // Rafraîchit le profil au montage et sur reprise de l'application
    WidgetsBinding.instance.addObserver(this);
    profileController.refreshProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-rafraîchissement des crédits quand l'app redevient active
      profileController.refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool ishowing = widget.ishowing;
    return Obx(() {
      double userBalance =
          double.tryParse(profileController.creditBalance.value) ?? 0.0;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            AppImages.logo_png,
            width: context.width * 0.2,
            height: context.width * 0.2,
            fit: BoxFit.contain,
          ),
          // Left group: profile avatar + credits + refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.width * 0.02,
                    ),
                    child:
                        ishowing
                            ? Container(
                              width: context.width * 0.15,
                              height: context.width * 0.15,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor,
                                border: Border.all(
                                  color: AppTheme.warningColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Obx(
                                    () => Text(
                                      profileController
                                              .creditBalance
                                              .value
                                              .isNotEmpty
                                          ? (userBalance >= 1000
                                              ? '${(userBalance / 1000).toStringAsFixed(1)}k'
                                              : userBalance.toStringAsFixed(1))
                                          : '0.0',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.warningColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
                            )
                            : Container(),
                  ),
                  if (ishowing)
                    Padding(
                      padding: EdgeInsets.only(left: context.width * 0.01),
                      child: Obx(() {
                        final loading = profileController.isLoading.value;
                        return GestureDetector(
                          onTap:
                              loading
                                  ? null
                                  : () => profileController.refreshProfile(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.06),
                              shape: BoxShape.circle,
                            ),
                            child:
                                loading
                                    ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryTextColor,
                                      ),
                                    )
                                    : Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: AppTheme.primaryTextColor,
                                    ),
                          ),
                        );
                      }),
                    ),
                ],
              ),
              SizedBox(width: context.width * 0.02),

              // Profile avatar with edit and rating
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
                          width: context.width * 0.16,
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
                          border: Border.all(color: Colors.white70, width: 1),
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
                    top: -0,
                    right: -0,
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
                          Icon(Icons.star, color: Colors.black, size: 9),
                          const SizedBox(width: 2),
                          Text(
                            profileController.note.value.toStringAsFixed(1),
                            style: TextStyle(
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

              // Credits + refresh
            ],
          ),

          // Container(
          //   padding: EdgeInsets.symmetric(horizontal: context.width * 0.02),
          //   child:
          //       ishowing
          //           ? Container(
          //             width: context.width * 0.15,
          //             height: context.width * 0.15,
          //             decoration: BoxDecoration(
          //               shape: BoxShape.circle,
          //               color: AppTheme.silverColor.withOpacity(0.2),
          //               border: Border.all(
          //                 color: AppTheme.silverColor,
          //                 width: 1.5,
          //               ),
          //             ),
          //             child: Column(
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               children: [
          //                 Obx(
          //                   () => Text(
          //                     profileController.creditsilverpadel.value.isNotEmpty ? (double.parse(profileController.creditsilverpadel.value) >= 1000 ? '${(double.parse(profileController.creditsilverpadel.value) / 1000).toStringAsFixed(1)}k' : double.parse(profileController.creditsilverpadel.value).toStringAsFixed(1)) : '0.0',
          //                     style: Theme.of(
          //                       context,
          //                     ).textTheme.bodyMedium?.copyWith(
          //                       color: AppTheme.silverColor,
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                 ),
          //                 Text(
          //                   'Credit',
          //                   style: Theme.of(
          //                     context,
          //                   ).textTheme.bodySmall?.copyWith(
          //                     color: AppTheme.silverColor,
          //                     fontWeight: FontWeight.w500,
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           )
          //           : Container(),
          // ),
        ],
      );
    });
  }
}
