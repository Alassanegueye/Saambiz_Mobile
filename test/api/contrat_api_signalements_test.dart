import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/signalements/data/datasources/signalements_remote_datasource.dart';

import '../helpers/dio_espion.dart';

/// Le signalement d'un contenu : ce que le mobile envoie, et par où on y entre.
///
/// Le second groupe est inhabituel pour des tests, et c'est le plus utile ici.
/// Cette fonctionnalité était **entièrement écrite** — formulaire, bloc,
/// datasource, route `POST /signalements` montée et validée côté API — mais
/// aucun écran n'ouvrait le formulaire. Le profil affichait même « Mes
/// signalements », une liste condamnée à rester vide.
///
/// Rien ne pouvait le détecter : l'analyseur ne signale pas un widget public
/// inutilisé, et aucun test d'interface ne traverse cet écran. Le même oubli
/// s'était produit sur les boutons de connexion Google et Apple.
///
/// Or ce n'est pas un simple manque : le règlement de Google Play EXIGE un
/// moyen de signaler, dans l'application, pour toute application qui héberge
/// du contenu publié par ses utilisateurs. SaamBiz en héberge — fiches
/// produits, boutiques, avis, messagerie.
void main() {
  group('Contrat HTTP', () {
    late DioEspion espion;
    late SignalementsRemoteDataSource source;

    setUp(() {
      espion = DioEspion();
      source = SignalementsRemoteDataSourceImpl(dioDeTest(espion));
    });

    test('un produit se signale par POST /signalements', () async {
      espion.repond({
        'signalement': {
          'id': 's1',
          'type': 'produit',
          'raison': 'Contrefaçon',
          'statut': 'en_attente',
        },
      });

      await source.creerSignalement(
        type: 'produit',
        raison: 'Contrefaçon',
        description: 'Ce sac imite une marque.',
        cibleId: 'b3f1c2d4-5e6a-7b8c-9d0e-1f2a3b4c5d6e',
      );

      expect(espion.appel, 'POST /signalements');
      // Les quatre champs que la validation express-validator exige.
      expect(espion.corpsEnvoye['type'], 'produit');
      expect(
        espion.corpsEnvoye['cibleId'],
        'b3f1c2d4-5e6a-7b8c-9d0e-1f2a3b4c5d6e',
      );
      expect(espion.corpsEnvoye['raison'], 'Contrefaçon');
      expect(espion.corpsEnvoye['description'], 'Ce sac imite une marque.');
    });

    test('une boutique se signale par la même route', () async {
      espion.repond({'signalement': {'id': 's2', 'type': 'boutique'}});

      await source.creerSignalement(
        type: 'boutique',
        raison: 'Boutique frauduleuse',
        description: 'Ne livre jamais.',
        cibleId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      );

      expect(espion.corpsEnvoye['type'], 'boutique');
    });

    test('la liste de mes signalements sait défaire son enveloppe', () async {
      // Le backend enveloppe ; le datasource doit retrouver la liste quelle
      // que soit la clé employée.
      espion.repond({
        'signalements': [
          {'id': 's1', 'type': 'produit', 'raison': 'Contrefaçon'},
          {'id': 's2', 'type': 'boutique', 'raison': 'Arnaque'},
        ],
      });

      final liste = await source.mesSignalements();

      expect(espion.appel, 'GET /signalements/mes-signalements');
      expect(liste, hasLength(2));
    });

    test('un refus du serveur remonte à l’appelant', () async {
      // cibleId qui n'est pas un UUID : la validation côté API refuse.
      espion.repondErreur(400, corps: {
        'message': 'L\'identifiant de la cible doit être un UUID valide',
      });

      await expectLater(
        source.creerSignalement(
          type: 'produit',
          raison: 'x',
          description: 'y',
          cibleId: 'pas-un-uuid',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('Le formulaire est atteignable', () {
    // Ces lectures de fichiers remplacent le test d'interface qui n'existe
    // pas. Grossier, mais il attrape exactement le défaut qui s'est produit.
    String lire(String chemin) => File(chemin).readAsStringSync();

    test('la fiche produit propose de signaler', () {
      final page = lire(
        'lib/features/catalogue/presentation/pages/produit_detail_page.dart',
      );
      expect(page, contains('MenuSignaler'));
      expect(page, contains("type: 'produit'"));
    });

    test('la page boutique propose de signaler', () {
      final page = lire(
        'lib/features/catalogue/presentation/pages/boutique_publique_page.dart',
      );
      expect(page, contains('MenuSignaler'));
      expect(page, contains("type: 'boutique'"));
    });

    test('le menu conduit bien au formulaire', () {
      final porte = lire(
        'lib/features/signalements/presentation/ouvrir_signalement.dart',
      );
      expect(porte, contains('SignalerFormPage'));
      // L'API refuse un signalement anonyme : on le dit avant le formulaire,
      // plutôt qu'un 401 une fois celui-ci rempli.
      expect(porte, contains('isAuthenticated'));
    });
  });
}
