import 'package:app/global/constants/images.dart';
import 'package:app/global/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter_new/qr_flutter.dart';

import '../ProfileView/reservastiom.dart';

class HistoryDetailsScreen extends StatefulWidget {
  final String reservationId;

  const HistoryDetailsScreen({super.key, required this.reservationId});

  @override
  State<HistoryDetailsScreen> createState() => _HistoryDetailsScreenState();
}

class _HistoryDetailsScreenState extends State<HistoryDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Reservation _reservation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();

    // Load mocked data
    _reservation = _mockReservation(widget.reservationId);
  }

  Reservation _mockReservation(String reservationId) {
    return Reservation(
      reservationId: reservationId,
      fieldId: 'field_123',
      fieldName: ' Réservation Terrain Central ',
      fieldType: 'Soccer',
      date: '05/06/2025',
      timeSlotId: 'slot_930',
      startTime: '09:30',
      endTime: '10:30',
      price: 50.0,
      status: 'Confirmed',
      createdAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          // Background
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

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.width * 0.05,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: context.height * 0.03),
                            _buildFieldImage(context),
                            SizedBox(height: context.height * 0.04),
                            _buildTitle(context, _reservation.fieldName),
                            SizedBox(height: context.height * 0.02),
                            _buildDateTimeInfo(
                              context,
                              _reservation.date,
                              _reservation.startTime,
                            ),
                            SizedBox(height: context.height * 0.02),
                            _buildQRCodeSection(
                              context,
                              _reservation.reservationId,
                            ),
                            SizedBox(height: context.height * 0.04),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.width * 0.05,
            vertical: 20,
          ),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              // decoration: BoxDecoration(
              //   color: AppTheme.cardColor.withOpacity(0.3),
              //   borderRadius: BorderRadius.circular(12),
              //   border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
              // ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_ios,
                    color: AppTheme.primaryTextColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Retourner",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldImage(BuildContext context) {
    return Container(
      height: context.height * 0.25,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.overlayColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF4CAF50),
                      Color(0xFF2E7D32),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: FieldLinesPainter())),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: AppTheme.primaryTextColor,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDateTimeInfo(BuildContext context, String date, String time) {
    return Row(
      children: [
        _infoContainer(context, Icons.calendar_today, date),
        SizedBox(width: context.width * 0.06),
        _infoContainer(context, Icons.access_time, time),
      ],
    );
  }

  Widget _infoContainer(BuildContext context, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // decoration: BoxDecoration(
      //   color: AppTheme.cardColor.withOpacity(0.6),
      //   borderRadius: BorderRadius.circular(12),
      //   border: Border.all(
      //     color: AppTheme.borderColor.withOpacity(0.5),
      //   ),
      // ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryTextColor, size: 18),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(BuildContext context, String reservationId) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            // decoration: BoxDecoration(
            //   color: AppTheme.cardColor.withOpacity(0.4),
            //   borderRadius: BorderRadius.circular(16),
            //   border: Border.all(
            //     color: AppTheme.borderColor.withOpacity(0.3),
            //   ),
            // ),
            child: Text(
              "Ce code QR sera scanné lors \n de votre arrivée au complexe",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: context.height * 0.02),
        Container(
          width: context.width * 0.4,
          height: context.width * 0.4,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.overlayColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: QrImageView(
            data: reservationId,
            version: QrVersions.auto,
            size: context.width * 0.5,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}

class FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawCircle(Offset(centerX, centerY), size.width * 0.15, paint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);

    final goalWidth = size.width * 0.3;
    final goalHeight = size.height * 0.2;

    canvas.drawRect(
      Rect.fromLTWH(0, centerY - goalHeight / 2, goalWidth, goalHeight),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.width - goalWidth,
        centerY - goalHeight / 2,
        goalWidth,
        goalHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
