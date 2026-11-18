import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/home/domain/entities/notification_model.dart';
import 'package:saambiz/features/notifications/presentation/destination_notification.dart';

/// Où mène une notification quand on la touche.
///
/// Toutes ouvraient la messagerie, quel que soit leur contenu : « Nouvelle
/// commande » menait à une conversation, jamais à la commande. Le serveur
/// joignait pourtant déjà les identifiants utiles ; personne ne les lisait.

NotificationModel _notif({
  String type = 'systeme',
  Map<String, dynamic> donnees = const {},
}) => NotificationModel(
  id: 'n1',
  titre: 'Titre',
  message: 'Message',
  date: DateTime(2026, 11, 12, 22, 29),
  lue: false,
  type: type,
  donnees: donnees,
);

void main() {
  group('Une commande mène à la commande', () {
    test('même quand un interlocuteur est joint', () {
      // LE CAS QUI ÉTAIT CASSÉ. Une notification de commande porte les deux :
      // `commandeId` et l'interlocuteur d'en face, pour pouvoir lui écrire.
      // Lire l'interlocuteur d'abord ramenait à la messagerie.
      final d = destinationNotification(
        _notif(
          type: 'commande',
          donnees: {
            'commandeId': 'cmd-1',
            'interlocuteurId': 'u-9',
            'interlocuteurNom': 'Balla BEYE',
          },
        ),
      );
      expect(d.cible, CibleNotification.commande);
      expect(d.id, 'cmd-1');
    });

    test('et quand elle est seule', () {
      final d = destinationNotification(
        _notif(type: 'commande', donnees: {'commandeId': 'cmd-2'}),
      );
      expect(d.cible, CibleNotification.commande);
      expect(d.id, 'cmd-2');
    });
  });

  group('Une boutique mène à la boutique', () {
    test('promotion', () {
      final d = destinationNotification(
        _notif(
          type: 'promotion',
          donnees: {'boutiqueId': 'b-1', 'produitId': 'p-1'},
        ),
      );
      expect(d.cible, CibleNotification.boutique);
      expect(d.id, 'b-1');
    });

    test('nouveau produit', () {
      final d = destinationNotification(
        _notif(type: 'nouveau_produit', donnees: {'boutiqueId': 'b-2'}),
      );
      expect(d.cible, CibleNotification.boutique);
      expect(d.id, 'b-2');
    });
  });

  group('Un abonnement mène à l’abonnement', () {
    test('par son identifiant', () {
      final d = destinationNotification(
        _notif(type: 'abonnement', donnees: {'abonnementId': 'a-1'}),
      );
      expect(d.cible, CibleNotification.abonnement);
    });

    test('par son seul type, sans identifiant', () {
      final d = destinationNotification(_notif(type: 'abonnement'));
      expect(d.cible, CibleNotification.abonnement);
    });
  });

  group('Le reste', () {
    test('un interlocuteur seul ouvre la conversation', () {
      final d = destinationNotification(
        _notif(donnees: {'interlocuteurId': 'u-9'}),
      );
      expect(d.cible, CibleNotification.conversation);
      expect(d.id, 'u-9');
    });

    test('une notification sans rien ouvre la messagerie', () {
      // Les anciennes, enregistrées avant que le serveur ne joigne des
      // identifiants. Elles gardent l'ancien comportement.
      expect(
        destinationNotification(_notif()).cible,
        CibleNotification.messagerie,
      );
    });

    test('un identifiant vide ne compte pas pour un identifiant', () {
      expect(
        destinationNotification(_notif(donnees: {'commandeId': ''})).cible,
        CibleNotification.messagerie,
      );
    });
  });

  group('Le modèle lit ce que le serveur envoie', () {
    test('type et données traversent fromJson', () {
      final n = NotificationModel.fromJson({
        'id': 'n1',
        'titre': 'Nouvelle commande',
        'message': 'Commande CMD-2026-N9WEBH — 9000.00 FCFA.',
        'lue': false,
        'type': 'commande',
        'donnees': {'commandeId': 'cmd-1'},
        'createdAt': '2026-11-12T22:29:00.000Z',
      });
      expect(n.type, 'commande');
      expect(n.commandeId, 'cmd-1');
      expect(destinationNotification(n).cible, CibleNotification.commande);
    });

    test('un type absent ne fait pas tomber la lecture', () {
      final n = NotificationModel.fromJson({'id': 'n1', 'titre': 'x'});
      expect(n.type, 'systeme');
      expect(n.commandeId, isNull);
    });
  });

  group('Depuis la charge d’un push', () {
    // FCM n'accepte que des chaînes dans `data` : tout arrive en texte, y
    // compris les booléens. La charge est celle que push.service.js envoie,
    // c'est-à-dire `{type, ...donnees}`.
    test('une commande mène à la commande, du bon côté', () {
      final n = notificationDepuisPush({
        'type': 'commande',
        'commandeId': 'cmd-1',
        'pourVendeur': 'true',
        'interlocuteurId': 'u-9',
        'interlocuteurNom': 'Balla BEYE',
      });
      final d = destinationNotification(n);
      expect(d.cible, CibleNotification.commande);
      expect(d.id, 'cmd-1');
      // Sans ce drapeau, la fiche s'ouvrirait côté acheteur pour un vendeur :
      // ni « Accepter », ni « Passer à : En préparation ».
      expect(n.pourVendeur, isTrue);
    });

    test('l’acheteur reçoit la version acheteur', () {
      final n = notificationDepuisPush({
        'type': 'commande',
        'commandeId': 'cmd-1',
        'pourVendeur': 'false',
      });
      expect(n.pourVendeur, isFalse);
    });

    test('un booléen non chaîné est accepté aussi', () {
      // Dans l'application, la même fonction peut recevoir du JSON déjà typé.
      expect(notificationDepuisPush({'pourVendeur': true}).pourVendeur, isTrue);
    });

    test('le drapeau absent vaut « acheteur »', () {
      expect(notificationDepuisPush({}).pourVendeur, isFalse);
    });

    test('une promotion mène à la boutique', () {
      final d = destinationNotification(
        notificationDepuisPush({'type': 'promotion', 'boutiqueId': 'b-1'}),
      );
      expect(d.cible, CibleNotification.boutique);
      expect(d.id, 'b-1');
    });

    test('une charge vide retombe sur la messagerie', () {
      expect(
        destinationNotification(notificationDepuisPush({})).cible,
        CibleNotification.messagerie,
      );
    });
  });

  group('La réponse à une demande de certification', () {
    test('une certification approuvée mène à l’écran de certification', () {
      // Elle ne porte ni commande ni boutique : sans la clé `certification`,
      // elle retombait sur la messagerie, et le vendeur prévenu que sa
      // boutique était certifiée arrivait dans ses conversations.
      final d = destinationNotification(
        notificationDepuisPush({
          'type': 'systeme',
          'certification': 'approuve',
        }),
      );
      expect(d.cible, CibleNotification.certification);
    });

    test('un refus y mène aussi : c’est là qu’on renvoie ses photos', () {
      final d = destinationNotification(
        notificationDepuisPush({'type': 'systeme', 'certification': 'rejete'}),
      );
      expect(d.cible, CibleNotification.certification);
    });

    test('une notification système ordinaire n’y mène pas', () {
      // Seule la présence de la clé compte, pas le type « systeme », que
      // d'autres annonces utilisent aussi.
      final d = destinationNotification(
        notificationDepuisPush({'type': 'systeme'}),
      );
      expect(d.cible, CibleNotification.messagerie);
    });

    test('une commande garde la priorité sur la certification', () {
      // L'ordre de lecture ne doit pas se déplacer : une notification qui
      // porte une commande ouvre la commande, quoi qu'elle porte d'autre.
      final d = destinationNotification(
        notificationDepuisPush({
          'commandeId': 'cmd-1',
          'certification': 'approuve',
        }),
      );
      expect(d.cible, CibleNotification.commande);
    });
  });
}
