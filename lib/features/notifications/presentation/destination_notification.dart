import '../../home/domain/entities/notification_model.dart';

/// L'écran qu'une notification doit ouvrir.
enum CibleNotification {
  /// La fiche de la commande concernée.
  commande,

  /// La boutique qui a publié la promotion ou le nouveau produit.
  boutique,

  /// L'abonnement du vendeur.
  abonnement,

  /// La conversation avec l'interlocuteur nommé par la notification.
  conversation,

  /// La certification de la boutique : l'administrateur a tranché.
  certification,

  /// Les produits du vendeur : rupture de stock, modération.
  mesProduits,

  /// La boutique du vendeur : avis reçu, site activé ou coupé.
  maBoutique,

  /// Les abonnés de la boutique.
  abonnes,

  /// Les signalements envoyés par l'utilisateur.
  mesSignalements,

  /// Rien de précis : la liste des conversations, comme avant.
  messagerie,
}

/// Où mène une notification, et avec quel identifiant.
class DestinationNotification {
  final CibleNotification cible;

  /// L'identifiant à présenter à l'écran visé (`null` pour [messagerie]).
  final String? id;

  const DestinationNotification(this.cible, [this.id]);

  @override
  String toString() => 'DestinationNotification($cible, $id)';
}

/// Décide où mène une notification, d'après ce qu'elle transporte.
///
/// Toutes ouvraient la messagerie, quel que soit leur contenu : une
/// notification « Nouvelle commande » menait à une conversation, jamais à la
/// commande. Le serveur joignait pourtant déjà les identifiants utiles
/// (`commandeId`, `boutiqueId`, `abonnementId`) ; personne ne les lisait.
///
/// L'ORDRE DE LECTURE EST LE CŒUR DE LA RÈGLE. Une notification de commande
/// porte à la fois `commandeId` et `interlocuteurId` — l'acheteur ou le
/// vendeur d'en face, pour pouvoir lui écrire. La commande doit gagner :
/// c'est elle qu'on vient voir. L'inverse ramenait à la messagerie, ce qui
/// est précisément le défaut constaté.
DestinationNotification destinationNotification(NotificationModel n) {
  final commande = n.commandeId;
  if (commande != null) {
    return DestinationNotification(CibleNotification.commande, commande);
  }

  // Promotion, nouveau produit, annonce d'une boutique suivie. Le produit
  // concerné n'est pas toujours joint ; la boutique, elle, l'est toujours, et
  // c'est là que le produit se trouve.
  final boutique = n.boutiqueId;
  if (boutique != null) {
    return DestinationNotification(CibleNotification.boutique, boutique);
  }

  final abonnement = n.abonnementId;
  if (abonnement != null || n.type == 'abonnement') {
    return DestinationNotification(CibleNotification.abonnement, abonnement);
  }

  // Réponse à une demande de certification, approuvée ou refusée. Elle ne
  // porte aucun identifiant (ni commande, ni boutique à visiter) et
  // retomberait sinon sur la messagerie. L'écran de certification est celui
  // où le vendeur peut renvoyer ses photos, comme la notification l'y invite.
  if (n.certification != null) {
    return DestinationNotification(CibleNotification.certification);
  }

  // Écrans sans identifiant à viser : le serveur les nomme directement.
  // Une rupture de stock ou un produit refusé mène aux produits du vendeur,
  // un avis reçu à sa boutique — rien de tout cela ne se devine depuis un
  // identifiant, et sans ce nom ces notifications tombaient sur le repli.
  final ecran = n.ecran;
  if (ecran != null) {
    final cible = switch (ecran) {
      'mes_produits' => CibleNotification.mesProduits,
      'ma_boutique' => CibleNotification.maBoutique,
      'abonnes' => CibleNotification.abonnes,
      'mes_signalements' => CibleNotification.mesSignalements,
      _ => null,
    };
    // Un nom d'écran inconnu — une version plus récente du serveur — ne
    // bloque pas la lecture : on continue avec les règles suivantes.
    if (cible != null) return DestinationNotification(cible);
  }

  final interlocuteur = n.interlocuteurId;
  if (interlocuteur != null) {
    return DestinationNotification(
      CibleNotification.conversation,
      interlocuteur,
    );
  }

  // Anciennes notifications, enregistrées avant que le serveur ne joigne des
  // identifiants : elles n'ont rien pour viser un écran. La messagerie reste
  // le repli, comme avant.
  return const DestinationNotification(CibleNotification.messagerie);
}

/// Reconstitue une notification depuis la charge d'un push.
///
/// Le système ne remet que la carte `data` du message, dont les valeurs sont
/// toutes des chaînes — c'est une contrainte de FCM, pas un choix. Le titre et
/// le corps vivent ailleurs dans le message et ne servent pas à l'aiguillage :
/// seuls les identifiants comptent, et ils sont là.
NotificationModel notificationDepuisPush(Map<String, dynamic> donnees) =>
    NotificationModel(
      id: donnees['notificationId']?.toString() ?? '',
      titre: donnees['titre']?.toString() ?? '',
      message: '',
      date: DateTime.now(),
      // Elle vient d'être touchée : la marquer non lue n'aurait aucun sens.
      lue: true,
      type: donnees['type']?.toString() ?? 'systeme',
      donnees: donnees,
    );
