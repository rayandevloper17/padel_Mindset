import 'dart:convert';
import 'package:app/services/api_service.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class RatingController extends GetxController {
  late final AuthController _authController;
  var answers = {
    'Q1': ''.obs,
    'Q2': ''.obs,
    'Q3': ''.obs,
    'Q4': ''.obs,
    'Q5': ''.obs,
  };

  var displayQ = 0.obs;
  var note = 0.0.obs;
  var statusLoaded = false.obs;

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'null';
    final tail = token.length > 6 ? token.substring(token.length - 6) : token;
    return '***$tail';
  }

  void _log(String message, [Map<String, dynamic>? meta]) {
    final ts = DateTime.now().toIso8601String();
    final base = '[RatingController][$ts] $message';
    if (meta == null || meta.isEmpty) {
      print(base);
    } else {
      try {
        print('$base | ${jsonEncode(meta)}');
      } catch (_) {
        print('$base | $meta');
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Resolve AuthController after DI is complete
    _authController = Get.find<AuthController>();
    // Attendre que l'ID utilisateur soit disponible
    _log('onInit: attaching currentUser listener');
    _authController.currentUser.listen((user) {
      _log('currentUser changed', {'id': user?['id']});
      if (user != null && user['id'] != null) {
        getRatingStatus();
      }
    });
  }

  void setAnswer(String question, String answer) {
    answers[question]?.value = answer;
  }

  Future<void> getRatingStatus() async {
    final userId = _authController.currentUser.value?['id'];
    _log('getRatingStatus invoked', {'userId': userId});
    if (userId == null) {
      _log('userId is null; skipping fetch');
      return;
    }

    String? token;
    try {
      token = await ApiService.instance.getValidAccessToken();
      _log('token obtained', {'token': _maskToken(token)});
    } catch (e) {
      _log('token obtain failed', {'error': e.toString()});
    }

    if (token == null || token.isEmpty) {
      _log('missing token; aborting', {'userId': userId});
      Get.snackbar('Erreur', 'Token manquant. Veuillez vous reconnecter.');
      return;
    }
    _log('sending GET via ApiService', {'userId': userId});

    try {
      final resp = await ApiService.instance.get('/rating/$userId');

      _log('response received', {
        'status': resp.statusCode,
        'hasData': resp.data != null,
      });

      if (resp.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = (resp.data is Map<String, dynamic>)
              ? resp.data
              : Map<String, dynamic>.from(resp.data as Map);
        } catch (e) {
          final String sample = resp.data?.toString() ?? '';
          _log('json decode failed', {
            'error': e.toString(),
            'bodySample': sample.substring(0, sample.length.clamp(0, 200)),
          });
          Get.snackbar(
            'Erreur',
            'Réponse invalide pour le statut du questionnaire.',
          );
          return;
        }
        displayQ.value = (data['displayQ'] as num?)?.toInt() ?? 0;
        note.value = (data['note'] as num?)?.toDouble() ?? 0.0;
        statusLoaded.value = true;
        _log('status updated', {
          'displayQ': displayQ.value,
          'note': note.value,
          'loaded': statusLoaded.value,
        });
      } else {
        _log('non-200 response', {
          'status': resp.statusCode,
          'data': resp.data,
        });
        Get.snackbar(
          'Erreur',
          'Impossible de récupérer le statut du questionnaire (${resp.statusCode}).',
        );
      }
    } catch (e) {
      _log('HTTP GET failed', {
        'error': e.toString(),
      });
      Get.snackbar(
        'Erreur',
        'Échec de la connexion au serveur de notation.',
      );
    }
  }

  Future<void> calculateAndSubmitRating() async {
    final userId = _authController.currentUser.value?['id'];
    if (userId == null) {
      Get.snackbar('Erreur', 'Utilisateur non connecté.');
      return;
    }

    final answersMap = {
      'Q1': answers['Q1']?.value,
      'Q2': answers['Q2']?.value,
      'Q3': answers['Q3']?.value,
      'Q4': answers['Q4']?.value,
      'Q5': answers['Q5']?.value,
    };

    String? token;
    try {
      token = await ApiService.instance.getValidAccessToken();
      _log('token obtained (submit)', {'token': _maskToken(token)});
    } catch (e) {
      _log('token obtain failed (submit)', {'error': e.toString()});
    }

    if (token == null || token.isEmpty) {
      _log('missing token; aborting submit', {'userId': userId});
      Get.snackbar('Erreur', 'Token manquant. Veuillez vous reconnecter.');
      return;
    }
    _log('sending POST via ApiService', {'userId': userId});
    try {
      final resp = await ApiService.instance.post(
        '/rating',
        data: <String, dynamic>{
          'userId': userId,
          'answers': answersMap,
        },
      );

      _log('response received (submit)', {
        'status': resp.statusCode,
        'hasData': resp.data != null,
      });

      if (resp.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = (resp.data is Map<String, dynamic>)
              ? resp.data
              : Map<String, dynamic>.from(resp.data as Map);
        } catch (e) {
          final String sample = resp.data?.toString() ?? '';
          _log('json decode failed (submit)', {
            'error': e.toString(),
            'bodySample': sample.substring(0, sample.length.clamp(0, 200)),
          });
          Get.snackbar('Erreur', 'Réponse invalide lors de la soumission.');
          return;
        }
        note.value = (data['note'] as num?)?.toDouble() ?? 0.0;
        displayQ.value = 1;
        _log('submit updated status', {
          'displayQ': displayQ.value,
          'note': note.value,
        });
        Get.snackbar('Succès', 'Votre niveau a été mis à jour.');
      } else {
        _log('non-200 response (submit)', {
          'status': resp.statusCode,
          'data': resp.data,
        });
        Get.snackbar('Erreur', 'Une erreur est survenue lors de la soumission.');
      }
    } catch (e) {
      _log('HTTP POST failed', {'error': e.toString()});
      Get.snackbar('Erreur', 'Échec de la connexion au serveur de notation.');
    }
  }
}
