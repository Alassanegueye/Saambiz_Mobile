class MessageModel {
  final String id;
  final String expediteurId;
  final String destinataireId;
  final String contenu;
  final bool lu;
  final DateTime? createdAt;

  MessageModel({
    required this.id,
    required this.expediteurId,
    required this.destinataireId,
    required this.contenu,
    required this.lu,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      expediteurId: json['expediteurId']?.toString() ?? '',
      destinataireId: json['destinataireId']?.toString() ?? '',
      contenu: json['contenu']?.toString() ?? '',
      lu: json['lu'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class ConversationModel {
  final String interlocuteurId;
  final String interlocuteurNom;
  final String? interlocuteurPhoto;
  final String dernierMessage;
  final DateTime? dateDernierMessage;
  final int nombreNonLus;

  ConversationModel({
    required this.interlocuteurId,
    required this.interlocuteurNom,
    this.interlocuteurPhoto,
    required this.dernierMessage,
    this.dateDernierMessage,
    this.nombreNonLus = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final interlocuteur =
        (json['interlocuteur'] ?? json['utilisateur']) as Map<String, dynamic>?;
    final dernierMessage = json['dernierMessage'];
    return ConversationModel(
      interlocuteurId: (json['interlocuteurId'] ?? interlocuteur?['id'])?.toString() ?? '',
      interlocuteurNom: interlocuteur != null
          ? '${interlocuteur['prenom'] ?? ''} ${interlocuteur['nom'] ?? ''}'.trim()
          : (json['interlocuteurNom']?.toString() ?? ''),
      interlocuteurPhoto: interlocuteur?['photoProfil']?.toString(),
      dernierMessage: dernierMessage is Map
          ? (dernierMessage['contenu']?.toString() ?? '')
          : (json['contenu']?.toString() ?? ''),
      dateDernierMessage: dernierMessage is Map && dernierMessage['createdAt'] != null
          ? DateTime.tryParse(dernierMessage['createdAt'].toString())
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null),
      nombreNonLus: (json['nombreNonLus'] ?? json['nonLus'] ?? 0) is int
          ? (json['nombreNonLus'] ?? json['nonLus'] ?? 0)
          : int.tryParse('${json['nombreNonLus'] ?? json['nonLus']}') ?? 0,
    );
  }
}
