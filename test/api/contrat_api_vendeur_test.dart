import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/abonnement/data/datasources/abonnement_remote_datasource.dart';
import 'package:saambiz/features/boutique/data/datasources/boutique_remote_datasource.dart';
import 'package:saambiz/features/compte/data/datasources/compte_remote_datasource.dart';
import 'package:saambiz/features/promotions/data/datasources/promotions_remote_datasource.dart';
import 'package:saambiz/features/signalements/data/datasources/signalements_remote_datasource.dart';
import 'package:saambiz/features/vendeur/data/datasources/vendeur_produit_datasource.dart';
import 'package:saambiz/features/vitrine/data/datasources/vitrine_remote_datasource.dart';

import '../helpers/dio_espion.dart';

/// Contrat HTTP des appels côté vendeur et compte.
///
/// Même principe que le contrat acheteur : on vérifie le verbe, le chemin et
/// les champs envoyés, puis la relecture de la réponse telle que le backend
/// la forme.
void main() {
  late DioEspion espion;
  late Dio dio;

  setUp(() {
    espion = DioEspion();
    dio = dioDeTest(espion);
  });

  group('Produits du vendeur', () {
    test('la liste', () async {
      espion.repond({'success': true, 'produits': []});

      await VendeurProduitDataSource(dio).mesProduits();

      expect(espion.appel, 'GET /vendeur/liste-produits');
    });

    test('les catégories du formulaire', () async {
      espion.repond({'success': true, 'categories': []});

      await VendeurProduitDataSource(dio).categories();

      expect(espion.appel, 'GET /categories');
    });

    test("l'ajout part en multipart avec tous les champs", () async {
      espion.repond({'success': true});

      await VendeurProduitDataSource(dio).ajouterProduit(
        nom: 'Chemise en wax',
        description: 'Coupe droite',
        prix: 22000,
        quantite: 14,
        categorieId: 'c1',
        attributs: {'tailles': 'M,L'},
      );

      expect(espion.appel, 'POST /vendeur/ajout-produit');
      // Multer lit des champs de formulaire, pas du JSON : envoyer un corps
      // JSON ici produirait un 400 sur un produit pourtant complet.
      expect(espion.requete.data, isA<FormData>());
      final champs = espion.champsMultipart;
      expect(champs['nom'], 'Chemise en wax');
      expect(champs['prix'], '22000');
      expect(champs['quantite'], '14');
      expect(champs['categorieId'], 'c1');
    });

    test('la suppression', () async {
      espion.repond({'success': true});

      await VendeurProduitDataSource(dio).supprimerProduit('p1');

      expect(espion.appel, 'DELETE /vendeur/supprimer-produit/p1');
    });

    test('la mise en ligne passe par PATCH', () async {
      espion.repond({'success': true});

      await VendeurProduitDataSource(dio).toggleDisponibilite('p1');

      expect(espion.appel, 'PATCH /vendeur/produit/p1/disponibilite');
    });

    test('la duplication', () async {
      espion.repond({'success': true});

      await VendeurProduitDataSource(dio).dupliquerProduit('p1');

      expect(espion.appel, 'POST /vendeur/produit/p1/dupliquer');
    });

    test("le retrait d'une image", () async {
      espion.repond({'success': true});

      await VendeurProduitDataSource(dio).supprimerImage('p1', 'i1');

      expect(espion.appel, 'DELETE /vendeur/produit/p1/images/i1');
    });

    test('la recherche', () async {
      espion.repond({'success': true, 'produits': []});

      await VendeurProduitDataSource(dio).rechercheProduits('wax');

      expect(espion.appel, 'GET /vendeur/recherche-produits');
    });
  });

  group('Tableau de bord', () {
    test('les statistiques sont lues sous `stats`', () async {
      // L'écran lit `data['stats']['chiffreAffaires']` : une enveloppe
      // différente afficherait 0 FCFA sans la moindre erreur.
      espion.repond({
        'success': true,
        'data': {
          'stats': {
            'chiffreAffaires': 487500,
            'nombreCommandes': 23,
            'totalVues': 1842,
            'nombreAbonnes': 156,
          },
          'notificationsNonLues': 3,
        },
      });

      final res = await VendeurProduitDataSource(dio).dashboard();

      expect(espion.appel, 'GET /vendeur/dashboard');
      expect((res['stats'] as Map)['chiffreAffaires'], 487500);
      expect(res['notificationsNonLues'], 3);
    });

    test('une réponse sans enveloppe `data` est lue aussi', () async {
      espion.repond({
        'success': true,
        'stats': {'chiffreAffaires': 1000},
      });

      final res = await VendeurProduitDataSource(dio).dashboard();

      expect((res['stats'] as Map)['chiffreAffaires'], 1000);
    });

    test('les vues détaillées', () async {
      espion.repond({'success': true, 'data': {}});

      await VendeurProduitDataSource(dio).statistiquesVues();

      expect(espion.appel, 'GET /vendeur/statistiques-vues');
    });

    test('le nombre de produits', () async {
      espion.repond({'success': true, 'data': {}});

      await VendeurProduitDataSource(dio).nombreProduit();

      expect(espion.appel, 'GET /vendeur/nombre-produit');
    });
  });

  group('Boutique', () {
    test('ma boutique', () async {
      espion.repond({
        'success': true,
        'boutique': {'id': 'b1', 'nom': 'Aloushop'},
      });

      await BoutiqueRemoteDataSourceImpl(dio).getMaBoutique();

      expect(espion.appel, 'GET /vendeur/ma-boutique');
    });

    test('la mise en pause passe par PATCH', () async {
      espion.repond({'success': true});

      await BoutiqueRemoteDataSourceImpl(dio).pauseBoutique();

      expect(espion.appel, 'PATCH /vendeur/boutique/pause');
    });

    test('la réactivation', () async {
      espion.repond({'success': true});

      await BoutiqueRemoteDataSourceImpl(dio).reactiverBoutique();

      expect(espion.appel, 'PATCH /vendeur/boutique/reactiver');
    });

    test("l'état de la demande de vérification", () async {
      // Route existante côté backend, qui n'était appelée par personne.
      espion.repond({
        'success': true,
        'data': {'statutValidation': 'en_attente'},
      });

      final res = await BoutiqueRemoteDataSourceImpl(dio).statutVerification();

      expect(espion.appel, 'GET /vendeur/statut-verification');
      expect(res['statutValidation'], 'en_attente');
    });

    test('le dépôt du dossier de vérification', () async {
      espion.repond({'success': true, 'data': {}});

      await BoutiqueRemoteDataSourceImpl(
        dio,
      ).soumettreVerification({'registreCommerce': 'RC-123'});

      expect(espion.appel, 'POST /vendeur/soumettre-verification');
      expect(espion.corpsEnvoye['registreCommerce'], 'RC-123');
    });

    test("la fiche d'un abonné", () async {
      espion.repond({
        'success': true,
        'data': {'id': 'a1', 'nom': 'Awa Diop'},
      });

      final res = await BoutiqueRemoteDataSourceImpl(dio).abonne('a1');

      expect(espion.appel, 'GET /vendeur/abonnes/a1');
      expect(res['nom'], 'Awa Diop');
    });
  });

  group('Vitrine', () {
    test('les secteurs proposés', () async {
      espion.repond({'success': true, 'secteurs': []});

      await VitrineRemoteDataSourceImpl(dio).getSecteurs();

      expect(espion.appel, 'GET /vendeur/vitrine/secteurs');
    });

    test("l'aperçu avant publication", () async {
      // Route existante côté backend, qui n'était appelée par personne.
      espion.repond({'success': true, 'html': '<html></html>'});

      final res = await VitrineRemoteDataSourceImpl(dio).apercu();

      expect(espion.appel, 'GET /vendeur/ma-vitrine/apercu');
      expect(res['html'], '<html></html>');
    });

    test('la suppression du site', () async {
      espion.repond({'success': true});

      await VitrineRemoteDataSourceImpl(dio).supprimerVitrine();

      expect(espion.appel, 'DELETE /vendeur/ma-vitrine');
    });

    test('un refus du serveur remonte à l\'appelant', () async {
      // L'écran doit pouvoir afficher le message plutôt que de laisser croire
      // que le site a été retiré.
      espion.repondErreur(403, corps: {'message': 'Abonnement expiré'});

      await expectLater(
        VitrineRemoteDataSourceImpl(dio).supprimerVitrine(),
        throwsA(isA<DioException>()),
      );
    });

    // Les photos du haut du site : chaque route répond le site à jour, dans
    // l'enveloppe `{ success, message, data: { vitrine, boutique } }`.
    Map<String, dynamic> siteAJour(List<Map<String, String>> photos) => {
      'success': true,
      'message': '2 photos ajoutées à votre site.',
      'data': {
        'vitrine': {
          'slug': 'maison-ndella',
          'url': 'https://saambiz.com/b/maison-ndella',
          'photos': photos,
          'photosMax': 10,
        },
        'boutique': {
          'nom': 'Maison Ndella',
          'slogan': 'La déco qui vous ressemble',
        },
      },
    };

    test(
      "l'ajout de photos part en multipart, toutes sous « photos »",
      () async {
        final dossier = Directory.systemTemp.createTempSync('photos_site');
        addTearDown(() => dossier.deleteSync(recursive: true));
        final chemins = [
          for (final nom in ['a.jpg', 'b.png'])
            (File(
              '${dossier.path}/$nom',
            )..writeAsBytesSync([0xFF, 0xD8, 0xFF])).path,
        ];
        espion.repond(
          siteAJour([
            {'id': 'p1', 'url': 'https://res.cloudinary.com/x/a.jpg'},
            {'id': 'p2', 'url': 'https://res.cloudinary.com/x/b.png'},
          ]),
        );

        final res = await VitrineRemoteDataSourceImpl(
          dio,
        ).ajouterPhotos(chemins);

        expect(espion.appel, 'POST /vendeur/ma-vitrine/photos');
        // Multer lit `upload.array('photos')` : un seul nom de champ, répété.
        final form = espion.requete.data as FormData;
        expect(form.files.map((f) => f.key), ['photos', 'photos']);
        expect(form.files.map((f) => f.value.contentType?.mimeType), [
          'image/jpeg',
          'image/png',
        ]);
        expect(res.vitrine.photos.map((p) => p.id), ['p1', 'p2']);
        expect(res.vitrine.slogan, 'La déco qui vous ressemble');
        // La phrase du serveur dit ce qui est entré : l'écran la reprend.
        expect(res.message, '2 photos ajoutées à votre site.');
      },
    );

    test("le retrait d'une photo", () async {
      espion.repond(
        siteAJour([
          {'id': 'p2', 'url': 'https://res.cloudinary.com/x/b.png'},
        ]),
      );

      final v = await VitrineRemoteDataSourceImpl(dio).retirerPhoto('p1');

      expect(espion.appel, 'DELETE /vendeur/ma-vitrine/photos/p1');
      expect(v.photos.map((p) => p.id), ['p2']);
    });

    test("l'ordre des photos part en JSON, par identifiants", () async {
      espion.repond(
        siteAJour([
          {'id': 'p2', 'url': 'https://res.cloudinary.com/x/b.png'},
          {'id': 'p1', 'url': 'https://res.cloudinary.com/x/a.jpg'},
        ]),
      );

      final v = await VitrineRemoteDataSourceImpl(
        dio,
      ).ordonnerPhotos(['p2', 'p1']);

      expect(espion.appel, 'PUT /vendeur/ma-vitrine/photos/ordre');
      expect(espion.corpsEnvoye, {
        'ids': ['p2', 'p1'],
      });
      expect(v.photos.map((p) => p.id), ['p2', 'p1']);
    });

    test('une photo sans identifiant ou sans adresse est écartée', () async {
      // On ne pourrait ni l'afficher, ni la retirer.
      espion.repond(
        siteAJour([
          {'id': 'p1', 'url': 'https://res.cloudinary.com/x/a.jpg'},
          {'id': '', 'url': 'https://res.cloudinary.com/x/b.jpg'},
          {'id': 'p3', 'url': ''},
        ]),
      );

      final v = await VitrineRemoteDataSourceImpl(dio).getMaVitrine();

      expect(v.photos.map((p) => p.id), ['p1']);
      expect(v.photosMax, 10);
    });
  });

  group('Promotions', () {
    test('les promotions actives', () async {
      espion.repond({'success': true, 'promotions': []});

      await PromotionsRemoteDataSourceImpl(dio).promotionsActives();

      expect(espion.appel, 'GET /promotions/actives');
    });

    test('mes promotions', () async {
      espion.repond({'success': true, 'promotions': []});

      await PromotionsRemoteDataSourceImpl(dio).mesPromotions();

      expect(espion.appel, 'GET /promotions');
    });

    test('la suppression', () async {
      espion.repond({'success': true});

      await PromotionsRemoteDataSourceImpl(dio).supprimerPromotion('pr1');

      expect(espion.appel, 'DELETE /promotions/pr1');
    });
  });

  group('Signalements', () {
    test('mes signalements', () async {
      espion.repond({'success': true, 'signalements': []});

      await SignalementsRemoteDataSourceImpl(dio).mesSignalements();

      expect(espion.appel, 'GET /signalements/mes-signalements');
    });
  });

  group('Abonnement et paiement', () {
    test('mon abonnement', () async {
      espion.repond({
        'success': true,
        'abonnement': {'id': 'a1', 'statut': 'actif'},
      });

      await AbonnementRemoteDataSourceImpl(dio).monAbonnement();

      expect(espion.appel, 'GET /vendeur/mon-abonnement');
    });

    test('le renouvellement rend un identifiant de paiement', () async {
      espion.repond({'success': true, 'paiementId': 'pay1'});

      final id = await AbonnementRemoteDataSourceImpl(
        dio,
      ).initierRenouvellement(montant: 2000);

      expect(espion.appel, 'POST /vendeur/initier-renouvellement');
      expect(espion.corpsEnvoye['montant'], 2000);
      expect(id, 'pay1');
    });

    test('le paiement envoie les trois champs exigés', () async {
      // Le contrôleur refuse la requête si l'un des trois manque.
      espion.repond({'success': true, 'paymentUrl': 'https://pay/x'});

      final res = await AbonnementRemoteDataSourceImpl(dio).payer(
        montant: 2000,
        numeroTelephone: '77 123 45 67',
        methode: 'orange_money',
      );

      expect(espion.appel, 'POST /paiement/payer');
      expect(
        espion.corpsEnvoye.keys,
        containsAll(['montant', 'numeroTelephone', 'methode']),
      );
      expect(res['paymentUrl'], 'https://pay/x');
    });

    test("l'historique des paiements de l'abonnement", () async {
      espion.repond({'success': true, 'paiements': []});

      await AbonnementRemoteDataSourceImpl(dio).historiquePaiementsAbonnement();

      expect(espion.appel, 'GET /vendeur/historique-paiements');
    });
  });

  group('Compte', () {
    test('mon profil', () async {
      espion.repond({
        'success': true,
        'utilisateur': {'id': 'u1', 'nom': 'Ndiaye', 'prenom': 'Alioune'},
      });

      await CompteRemoteDataSourceImpl(dio).getMe();

      expect(espion.appel, 'GET /account/me');
    });

    test('le changement de mot de passe', () async {
      espion.repond({'success': true});

      await CompteRemoteDataSourceImpl(dio).changePassword(
        ancienMotDePasse: 'ancien',
        nouveauMotDePasse: 'nouveau',
      );

      expect(espion.appel, 'PUT /account/change-password');
    });

    test('le mot de passe oublié', () async {
      espion.repond({'success': true});

      await CompteRemoteDataSourceImpl(dio).forgotPassword('a@b.sn');

      expect(espion.appel, 'POST /account/forgot-password');
      expect(espion.corpsEnvoye['email'], 'a@b.sn');
    });

    test('la réinitialisation envoie le code sous le nom « otp »', () async {
      // Le code partait sous le nom « code ». Le schéma Joi du serveur veut
      // « otp » et n'autorise aucun champ qu'il ne connaît pas : il répondait
      // 400 « Le code OTP est requis, "code" is not allowed ». Personne ne
      // pouvait réinitialiser son mot de passe, avec le bon code sous les
      // yeux — et depuis toujours, pas depuis une régression.
      //
      // Le changement de mot de passe et le mot de passe oublié ont leur
      // propre test ci-dessus ; cette ligne-là n'en avait aucun.
      espion.repond({'success': true});

      await CompteRemoteDataSourceImpl(dio).resetPassword(
        email: 'a@b.sn',
        code: '548229',
        nouveauMotDePasse: 'Passer@1234',
      );

      expect(espion.appel, 'POST /account/reset-password');
      expect(espion.corpsEnvoye['otp'], '548229');
      expect(espion.corpsEnvoye['email'], 'a@b.sn');
      expect(espion.corpsEnvoye['nouveauMotDePasse'], 'Passer@1234');
      // Rien d'autre : un champ en trop suffit à faire refuser l'envoi.
      expect(espion.corpsEnvoye.keys.toSet(), {
        'email',
        'otp',
        'nouveauMotDePasse',
      });
    });

    test('la suppression de compte passe par DELETE /account/me', () async {
      // Exigence des deux magasins : l'utilisateur doit pouvoir supprimer son
      // compte depuis l'application.
      espion.repond({'success': true});

      await CompteRemoteDataSourceImpl(dio).deleteAccount(motif: 'au revoir');

      expect(espion.appel, 'DELETE /account/me');
    });
  });
}
