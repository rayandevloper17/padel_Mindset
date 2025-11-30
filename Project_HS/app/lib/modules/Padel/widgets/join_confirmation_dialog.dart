import 'package:flutter/material.dart';

/// Affiche une fenêtre de confirmation avant de rejoindre un match.
/// Retourne true si l'utilisateur confirme, sinon false.
Future<bool> showJoinConfirmationDialog(
  BuildContext context, {
  String title = 'Confirmer la réservation',
  String message = 'Voulez-vous confirmer votre participation à ce match ?',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Non',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}