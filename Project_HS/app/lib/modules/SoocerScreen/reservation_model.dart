class Reservation {
  int? id;
  int idUtilisateur;
  int idTerrain;
  int idPlageHoraire;
  String date;
  int? etat;
  double prixTotal;
  DateTime? dateCreation;
  DateTime? dateModif;
  String? qrcode;
  String? coder;

  int? nombreJoueurs;
  int? typer;

  Reservation({
    this.id,
    required this.idUtilisateur,
    required this.idTerrain,
    required this.idPlageHoraire,
    required this.date,
    this.etat = 0,
    required this.prixTotal,
    this.dateCreation,
    this.dateModif,
    this.coder,
    this.qrcode,
    this.nombreJoueurs,
    this.typer = 1,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: int.tryParse(json['id'].toString()),
    idUtilisateur: int.parse(json['id_utilisateur'].toString()),
    idTerrain: int.parse(json['id_terrain'].toString()),
    idPlageHoraire: int.parse(json['id_plage_horaire'].toString()),
    date: json['date'],
    etat: json['etat'],
    prixTotal: double.parse(json['prix_total'].toString()),
    dateCreation:
        json['date_creation'] != null
            ? DateTime.parse(json['date_creation'])
            : null,
    dateModif:
        json['date_modif'] != null ? DateTime.parse(json['date_modif']) : null,
    coder: json['coder'],
    qrcode: json['qrcode'],
    nombreJoueurs:
        json['nombre_joueurs'] != null
            ? int.parse(json['nombre_joueurs'].toString())
            : null,
    typer: json['typer'] != null ? int.parse(json['typer'].toString()) : 1,
  );

  Map<String, dynamic> toJson() => {
    'id_utilisateur': idUtilisateur,
    'id_terrain': idTerrain,
    'id_plage_horaire': idPlageHoraire,
    'date': date,
    'etat': etat,
    'prix_total': prixTotal,
    'date_creation': dateCreation?.toIso8601String(),
    'date_modif': dateModif?.toIso8601String(),
    'coder': coder,
    'qrcode': qrcode,
    'nombre_joueurs': nombreJoueurs,
    'typer': typer,
  };
}
