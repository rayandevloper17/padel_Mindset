import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:app/modules/ProfileView/controller_profile_page.dart';
// import 'package:app/modules/ProfileView/controller/profile_controller.dart';
// import 'package:app/modules/ProfileView/reservastiom.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/controllers/auth_controller.dart';
import 'package:app/routes/app_pages.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController profilecontroller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTheme.primaryColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.primaryTextColor,
      ),
      body: Stack(
        children: [
          // Background image with dark gradient overlay for consistency
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(AppImages.home_background, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.overlayColor,
                        AppTheme.primaryColor.withOpacity(0.7),
                        AppTheme.primaryColor.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(child: _buildProfileContent(context)),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: context.width * 0.05),
      child: Column(
        children: [
          SizedBox(height: context.height * 0.01),
          Obx(() {
            final name = profilecontroller.nom.value;
            final prenome = profilecontroller.prenom.value;

            return _buildProfileSection(context, name, prenome);
          }),
          SizedBox(height: context.height * 0.04),
          _buildRecentReservationsSection(context),
          SizedBox(height: context.height * 0.04),
          _buildLogoutButton(context),
          SizedBox(height: context.height * 0.03),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    String name,
    String prenome,
  ) {
    return Container(
      padding: EdgeInsets.all(context.width * 0.06),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Obx(() {
                    final url = profilecontroller.profileImageUrl;
                    if (url.isNotEmpty) {
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 120,
                            color: AppTheme.primaryTextColor,
                          );
                        },
                      );
                    }
                    return Icon(
                      Icons.person,
                      size: 120,
                      color: AppTheme.primaryTextColor,
                    );
                  }),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => profilecontroller.editProfilePicture(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.height * 0.03),

          Obx(() {
            if (profilecontroller.nom.value.isEmpty ||
                profilecontroller.prenom.value.isEmpty) {
              return CircularProgressIndicator(
                color: AppTheme.primaryTextColor,
              );
            }
            return Text(
              "${profilecontroller.nom.value} ${profilecontroller.prenom.value}",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryTextColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            );
          }),

          SizedBox(height: context.height * 0.02),
          _buildUserIdCard(context),

          SizedBox(height: context.height * 0.02),

          Obx(() {
            final rating = profilecontroller.note.value;
            final fullStars = rating.floor();
            final halfStar = rating - fullStars >= 0.5;
            final emptyStars = 5 - fullStars - (halfStar ? 1 : 0);

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(
                  fullStars,
                  (index) =>
                      Icon(Icons.star, color: AppTheme.goldColor, size: 24),
                ),
                if (halfStar)
                  Icon(Icons.star_half, color: AppTheme.goldColor, size: 24),
                ...List.generate(
                  emptyStars,
                  (index) => Icon(
                    Icons.star_border,
                    color: AppTheme.goldColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: context.width * 0.02),
                Text(
                  rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }),

          SizedBox(height: context.height * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(context, Icons.badge, 'Membre'),
              SizedBox(width: context.width * 0.02),
              _buildInfoChip(context, Icons.sports_tennis, 'Padel'),
              SizedBox(width: context.width * 0.02),
              _buildInfoChip(context, Icons.verified, 'Actif'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserIdCard(BuildContext context) {
    return Obx(() {
      final id = profilecontroller.userId.value;
      if (id.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Chargement de votre ID…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.all(context.width * 0.04),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 86, 86, 104).withOpacity(0.25),
              const Color(0xFF22D3EE).withOpacity(0.20),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.45),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
                ),
              ),
              child: const Icon(Icons.fingerprint, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre identifiant',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryTextColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    id,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryTextColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontFamilyFallback: const ['SF Mono', 'monospace'],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: id));
                Get.snackbar(
                  'Copié',
                  'Votre ID a été copié dans le presse-papiers',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withOpacity(0.15),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.white),
              label: Text(
                'Copier',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.25),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRecentReservationsSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.width * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.cardColor.withOpacity(0.5),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DERNIERES RESERVATIONS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryTextColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: context.height * 0.025),

          Column(
            children: [
              _buildReservationItem(context, null),
              _buildReservationItem(context, null),
              _buildReservationItem(context, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationItem(BuildContext context, reservation) {
    return Container(
      margin: EdgeInsets.only(bottom: context.height * 0.015),
      padding: EdgeInsets.all(context.width * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: AppTheme.primaryColor.withOpacity(0.2),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réservation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CENTRAL PADEL',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: AppTheme.goldColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '12/01/2025',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, color: AppTheme.goldColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '12:00 - 14:00',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context) async {
    final authController = Get.find<AuthController>();
    await authController.logout();
    Get.offAllNamed(Routes.LOGIN);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Déconnexion',
            style: TextStyle(
              color: AppTheme.primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter?',
            style: TextStyle(color: AppTheme.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Annuler',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                _performLogout(context);
              },
              child: Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.height * 0.01,
          horizontal: context.width * 0.10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
        child: Text(
          'DECONNEXION',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.goldColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
