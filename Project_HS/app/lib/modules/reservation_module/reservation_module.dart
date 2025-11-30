// ---------------- MODELS ----------------
class Reservation {
  final int id;
  final String date;
  final Terrain terrain;
  final User utilisateur;
  final PlageHoraire plageHoraire;
  final int? nombreJoueurs;
  final String? etat;
  final double? prixTotal;
  final String? dateCreation;
  final String? dateModif;
  final String? qrcode;
  final String? typer;
  final String? coder;

  Reservation({
    required this.id,
    required this.date,
    required this.terrain,
    required this.utilisateur,
    required this.plageHoraire,
    this.nombreJoueurs,
    this.etat,
    this.prixTotal,
    this.dateCreation,
    this.dateModif,
    this.qrcode,
    this.typer,
    this.coder,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: int.tryParse(json['id'].toString()) ?? 0,
      date: json['date'] ?? '',
      nombreJoueurs: int.tryParse(json['nombre_joueurs']?.toString() ?? ''),
      terrain: Terrain.fromJson(json['terrain'] ?? {}),
      utilisateur: User.fromJson(json['utilisateur'] ?? {}),
      plageHoraire: PlageHoraire.fromJson(json['plageHoraire'] ?? {}),
      etat: json['etat']?.toString(),
      prixTotal: double.tryParse(json['prix_total']?.toString() ?? ''),
      dateCreation: json['date_creation']?.toString(),
      dateModif: json['date_modif']?.toString(),
      qrcode: json['qrcode']?.toString(),
      typer: json['typer']?.toString(),
      coder: json['coder']?.toString(),
    );
  }
}

class Terrain {
  final int id;
  final String name;
  final String type;
  final String imageUrl;

  Terrain({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
  });

  factory Terrain.fromJson(Map<String, dynamic> json) {
    return Terrain(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class PlageHoraire {
  final int id;
  final String startTime;
  final String endTime;
  final double? price;

  PlageHoraire({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.price,
  });

  factory PlageHoraire.fromJson(Map<String, dynamic> json) {
    return PlageHoraire(
      id: int.tryParse(json['id'].toString()) ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? ''),
    );
  }
}

class User {
  final int id;
  final String nom;
  final String prenom;
  final String? dateNaissance;
  final String? email;
  final String? numeroTelephone;
  final double? creditBalance; // Single credit balance field
  final String? points;
  final double? note;
  final String? imageUrl;
  final String? dateCreation;
  final String? dateMisAJour;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.email,
    this.numeroTelephone,
    this.creditBalance, // Single credit balance
    this.points,
    this.note,
    this.imageUrl,
    this.dateCreation,
    this.dateMisAJour,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      dateNaissance: json['date_naissance']?.toString(),
      email: json['email']?.toString(),
      numeroTelephone: json['numero_telephone']?.toString(),
      creditBalance: double.tryParse(
        json['credit_balance']?.toString() ?? 
        json['credit_gold_padel']?.toString() ?? '', // Fallback for backward compatibility
      ),
      points: json['points']?.toString(),
      note: double.tryParse(json['note']?.toString() ?? ''),
      imageUrl: json['image_url']?.toString(),
      dateCreation: json['date_creation']?.toString(),
      dateMisAJour: json['date_misajour']?.toString(),
    );
  }
}

class Participant {
  final int id;
  final int idUtilisateur;
  final int idReservation;
  final bool estCreateur;
  final User? utilisateur; // ✅ add this

  Participant({
    required this.id,
    required this.idUtilisateur,
    required this.idReservation,
    required this.estCreateur,
    this.utilisateur,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: int.tryParse(json['id'].toString()) ?? 0,
      idUtilisateur: int.tryParse(json['id_utilisateur'].toString()) ?? 0,
      idReservation:
          int.tryParse(json['id_reservation']?.toString() ?? '0') ?? 0,
      estCreateur: json['est_createur'] ?? false,
      utilisateur:
          json['utilisateur'] != null
              ? User.fromJson(json['utilisateur'])
              : null,
    );
  }
}
