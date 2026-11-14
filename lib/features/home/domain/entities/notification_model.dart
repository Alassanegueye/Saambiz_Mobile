class NotificationModel {
  final String id;
  final String titre;
  final String message;
  final DateTime date;
  final bool lue;

  /// Ce que la notification concerne : `interlocuteurId` et
  /// `interlocuteurNom` (conversation à ouvrir), `commandeId`, `boutiqueId`…
  final Map<String, dynamic> donnees;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
    required this.lue,
    this.donnees = const {},
  });

  /// La personne (ou la boutique) avec qui ouvrir la conversation.
  String? get interlocuteurId {
    final id = donnees['interlocuteurId']?.toString() ?? '';
    return id.isEmpty ? null : id;
  }

  String get interlocuteurNom => donnees['interlocuteurNom']?.toString() ?? '';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      date: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lue: json['lue'] ?? false,
      donnees: json['donnees'] is Map
          ? Map<String, dynamic>.from(json['donnees'] as Map)
          : const {},
    );
  }
}
