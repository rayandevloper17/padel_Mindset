// Add this UserRating model class to your models file
import 'package:app/modules/Padel/controller/controller_participant.dart';

class UserRating {
  final String id;
  final String idNoteur;
  final String dateCreation;
  final double note;
  final String idReservation;
  final ReservationData? reservation;
  final User? noteur;

  UserRating({
    required this.id,
    required this.idNoteur,
    required this.dateCreation,
    required this.note,
    required this.idReservation,
    this.reservation,
    this.noteur,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      id: json['id']?.toString() ?? '',
      idNoteur: json['id_noteur']?.toString() ?? '',
      dateCreation: json['date_creation']?.toString() ?? '',
      note: double.tryParse(json['note']?.toString() ?? '0') ?? 0.0,
      idReservation: json['id_reservation']?.toString() ?? '',
      reservation: json['reservation'] != null 
          ? ReservationData.fromJson(json['reservation']) 
          : null,
      noteur: json['noteur'] != null 
          ? User.fromJson(json['noteur']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_noteur': idNoteur,
      'date_creation': dateCreation,
      'note': note,
      'id_reservation': idReservation,
      'reservation': reservation?.toJson(),
      'noteur': noteur?.toString(),
    };
  }

  @override
  String toString() {
    return 'UserRating(id: $id, note: $note, noteur: ${noteur?.nom ?? "Unknown"}, reservation: $idReservation)';
  }
}

// Separate model for reservation data in ratings (to avoid conflicts with main Reservation model)
class ReservationData {
  final String id;
  final String idUtilisateur;
  final String idTerrain;
  final String idPlageHoraire;
  final String date;
  final String? etat;
  final double? prixTotal;
  final String? dateCreation;
  final String? dateModif;
  final String? qrcode;
  final int? nombreJoueurs;
  final String? typer;
  final String? coder;

  ReservationData({
    required this.id,
    required this.idUtilisateur,
    required this.idTerrain,
    required this.idPlageHoraire,
    required this.date,
    this.etat,
    this.prixTotal,
    this.dateCreation,
    this.dateModif,
    this.qrcode,
    this.nombreJoueurs,
    this.typer,
    this.coder,
  });

  factory ReservationData.fromJson(Map<String, dynamic> json) {
    return ReservationData(
      id: json['id']?.toString() ?? '',
      idUtilisateur: json['id_utilisateur']?.toString() ?? '',
      idTerrain: json['id_terrain']?.toString() ?? '',
      idPlageHoraire: json['id_plage_horaire']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      etat: json['etat']?.toString(),
      prixTotal: double.tryParse(json['prix_total']?.toString() ?? ''),
      dateCreation: json['date_creation']?.toString(),
      dateModif: json['date_modif']?.toString(),
      qrcode: json['qrcode']?.toString(),
      nombreJoueurs: int.tryParse(json['nombre_joueurs']?.toString() ?? ''),
      typer: json['typer']?.toString(),
      coder: json['coder']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_utilisateur': idUtilisateur,
      'id_terrain': idTerrain,
      'id_plage_horaire': idPlageHoraire,
      'date': date,
      'etat': etat,
      'prix_total': prixTotal,
      'date_creation': dateCreation,
      'date_modif': dateModif,
      'qrcode': qrcode,
      'nombre_joueurs': nombreJoueurs,
      'typer': typer,
      'coder': coder,
    };
  }
}