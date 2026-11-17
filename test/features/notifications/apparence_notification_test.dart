import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/home/domain/entities/notification_model.dart';
import 'package:saambiz/features/notifications/presentation/pages/notifications_page.dart';

NotificationModel _n(String type, {Map<String, dynamic> donnees = const {}}) =>
    NotificationModel(
      id: 'n',
      titre: 't',
      message: 'm',
      date: DateTime(2026, 11, 17),
      lue: false,
      type: type,
      donnees: donnees,
    );

void main() {
  group('Groupes par jour', () {
    final midi = DateTime(2026, 11, 17, 12);
    test('aujourd’hui, hier, cette semaine, plus tôt', () {
      expect(
        libelleJourNotification(DateTime(2026, 11, 17, 8), maintenant: midi),
        'Aujourd’hui',
      );
      expect(
        libelleJourNotification(DateTime(2026, 11, 16, 23), maintenant: midi),
        'Hier',
      );
      expect(
        libelleJourNotification(DateTime(2026, 11, 12), maintenant: midi),
        'Cette semaine',
      );
      expect(
        libelleJourNotification(DateTime(2026, 11, 1), maintenant: midi),
        'Plus tôt',
      );
    });
  });

  group('Icône d’une notification', () {
    test('chaque type a la sienne', () {
      expect(
        apparenceNotification(_n('commande')).icone,
        Icons.receipt_long_rounded,
      );
      expect(
        apparenceNotification(_n('promotion')).icone,
        Icons.local_offer_rounded,
      );
      expect(
        apparenceNotification(_n('nouveau_produit')).icone,
        Icons.new_releases_rounded,
      );
      expect(
        apparenceNotification(_n('abonnement')).icone,
        Icons.workspace_premium_rounded,
      );
    });

    test('un message (interlocuteur, sans type) a la bulle', () {
      expect(
        apparenceNotification(
          _n('systeme', donnees: {'interlocuteurId': 'v1'}),
        ).icone,
        Icons.chat_bubble_rounded,
      );
    });

    test('une commande qui nomme un interlocuteur reste une commande', () {
      // Même règle que l'écran à ouvrir : le type passe avant.
      expect(
        apparenceNotification(
          _n(
            'commande',
            donnees: {'commandeId': 'c1', 'interlocuteurId': 'v1'},
          ),
        ).icone,
        Icons.receipt_long_rounded,
      );
    });
  });
}
