class NotificationModel {
  final String id;
  final String titre;
  final String message;
  final DateTime date;
  final bool lue;

  /// Ce que la notification annonce, tel que le serveur le range :
  /// `commande`, `promotion`, `nouveau_produit`, `abonnement` ou `systeme`.
  /// Sert à choisir l'écran à ouvrir quand les données seules ne suffisent pas.
  final String type;

  /// Ce que la notification concerne : `interlocuteurId` et
  /// `interlocuteurNom` (conversation à ouvrir), `commandeId`, `boutiqueId`…
  final Map<String, dynamic> donnees;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
    required this.lue,
    this.type = 'systeme',
    this.donnees = const {},
  });

  /// La personne (ou la boutique) avec qui ouvrir la conversation.
  String? get interlocuteurId {
    final id = donnees['interlocuteurId']?.toString() ?? '';
    return id.isEmpty ? null : id;
  }

  String get interlocuteurNom => donnees['interlocuteurNom']?.toString() ?? '';

  /// Les identifiants que la notification transporte, quand elle en a un.
  ///
  /// Ce sont eux qui décident de l'écran à ouvrir : une notification de
  /// commande porte `commandeId`, une promotion porte `boutiqueId`, et ainsi
  /// de suite. L'ordre de lecture compte — voir `destinationNotification`.
  String? get commandeId => _id('commandeId');
  String? get produitId => _id('produitId');
  String? get boutiqueId => _id('boutiqueId');
  String? get abonnementId => _id('abonnementId');

  /// Vrai quand c'est le vendeur qui lit cette notification.
  ///
  /// La fiche d'une commande n'affiche pas les mêmes boutons des deux côtés.
  /// Dans l'application, l'écran sait déjà où il se trouve ; depuis un push
  /// touché téléphone verrouillé, rien ne le dit — d'où ce drapeau, joint par
  /// le serveur. Les charges de push ne transportent que du texte : `true`
  /// arrive aussi bien en booléen qu'en chaîne.
  bool get pourVendeur =>
      donnees['pourVendeur'] == true ||
      donnees['pourVendeur']?.toString().toLowerCase() == 'true';

  String? _id(String cle) {
    final valeur = donnees[cle]?.toString() ?? '';
    return valeur.isEmpty ? null : valeur;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      date: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lue: json['lue'] ?? false,
      type: json['type']?.toString() ?? 'systeme',
      donnees: json['donnees'] is Map
          ? Map<String, dynamic>.from(json['donnees'] as Map)
          : const {},
    );
  }
}
