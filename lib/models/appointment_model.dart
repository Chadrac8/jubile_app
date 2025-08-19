import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String membreId;
  final String responsableId;
  final DateTime dateTime;
  final String motif;
  final String statut; // 'en_attente', 'confirme', 'refuse', 'termine', 'annule'
  final String lieu; // 'en_personne', 'appel_video', 'telephone'
  final String? notes;
  final String? notesPrivees; // Visible uniquement par le responsable
  final String? adresse; // Pour les RDV en personne
  final String? lienVideo; // Pour les RDV vidéo
  final String? numeroTelephone; // Pour les RDV téléphone
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastModifiedBy;
  final DateTime? dateConfirmation;
  final DateTime? dateAnnulation;
  final String? raisonAnnulation;

  AppointmentModel({
    required this.id,
    required this.membreId,
    required this.responsableId,
    required this.dateTime,
    required this.motif,
    this.statut = 'en_attente',
    this.lieu = 'en_personne',
    this.notes,
    this.notesPrivees,
    this.adresse,
    this.lienVideo,
    this.numeroTelephone,
    required this.createdAt,
    required this.updatedAt,
    this.lastModifiedBy,
    this.dateConfirmation,
    this.dateAnnulation,
    this.raisonAnnulation,
  });

  String get statutLabel {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'confirme':
        return 'Confirmé';
      case 'refuse':
        return 'Refusé';
      case 'termine':
        return 'Terminé';
      case 'annule':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  String get lieuLabel {
    switch (lieu) {
      case 'en_personne':
        return 'En personne';
      case 'appel_video':
        return 'Appel vidéo';
      case 'telephone':
        return 'Téléphone';
      default:
        return 'Non défini';
    }
  }

  bool get isEnAttente => statut == 'en_attente';
  bool get isConfirme => statut == 'confirme';
  bool get isRefuse => statut == 'refuse';
  bool get isTermine => statut == 'termine';
  bool get isAnnule => statut == 'annule';
  bool get isPasse => dateTime.isBefore(DateTime.now());
  bool get isAVenir => dateTime.isAfter(DateTime.now());

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      membreId: data['membreId'] ?? '',
      responsableId: data['responsableId'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      motif: data['motif'] ?? '',
      statut: data['statut'] ?? 'en_attente',
      lieu: data['lieu'] ?? 'en_personne',
      notes: data['notes'],
      notesPrivees: data['notesPrivees'],
      adresse: data['adresse'],
      lienVideo: data['lienVideo'],
      numeroTelephone: data['numeroTelephone'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastModifiedBy: data['lastModifiedBy'],
      dateConfirmation: data['dateConfirmation'] != null 
          ? (data['dateConfirmation'] as Timestamp).toDate() 
          : null,
      dateAnnulation: data['dateAnnulation'] != null 
          ? (data['dateAnnulation'] as Timestamp).toDate() 
          : null,
      raisonAnnulation: data['raisonAnnulation'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'membreId': membreId,
      'responsableId': responsableId,
      'dateTime': Timestamp.fromDate(dateTime),
      'motif': motif,
      'statut': statut,
      'lieu': lieu,
      'notes': notes,
      'notesPrivees': notesPrivees,
      'adresse': adresse,
      'lienVideo': lienVideo,
      'numeroTelephone': numeroTelephone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastModifiedBy': lastModifiedBy,
      'dateConfirmation': dateConfirmation != null 
          ? Timestamp.fromDate(dateConfirmation!) 
          : null,
      'dateAnnulation': dateAnnulation != null 
          ? Timestamp.fromDate(dateAnnulation!) 
          : null,
      'raisonAnnulation': raisonAnnulation,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? statut,
    String? notesPrivees,
    DateTime? updatedAt,
    String? lastModifiedBy,
    DateTime? dateConfirmation,
    DateTime? dateAnnulation,
    String? raisonAnnulation,
    String? adresse,
    String? lienVideo,
    String? numeroTelephone,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      membreId: membreId,
      responsableId: responsableId,
      dateTime: dateTime,
      motif: motif,
      statut: statut ?? this.statut,
      lieu: lieu,
      notes: notes,
      notesPrivees: notesPrivees ?? this.notesPrivees,
      adresse: adresse ?? this.adresse,
      lienVideo: lienVideo ?? this.lienVideo,
      numeroTelephone: numeroTelephone ?? this.numeroTelephone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      dateConfirmation: dateConfirmation ?? this.dateConfirmation,
      dateAnnulation: dateAnnulation ?? this.dateAnnulation,
      raisonAnnulation: raisonAnnulation ?? this.raisonAnnulation,
    );
  }
}

class DisponibiliteModel {
  final String id;
  final String responsableId;
  final String type; // 'recurrence_hebdo', 'recurrence_mensuelle', 'ponctuel'
  final List<String> jours; // ['lundi', 'mardi'] pour récurrence hebdo
  final List<CreneauHoraire> creneaux;
  final DateTime? dateDebut; // Pour les récurrences
  final DateTime? dateFin; // Pour les récurrences
  final DateTime? dateSpecifique; // Pour les créneaux ponctuels
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DisponibiliteModel({
    required this.id,
    required this.responsableId,
    required this.type,
    this.jours = const [],
    this.creneaux = const [],
    this.dateDebut,
    this.dateFin,
    this.dateSpecifique,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRecurrenceHebdo => type == 'recurrence_hebdo';
  bool get isRecurrenceMensuelle => type == 'recurrence_mensuelle';
  bool get isPonctuel => type == 'ponctuel';

  factory DisponibiliteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DisponibiliteModel(
      id: doc.id,
      responsableId: data['responsableId'] ?? '',
      type: data['type'] ?? 'ponctuel',
      jours: List<String>.from(data['jours'] ?? []),
      creneaux: (data['creneaux'] as List<dynamic>? ?? [])
          .map((item) => CreneauHoraire.fromMap(item as Map<String, dynamic>))
          .toList(),
      dateDebut: data['dateDebut'] != null 
          ? (data['dateDebut'] as Timestamp).toDate() 
          : null,
      dateFin: data['dateFin'] != null 
          ? (data['dateFin'] as Timestamp).toDate() 
          : null,
      dateSpecifique: data['dateSpecifique'] != null 
          ? (data['dateSpecifique'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'] ?? true,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'responsableId': responsableId,
      'type': type,
      'jours': jours,
      'creneaux': creneaux.map((c) => c.toMap()).toList(),
      'dateDebut': dateDebut != null ? Timestamp.fromDate(dateDebut!) : null,
      'dateFin': dateFin != null ? Timestamp.fromDate(dateFin!) : null,
      'dateSpecifique': dateSpecifique != null ? Timestamp.fromDate(dateSpecifique!) : null,
      'isActive': isActive,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class CreneauHoraire {
  final String debut; // "14:00"
  final String fin; // "17:00"
  final int? dureeRendezVous; // Durée en minutes (30, 60, etc.)

  CreneauHoraire({
    required this.debut,
    required this.fin,
    this.dureeRendezVous = 30,
  });

  factory CreneauHoraire.fromMap(Map<String, dynamic> map) {
    return CreneauHoraire(
      debut: map['debut'] ?? '',
      fin: map['fin'] ?? '',
      dureeRendezVous: map['dureeRendezVous'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'debut': debut,
      'fin': fin,
      'dureeRendezVous': dureeRendezVous,
    };
  }

  // Génère la liste des créneaux possibles dans cette plage horaire
  List<DateTime> generateSlots(DateTime date) {
    final List<DateTime> slots = [];
    
    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(debut.split(':')[0]),
      int.parse(debut.split(':')[1]),
    );
    
    final endTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(fin.split(':')[0]),
      int.parse(fin.split(':')[1]),
    );

    DateTime current = startTime;
    while (current.add(Duration(minutes: dureeRendezVous!)).isBefore(endTime) || 
           current.add(Duration(minutes: dureeRendezVous!)).isAtSameMomentAs(endTime)) {
      slots.add(current);
      current = current.add(Duration(minutes: dureeRendezVous!));
    }

    return slots;
  }
}

class AppointmentStatisticsModel {
  final int totalAppointments;
  final int pendingAppointments;
  final int confirmedAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final Map<String, int> appointmentsByMonth;
  final Map<String, int> appointmentsByResponsable;
  final Map<String, int> appointmentsByLieu;
  final DateTime lastUpdated;

  AppointmentStatisticsModel({
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.confirmedAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.appointmentsByMonth,
    required this.appointmentsByResponsable,
    required this.appointmentsByLieu,
    required this.lastUpdated,
  });

  double get confirmationRate => totalAppointments > 0 ? confirmedAppointments / totalAppointments : 0.0;
  double get completionRate => confirmedAppointments > 0 ? completedAppointments / confirmedAppointments : 0.0;

  factory AppointmentStatisticsModel.fromMap(Map<String, dynamic> data) {
    return AppointmentStatisticsModel(
      totalAppointments: data['totalAppointments'] ?? 0,
      pendingAppointments: data['pendingAppointments'] ?? 0,
      confirmedAppointments: data['confirmedAppointments'] ?? 0,
      completedAppointments: data['completedAppointments'] ?? 0,
      cancelledAppointments: data['cancelledAppointments'] ?? 0,
      appointmentsByMonth: Map<String, int>.from(data['appointmentsByMonth'] ?? {}),
      appointmentsByResponsable: Map<String, int>.from(data['appointmentsByResponsable'] ?? {}),
      appointmentsByLieu: Map<String, int>.from(data['appointmentsByLieu'] ?? {}),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(data['lastUpdated'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAppointments': totalAppointments,
      'pendingAppointments': pendingAppointments,
      'confirmedAppointments': confirmedAppointments,
      'completedAppointments': completedAppointments,
      'cancelledAppointments': cancelledAppointments,
      'appointmentsByMonth': appointmentsByMonth,
      'appointmentsByResponsable': appointmentsByResponsable,
      'appointmentsByLieu': appointmentsByLieu,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
}