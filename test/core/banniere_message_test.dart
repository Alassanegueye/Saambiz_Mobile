import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/services/fcm_service.dart';
import 'package:saambiz/features/notifications/presentation/destination_notification.dart';

/// Un message reçu pendant que l'application est ouverte.
///
/// Le serveur envoie désormais un push à chaque message, pour atteindre un
/// téléphone rangé dans une poche. Mais application ouverte, FCM n'affiche
/// rien : c'est l'application qui dessine la bannière. Sans précaution, elle
/// en dessinait une pour le message que l'utilisateur était en train de lire,
/// par-dessus la conversation elle-même — alors que le temps réel venait de
/// le poser dans le fil.

void main() {
  group('Faut-il dessiner la bannière ?', () {
    test('non, si le message vient de la conversation ouverte', () {
      final utile = FcmService.banniereUtile({
        'interlocuteurId': 'awa',
      }, conversationOuverte: 'awa');
      expect(utile, isFalse);
    });

    test('oui, si le message vient de quelqu’un d’autre', () {
      // On lit Awa, Moussa écrit : il faut le dire, sinon le message attend
      // sans que rien ne le signale.
      final utile = FcmService.banniereUtile({
        'interlocuteurId': 'moussa',
      }, conversationOuverte: 'awa');
      expect(utile, isTrue);
    });

    test('oui, si aucune conversation n’est ouverte', () {
      final utile = FcmService.banniereUtile({
        'interlocuteurId': 'awa',
      }, conversationOuverte: null);
      expect(utile, isTrue);
    });

    test('oui pour ce qui n’est pas un message', () {
      // Une commande prête doit s'afficher même pendant une discussion.
      final utile = FcmService.banniereUtile({
        'commandeId': 'cmd-1',
      }, conversationOuverte: 'awa');
      expect(utile, isTrue);
    });

    test('un identifiant vide ne fait pas taire la bannière', () {
      for (final valeur in ['', null]) {
        expect(
          FcmService.banniereUtile({
            'interlocuteurId': valeur,
          }, conversationOuverte: ''),
          isTrue,
        );
      }
    });
  });

  group('Où mène un message touché', () {
    test('à la conversation de celui qui a écrit', () {
      // C'est tout l'intérêt du push : ouvrir la discussion, pas la liste.
      final d = destinationNotification(
        notificationDepuisPush({
          'type': 'message',
          'interlocuteurId': 'acheteur-1',
          'interlocuteurNom': 'Moussa Ndiaye',
        }),
      );

      expect(d.cible, CibleNotification.conversation);
      expect(d.id, 'acheteur-1');
    });

    test('le nom voyage avec, pour un en-tête tout de suite rempli', () {
      final n = notificationDepuisPush({
        'type': 'message',
        'interlocuteurId': 'vendeur-1',
        'interlocuteurNom': 'Chez Awa',
      });

      expect(n.interlocuteurNom, 'Chez Awa');
    });
  });
}
