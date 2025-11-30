import 'dart:convert';
import 'dart:math';
import 'package:app/modules/susscedPage/susscedPage.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:app/services/api_service.dart';
import 'package:qr_flutter_new/qr_flutter.dart';
import '../SoocerScreen/reservation_model.dart' as sm;
import 'package:app/modules/Padel/controller/controller_participant.dart'
    show MatchController;

class ReservationController extends GetxController {

  var reservations = <sm.Reservation>[].obs;
  var isLoading = false.obs;

  /// Fetch all reservations
  Future<void> fetchReservations() async {
    try {
      isLoading.value = true;
      final resp = await ApiService.instance.get('/reservations');
      if (resp.statusCode == 200) {
        final List data = (resp.data is List)
            ? resp.data
            : List<Map<String, dynamic>>.from(resp.data as List);
        reservations.value =
            data.map((json) => sm.Reservation.fromJson(json)).toList();
      } else {
        Get.snackbar('Error', 'Failed to fetch reservations');
      }
    } catch (e) {
      Get.snackbar('Exception', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a reservation with auto-generated QR code
  Future<void> createReservationWithData({
    required int idUtilisateur,
    required int idTerrain,
    required int idPlageHoraire,
    required String date,
    required double prixTotal,
    int? nombreJoueurs,
    required int typer,
    required int etat,
    int? typepaiementForCreator,
  }) async {
    final token = await ApiService.instance.getValidAccessToken();

    if (token == null) {
      await Get.dialog(
        AlertDialog(
          title: Text(
            'Authentication Error',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Please login again to continue. Your session has expired.',
          ),
          actions: [TextButton(child: Text('OK'), onPressed: () => Get.back())],
        ),
      );
      return;
    }

    // Pré-vérification: empêcher la création de deux réservations le même jour (aujourd'hui)
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (date == todayStr) {
        final resp = await ApiService.instance.get(
          '/reservations/check-date-conflict/$date',
        );
        if (resp.statusCode == 200) {
          final data = (resp.data is Map<String, dynamic>)
              ? resp.data
              : Map<String, dynamic>.from(resp.data as Map);
          final hasConflict = data['hasConflict'] == true;
          if (hasConflict) {
            await Get.dialog(
              AlertDialog(
                title: const Text(
                  'Conflit',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'Vous avez déjà créé une réservation aujourd’hui. Une seule réservation par jour est autorisée.',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(child: const Text('OK'), onPressed: () => Get.back()),
                ],
              ),
            );
            return; // Ne pas continuer la création
          }
        }
      }
    } catch (e) {
      // Ignorer les erreurs de pré-check; continuer vers la création
    }

    // Show processing dialog
    Get.dialog(
      Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating your reservation...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Generate unique QR code based on timestamp, user ID and random number
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond; // Additional randomness
    final qrCodeData = '$timestamp-$idUtilisateur-$random';
    final coder = qrCodeData
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .substring(0, min(8, qrCodeData.length));
    // Generate QR code data
    final qrCode = QrCode(4, QrErrorCorrectLevel.L)..addData(qrCodeData);
    // Store the QR code data directly as a string
    final qrString = qrCode.toString();

    final reservation = sm.Reservation(
      idUtilisateur: idUtilisateur,
      idTerrain: idTerrain,
      idPlageHoraire: idPlageHoraire,
      date: date,
      prixTotal: prixTotal,
      coder: coder,
      nombreJoueurs: nombreJoueurs,
      typer: typer,
      etat: etat,
      qrcode: qrString,
      dateCreation: DateTime.now(),
      dateModif: DateTime.now(),
    );

    try {
      final resp = await ApiService.instance.post(
        '/reservations',
        data: reservation.toJson(),
      );

      // Close processing dialog
      Get.back();

      if (resp.statusCode == 201) {
        debugPrint('✅ Reservation created successfully');
        debugPrint('✅  Code: $coder');

        // Update the plage horaire availability.
        // Requirement: when payment type is Sur place (etat==0 or typepaiement==2),
        // keep the slot available until Administration confirms.
        // Otherwise, follow match type rules (open=available, private=blocked).
        try {
          await _updatePlageHoraireDisponibilite(
            idPlageHoraire,
            disponible:
                (typer == 2) ||
                (etat == 0) ||
                ((typepaiementForCreator ?? 1) == 2),
          );
        } catch (e) {
          debugPrint('⚠️ Failed to update plage horaire availability: $e');
        }

        // Removed forced auto-assignment of creator to Club A position.
        // The creator can now freely choose any club/position from the join UI.

        if (etat == 0 || ((typepaiementForCreator ?? 1) == 2)) {
          // Sur place => pending confirmation popup, do NOT confirm directly
          await Get.dialog(
            AlertDialog(
              title: const Text(
                'Pending Confirmation',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Please wait for confirmation from the Administration to confirm your order reservation. Thank you.',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          );
        } else {
          await Get.dialog(
            AlertDialog(
              title: Text(
                'Success!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 50),
                  SizedBox(height: 16),
                  Text('Your reservation has been created successfully.'),
                  Text(
                    'Reservation Code: $coder',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Continue'),
                  onPressed: () {
                    Get.back();
                    Get.to(() => SucesPage());
                  },
                ),
              ],
            ),
          );
        }
      } else {
        // Log error details to console
        debugPrint('❌ Reservation creation failed');
        debugPrint('Status code: ${resp.statusCode}');
        debugPrint('Response data: ${resp.data}');

        String errorMessage = 'Unable to create your reservation.';
        try {
          final errorBody = (resp.data is Map<String, dynamic>)
              ? resp.data
              : Map<String, dynamic>.from(resp.data as Map);
          errorMessage = errorBody['message']?.toString() ?? errorMessage;
        } catch (e) {
          debugPrint('Failed to parse error response: $e');
        }

        await Get.dialog(
          AlertDialog(
            title: Text(
              'Reservation Failed',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 50),
                SizedBox(height: 16),
                Text(errorMessage),
                Text('Error code: ${resp.statusCode}'),
                if (resp.statusCode == 400)
                  Text('Please check your reservation details.')
                else if (resp.statusCode == 401)
                  Text('Your session has expired. Please login again.')
                else if (resp.statusCode == 403)
                  Text('You do not have permission to make this reservation.')
                else
                  Text('Please try again later or contact support.'),
              ],
            ),
            actions: [
              TextButton(child: Text('OK'), onPressed: () => Get.back()),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      // Close processing dialog
      Get.back();

      debugPrint('Exception during reservation: $e');
      debugPrintStack(stackTrace: stackTrace);

      await Get.dialog(
        AlertDialog(
          title: Text(
            'Error Occurred',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.red, size: 50),
              SizedBox(height: 16),
              Text(
                'An unexpected error occurred while processing your reservation.',
              ),
              Text(
                'Please try again later or contact support if the problem persists.',
              ),
            ],
          ),
          actions: [TextButton(child: Text('OK'), onPressed: () => Get.back())],
        ),
      );
    }
  }

  Future<void> _updatePlageHoraireDisponibilite(
    int idPlageHoraire, {
    required bool disponible,
  }) async {
    final token = await ApiService.instance.getValidAccessToken();

    if (token == null) {
      debugPrint('❌ Authentication token not found');
      return;
    }

    try {
      final resp = await ApiService.instance.put(
        '/plage-horaire/$idPlageHoraire',
        data: {'disponible': disponible},
      );

      if (resp.statusCode == 200) {
        debugPrint(
          '✅ Plage horaire $idPlageHoraire updated: disponible=$disponible',
        );
      } else {
        debugPrint('❌ Failed to update plage horaire: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error updating plage horaire: $e');
    }
  }

  /// Get reservation by ID
  Future<sm.Reservation?> getReservationById(int id) async {
    try {
      final resp = await ApiService.instance.get('/reservations/$id');
      if (resp.statusCode == 200) {
        final data = (resp.data is Map<String, dynamic>)
            ? resp.data
            : Map<String, dynamic>.from(resp.data as Map);
        return sm.Reservation.fromJson(data);
      } else {
        Get.snackbar('Error', 'Reservation not found');
      }
    } catch (e) {
      Get.snackbar('Exception', e.toString());
    }
    return null;
  }

  /// Update a reservation
  Future<void> updateReservation(int id, sm.Reservation reservation) async {
    try {
      final resp = await ApiService.instance.put(
        '/reservations/$id',
        data: reservation.toJson(),
      );
      if (resp.statusCode == 200) {
        fetchReservations();
        Get.snackbar('Success', 'Reservation updated');
      } else {
        Get.snackbar('Error', 'Failed to update reservation');
      }
    } catch (e) {
      Get.snackbar('Exception', e.toString());
    }
  }

  /// Delete a reservation
  Future<void> deleteReservation(int id) async {
    try {
      final resp = await ApiService.instance.delete('/reservations/$id');
      if (resp.statusCode == 200) {
        reservations.removeWhere((r) => (r.id ?? -1) == id);
        Get.snackbar('Deleted', 'Reservation removed');
      } else {
        Get.snackbar('Error', 'Failed to delete reservation');
      }
    } catch (e) {
      Get.snackbar('Exception', e.toString());
    }
  }
}
