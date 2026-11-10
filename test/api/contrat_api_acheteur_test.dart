import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/services/config_publique_service.dart';
import 'package:saambiz/features/catalogue/data/catalogue_remote_datasource.dart';
import 'package:saambiz/features/categories/data/categorie.dart';
import 'package:saambiz/features/commande/data/datasources/commande_remote_datasource.dart';
import 'package:saambiz/features/favoris/data/datasources/favoris_remote_datasource.dart';
import 'package:saambiz/features/messagerie/data/datasources/messagerie_remote_datasource.dart';
import 'package:saambiz/features/notifications/data/datasources/notifications_remote_datasource.dart';

import '../helpers/dio_espion.dart';

/// Contrat HTTP des appels côté acheteur.
///
/// Chaque test vérifie ce que le mobile ENVOIE — verbe et chemin, puis les
/// champs du corps — et ce qu'il SAIT RELIRE dans la réponse, écrite telle que
/// le backend la forme. Ce sont les deux endroits où une faute passe
/// l'analyse statique sans bruit et ne se voit qu'en production.
///
/// Les chemins attendus sont ceux de l'inventaire du backend
/// (`tests/integration/contratRoutesMobile.http.test.js`), qui garantit de son
/// côté que ces routes existent et sont protégées comme il faut.
void main() {
  late DioEspion espion;
  late Dio dio;

  setUp(() {
    espion = DioEspion();
    dio = dioDeTest(espion);
  });

  group('Catalogue public', () {
    test('la liste des produits est paginée et filtrable', () async {
      espion.repond({
        'success': true,
        'produits': [],
        'pagination': {'page': 2, 'limit': 20, 'total': 0, 'pages': 0},
      });

      final page = await CatalogueRemoteDataSource(
        dio,
      ).produits(categorie: 'mode-homme', recherche: 'wax', page: 2, promo: true);

      expect(espion.appel, 'GET /catalogue/produits');
      expect(espion.requete.queryParameters['categorie'], 'mode-homme');
      // La recherche part sous `q`, pas sous `recherche` : le backend ne lit
      // que `q`, et l'écart ne produirait aucune erreur, juste une recherche
      // qui ignore le mot saisi.
      expect(espion.requete.queryParameters['q'], 'wax');
      expect(espion.requete.queryParameters['promo'], '1');
      expect(espion.requete.queryParameters['page'], 2);
      expect(page.total, 0);
    });

    test('la fiche produit relit la réponse du backend', () async {
      espion.repond({
        'success': true,
        'produit': {
          'id': 'p1',
          'nom': 'Chemise en wax',
          'prix': 22000,
          'quantite': 14,
        },
        'similaires': [],
      });

      final res = await CatalogueRemoteDataSource(dio).detail('p1');

      expect(espion.appel, 'GET /catalogue/produits/p1');
      expect(res.produit.nom, 'Chemise en wax');
    });

    test('les promotions ont leur propre route', () async {
      espion.repond({
        'success': true,
        'produits': [],
        'pagination': {'total': 0},
      });

      await CatalogueRemoteDataSource(dio).promotions();

      expect(espion.appel, 'GET /catalogue/promotions');
    });

    test('la recherche de boutiques', () async {
      espion.repond({'success': true, 'boutiques': []});

      await CatalogueRemoteDataSource(dio).rechercherBoutiques('alou');

      expect(espion.appel, 'GET /catalogue/boutiques');
    });

    test('la fiche boutique', () async {
      espion.repond({
        'success': true,
        'boutique': {'id': 'b1', 'nom': 'Aloushop'},
        'produits': [],
      });

      await CatalogueRemoteDataSource(dio).boutique('b1');

      expect(espion.appel, 'GET /catalogue/boutiques/b1');
    });

    test("l'ouverture d'une fiche est comptabilisée", () async {
      // Ce compteur alimente « Visites » chez le vendeur et le tri
      // `populaires` : il était absent de l'application.
      espion.repond({'success': true});

      await CatalogueRemoteDataSource(dio).signalerVue('p1');

      expect(espion.appel, 'POST /acheteurs/produit/p1/vue');
    });

    test('un échec du compteur de vues ne remonte pas', () async {
      espion.repondErreur(500, corps: {'message': 'boum'});

      // Ne doit pas lever : une vue perdue ne vaut pas un écran en erreur.
      await CatalogueRemoteDataSource(dio).signalerVue('p1');

      expect(espion.appel, 'POST /acheteurs/produit/p1/vue');
    });
  });

  group('Catégories', () {
    test('la liste est lue sous la clé `categories`', () async {
      espion.repond({
        'success': true,
        'categories': [
          {'id': 'c1', 'nom': 'Mode homme', 'slug': 'mode-homme'},
        ],
      });

      final liste = await CategoriesRemoteDataSource(dio).lister(forcer: true);

      expect(espion.appel, 'GET /categories');
      expect(liste.first.nom, 'Mode homme');
    });

    test('la fiche d’une catégorie', () async {
      espion.repond({
        'success': true,
        'categorie': {'id': 'c1', 'nom': 'Mode homme', 'slug': 'mode-homme'},
      });

      final fiche = await CategoriesRemoteDataSource(dio).fiche('mode-homme');

      expect(espion.appel, 'GET /categories/mode-homme');
      expect(fiche?.nom, 'Mode homme');
    });

    test('les boutiques d’une catégorie sont paginées', () async {
      // Le backend envoie toujours l'en-tête `categorie` avec la page.
      espion.repond({
        'success': true,
        'categorie': {'id': 'c1', 'nom': 'Mode homme', 'slug': 'mode-homme'},
        'boutiques': [],
        'pagination': {'page': 1, 'limit': 20, 'total': 0},
      });

      await CategoriesRemoteDataSource(dio).boutiques('mode-homme', page: 3);

      expect(espion.appel, 'GET /categories/mode-homme/boutiques');
      expect(espion.requete.queryParameters['page'], 3);
    });
  });

  group('Commandes', () {
    test('la création envoie exactement ce que le backend valide', () async {
      espion.repond({
        'success': true,
        'commande': {
          'id': 'c1',
          'referenceCommande': 'SB-1',
          'montantTotal': 24000,
          'statut': 'en_attente',
        },
      });

      await CommandeRemoteDataSourceImpl(dio).creerCommande({
        'items': [
          {'produitId': 'p1', 'quantite': 2},
        ],
        'modeLivraison': 'livraison',
        'modePaiement': 'a_la_livraison',
        'adresseLivraison': 'Sacré-Cœur 3',
      });

      expect(espion.appel, 'POST /commandes');
      // Le schéma Joi du backend exige `items[].produitId` et `quantite`.
      final items = espion.corpsEnvoye['items'] as List;
      expect(items.first['produitId'], 'p1');
      expect(items.first['quantite'], 2);
      expect(espion.corpsEnvoye['modePaiement'], 'a_la_livraison');
    });

    test('mes commandes se filtrent par statut', () async {
      espion.repond({'success': true, 'commandes': []});

      await CommandeRemoteDataSourceImpl(dio).mesCommandes(statut: 'livree');

      expect(espion.appel, 'GET /commandes');
      expect(espion.requete.queryParameters['statut'], 'livree');
    });

    test('les commandes du vendeur ont leur route dédiée', () async {
      espion.repond({'success': true, 'commandes': []});

      await CommandeRemoteDataSourceImpl(dio).commandesVendeur();

      expect(espion.appel, 'GET /commandes/vendeur');
    });

    test('le changement de statut passe par PATCH', () async {
      // Un PUT ici répondrait 404 : la route backend est bien un PATCH.
      espion.repond({
        'success': true,
        'commande': {'id': 'c1', 'statut': 'confirmee'},
      });

      await CommandeRemoteDataSourceImpl(dio).changerStatut('c1', 'confirmee');

      expect(espion.appel, 'PATCH /commandes/c1/statut');
      expect(espion.corpsEnvoye['statut'], 'confirmee');
    });

    test("l'annulation passe par PUT", () async {
      espion.repond({
        'success': true,
        'commande': {'id': 'c1', 'statut': 'annulee'},
      });

      await CommandeRemoteDataSourceImpl(dio).annuler('c1');

      expect(espion.appel, 'PUT /commandes/c1/annuler');
    });

    test('le paiement envoie la méthode attendue', () async {
      espion.repond({'success': true, 'paymentUrl': 'https://paiement/x'});

      final url = await CommandeRemoteDataSourceImpl(
        dio,
      ).payer('c1', methode: 'wave', numeroTelephone: '77 123 45 67');

      expect(espion.appel, 'POST /commandes/c1/payer');
      expect(espion.corpsEnvoye['methode'], 'wave');
      expect(url, 'https://paiement/x');
    });

    test('la demande de retour porte sa raison', () async {
      espion.repond({'success': true});

      await CommandeRemoteDataSourceImpl(
        dio,
      ).demandeRetour('c1', raison: 'Article abîmé');

      expect(espion.appel, 'POST /commandes/c1/demande-retour');
      expect(espion.corpsEnvoye['raison'], 'Article abîmé');
    });
  });

  group('Favoris', () {
    test('suivre une boutique', () async {
      espion.repond({'success': true});

      await FavorisRemoteDataSourceImpl(dio).ajouter('b1');

      expect(espion.appel, 'POST /favoris');
      expect(espion.corpsEnvoye['boutiqueId'], 'b1');
    });

    test('ne plus suivre', () async {
      espion.repond({'success': true});

      await FavorisRemoteDataSourceImpl(dio).supprimer('b1');

      expect(espion.appel, 'DELETE /favoris/b1');
    });

    test('la cloche passe par PATCH', () async {
      espion.repond({'success': true, 'clocheActive': true});

      await FavorisRemoteDataSourceImpl(dio).toggleCloche('b1', true);

      expect(espion.appel, 'PATCH /favoris/b1/cloche');
    });

    test('état de suivi', () async {
      espion.repond({'success': true, 'suivi': true, 'clocheActive': false});

      final statut = await FavorisRemoteDataSourceImpl(dio).statutSuivi('b1');

      expect(espion.appel, 'GET /favoris/b1/statut');
      expect(statut['suivi'], isTrue);
    });
  });

  group('Messagerie', () {
    test('envoyer un message', () async {
      espion.repond({
        'success': true,
        'message': {'id': 'm1', 'contenu': 'Bonjour'},
      });

      await MessagerieRemoteDataSourceImpl(
        dio,
      ).envoyerMessage(destinataireId: 'u2', contenu: 'Bonjour');

      expect(espion.appel, 'POST /messages');
      expect(espion.corpsEnvoye['contenu'], 'Bonjour');
    });

    test('les conversations', () async {
      espion.repond({'success': true, 'conversations': []});

      await MessagerieRemoteDataSourceImpl(dio).conversations();

      expect(espion.appel, 'GET /messages/conversations');
    });

    test("l'historique d'un fil", () async {
      espion.repond({'success': true, 'messages': []});

      await MessagerieRemoteDataSourceImpl(dio).historique('u2');

      expect(espion.appel, 'GET /messages/u2');
    });

    test('marquer lu passe par PUT', () async {
      espion.repond({'success': true});

      await MessagerieRemoteDataSourceImpl(dio).marquerLu('m1');

      expect(espion.appel, 'PUT /messages/m1/lire');
    });

    test('le compteur de non-lus', () async {
      espion.repond({'success': true, 'nonLus': 4});

      final n = await MessagerieRemoteDataSourceImpl(dio).nombreNonLus();

      expect(espion.appel, 'GET /messages/non-lus');
      expect(n, 4);
    });
  });

  group('Notifications', () {
    test('la liste', () async {
      espion.repond({'success': true, 'notifications': []});

      await NotificationsRemoteDataSourceImpl(dio).notifications();

      expect(espion.appel, 'GET /notifications');
    });

    test('le compteur de non-lues', () async {
      espion.repond({'success': true, 'nonLues': 3});

      final n = await NotificationsRemoteDataSourceImpl(dio).nombreNonLues();

      expect(espion.appel, 'GET /notifications/non-lues');
      expect(n, 3);
    });

    test('tout marquer lu', () async {
      espion.repond({'success': true});

      await NotificationsRemoteDataSourceImpl(dio).marquerToutesLues();

      expect(espion.appel, 'PUT /notifications/toutes-lues');
    });

    test('marquer une notification lue', () async {
      espion.repond({'success': true});

      await NotificationsRemoteDataSourceImpl(dio).marquerLue('n1');

      expect(espion.appel, 'PUT /notifications/n1/lire');
    });

    test("l'enregistrement du jeton d'appareil", () async {
      espion.repond({'success': true});

      await NotificationsRemoteDataSourceImpl(
        dio,
      ).registerDeviceToken(token: 'tok', platform: 'ios');

      expect(espion.appel, 'POST /device-token/register');
      expect(espion.corpsEnvoye['platform'], 'ios');
    });

    test('le retrait du jeton passe par DELETE', () async {
      espion.repond({'success': true});

      await NotificationsRemoteDataSourceImpl(dio).unregisterDeviceToken('tok');

      expect(espion.appel, 'DELETE /device-token/unregister');
    });
  });

  group('Réglages publics', () {
    test('le prix de l’abonnement vient du serveur', () async {
      espion.repond({'prix': 2000, 'devise': 'FCFA'});

      final prix = await ConfigPubliqueService(dio).prixAbonnement();

      expect(espion.appel, 'GET /prix-abonnement');
      expect(prix, 2000);
    });

    test('un prix absent ou nul ne passe pas pour un prix', () async {
      // Renvoyer 0 ferait repartir l'écran d'abonnement vers un paiement que
      // le backend refuse.
      espion.repond({'prix': 0, 'devise': 'FCFA'});

      expect(await ConfigPubliqueService(dio).prixAbonnement(), isNull);
    });

    test('le serveur injoignable ne fait pas tomber l’appelant', () async {
      espion.repondErreur(503);

      expect(await ConfigPubliqueService(dio).prixAbonnement(), isNull);
    });

    test('l’état de service est relu entièrement', () async {
      espion.repond({
        'minVersionAndroid': '1.2.0',
        'minVersionIos': '1.3.0',
        'maintenance': true,
        'message': 'Retour à 14h',
      });

      final config = await ConfigPubliqueService(dio).configApp();

      expect(espion.appel, 'GET /app/config');
      expect(config!.maintenance, isTrue);
      expect(config.message, 'Retour à 14h');
      expect(config.miseAJourExigee('1.2.9', ios: true), isTrue);
      expect(config.miseAJourExigee('1.2.9', ios: false), isFalse);
    });
  });
}
