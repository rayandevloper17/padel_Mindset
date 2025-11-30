import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../controller/controller_participant.dart';
import '../utils/team_validation.dart';
import '../controller_user_padel.dart';
import 'package:app/services/api_service.dart';

/// Streamlined dialog that auto-selects position and only shows payment confirmation
class JoinMatchDialog extends StatefulWidget {
  final int reservationId;
  final double matchPrice;
  final String matchTime;
  final String matchDate;
  final String terrainName;
  final int plageId; // Time slot id for conflict check
  final int selectedPosition; // Required: position from button click (0-3)

  const JoinMatchDialog({
    Key? key,
    required this.reservationId,
    required this.matchPrice,
    required this.matchTime,
    required this.matchDate,
    required this.terrainName,
    required this.plageId,
    required this.selectedPosition, // Position already determined by button click
  }) : super(key: key);

  @override
  _JoinMatchDialogState createState() => _JoinMatchDialogState();
}

class _JoinMatchDialogState extends State<JoinMatchDialog> {
  bool isLoading = false;
  int _paymentType = 1; // 1: Credits, 2: Sur place
  final MatchController controller = Get.find<MatchController>();
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // Defer validation to after first frame to avoid build-phase updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _validatePosition();
    });
  }

  void _validatePosition() {
    // Validate position range (0-3)
    if (!isValidTeamIndex(widget.selectedPosition)) {
      // Schedule UI actions safely after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
        Get.snackbar(
          'Error',
          kTeamIndexErrorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      });
      return;
    }

    // Check if the EXACT position selected is occupied
    if (controller.isSlotOccupied(
      widget.reservationId,
      widget.selectedPosition,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
        Get.snackbar(
          'Position occupée',
          'La position ${widget.selectedPosition} est déjà prise. Veuillez en choisir une autre.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      });
    }
  }

  String _getTeamLabel() {
    return (widget.selectedPosition == 0 || widget.selectedPosition == 1)
        ? 'A'
        : 'B';
  }

  Future<void> _handlePaymentConfirmation() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userIdStr = await storage.read(key: 'userId');
      if (userIdStr == null) {
        throw Exception('User ID not found');
      }

      final userId = int.parse(userIdStr);

      // Pré-vérification: conflit à la même date et heure
      try {
        final api =
            Get.isRegistered<ApiService>()
                ? ApiService.instance
                : Get.put(ApiService());
        final resp = await api.get(
          '/reservations/check-date-time-conflict/${widget.matchDate}/${widget.plageId}',
        );
        if (resp.statusCode == 200) {
          final data = resp.data;
          final hasConflict =
              data is Map<String, dynamic>
                  ? (data['hasConflict'] == true)
                  : (data['hasConflict'] ?? false);
          if (hasConflict) {
            throw Exception(
              'Vous avez déjà un match prévu à la même date et heure',
            );
          }
        }
      } catch (_) {
        // Ignorer les erreurs réseau; le backend validera lors de la requête join
      }

      // Double-check position availability before payment
      if (controller.isSlotOccupied(
        widget.reservationId,
        widget.selectedPosition,
      )) {
        throw Exception('Cette position a été prise par un autre joueur');
      }

      int typePaiement = _paymentType; // 1: Crédit, 2: Sur place
      int statePaiement = _paymentType == 1 ? 1 : 0; // 1: payé, 0: à payer

      if (_paymentType == 1) {
        // Deduct credits first
        try {
          final userController = UserPadelController();
          final deduction = await userController.deductCredit(
            userId: userId.toString(),
            creditAmount: widget.matchPrice.toString(),
          );

          if (deduction['success'] != true) {
            throw Exception(
              deduction['message'] ?? 'Impossible de déduire les crédits',
            );
          }
        } catch (e) {
          throw Exception('Crédits insuffisants: ${e.toString()}');
        }
      }

      // ✅ CRITICAL FIX: Use joinMatchWithTeamIndex instead of joinMatch
      final success = await controller.joinMatchWithTeamIndex(
        widget.reservationId,
        userId,
        teamIndex:
            widget.selectedPosition, // ✅ Send exact position: 0, 1, 2, or 3
        typepaiement: typePaiement,
        statepaiement: statePaiement,
      );

      if (success) {
        // Persist successful selection
        final key = 'padel_selection_${widget.reservationId}';
        await storage.write(
          key: key,
          value: widget.selectedPosition.toString(),
        );

        Navigator.of(context).pop(); // Close dialog
        Get.snackbar(
          'Succès',
          'Match rejoint • Équipe ${_getTeamLabel()} • Position ${widget.selectedPosition}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        throw Exception(controller.errorMessage.value);
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.grey[900],
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.grey[850]!],
          ),
          border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Confirmer le paiement',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Match Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.stadium,
                        color: Color(0xFF6C63FF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.terrainName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF6C63FF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.matchDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF6C63FF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.matchTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Selected Position Display (Hero target from player slot)
            Hero(
              tag:
                  'join-slot-${widget.reservationId}-${widget.selectedPosition}',
              transitionOnUserGestures: true,
              child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6C63FF), width: 2),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.sports_tennis,
                    color: Color(0xFF6C63FF),
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CLUB ${_getTeamLabel()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Position ${widget.selectedPosition}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ),

            const SizedBox(height: 24),

            // Payment Options & Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sd_card_rounded,
                        color: Color(0xFF6C63FF),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Options de paiement',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Crédits'),
                        selected: _paymentType == 1,
                        onSelected: (sel) {
                          setState(() => _paymentType = 1);
                        },
                        selectedColor: const Color(0xFF6C63FF),
                        labelStyle: const TextStyle(color: Colors.white),
                        backgroundColor: Colors.grey[800],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Montant:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${widget.matchPrice} €',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child:
                        _paymentType == 1
                            ? const Text(
                              'Le montant sera débité de vos crédits.',
                              key: ValueKey('credits'),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            )
                            : const Text(
                              'Paiement à effectuer sur place avant le match.',
                              key: ValueKey('sur_place'),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Confirmation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handlePaymentConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 5,
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Confirmer et payer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info text
            const Text(
              'Le montant sera immédiatement débité de votre solde de crédits',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Usage in your _buildEmptyPlayerSlot method:
/// 
/// Widget _buildEmptyPlayerSlot(
///   BuildContext context,
///   Reservation reservation, {
///   required String teamLabel,
///   required int slotIndex,
///   required int positionNumber,
/// }) {
///   final MatchController controller = Get.find<MatchController>();
///   return GestureDetector(
///     onTap: () {
///       if (!controller.isUserInReservation(
///         controller.currentUserId.value,
///         reservation.id,
///       )) {
///         // Show payment confirmation dialog with auto-selected position
///         showDialog(
///           context: context,
///           builder: (context) => JoinMatchDialog(
///             reservationId: reservation.id,
///             matchPrice: reservation.prixTotal ?? 0.0,
///             matchTime: '${_formatTimeForDisplay(reservation.plageHoraire.startTime)} - ${_formatTimeForDisplay(reservation.plageHoraire.endTime)}',
///             matchDate: reservation.date,
///             terrainName: reservation.terrain.name,
///             selectedPosition: slotIndex, // Position from button click
///           ),
///         );
///       }
///     },
///     child: Stack(
///       clipBehavior: Clip.none,
///       children: [
///         Container(
///           width: 60,
///           height: 60,
///           decoration: BoxDecoration(
///             shape: BoxShape.circle,
///             color: Colors.black.withOpacity(0.5),
///             border: Border.all(color: Colors.grey.shade600, width: 1.5),
///           ),
///           child: Center(
///             child: Icon(Icons.add, color: Colors.grey.shade400, size: 24),
///           ),
///         ),
///         Positioned(
///           left: -6,
///           top: -6,
///           child: Container(
///             padding: const EdgeInsets.all(6),
///             decoration: BoxDecoration(
///               color: const Color(0xFF6C63FF),
///               shape: BoxShape.circle,
///               border: Border.all(color: Colors.white, width: 1.5),
///             ),
///             child: Text(
///               '$positionNumber',
///               style: const TextStyle(
///                 color: Colors.white,
///                 fontSize: 10,
///                 fontWeight: FontWeight.bold,
///               ),
///             ),
///           ),
///         ),
///       ],
///     ),
///   );
/// }