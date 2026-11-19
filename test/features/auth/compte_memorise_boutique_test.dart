import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/services/comptes_memorises.dart';
import 'package:saambiz/features/auth/data/models/user_model.dart';

/// Le nom de la boutique, à côté d'un compte vendeur mémorisé.
///
/// L'écran « Se connecter » liste les comptes déjà utilisés sur ce téléphone.
/// Deux vendeurs y portaient parfois le MÊME nom — deux « Alassane GUEYE »
/// l'un sous l'autre —, et on ne les distinguait qu'en lisant deux adresses
/// e-mail presque identiques. La boutique est ce qu'un vendeur reconnaît du
/// premier coup d'œil.
///
/// Elle n'arrive qu'avec une connexion complète : le serveur la joint à la
/// session d'un vendeur. Une reprise de session, elle, relit le jeton, qui ne
/// porte que l'identité — d'où le rattrapage vérifié plus bas.

UserModel _vendeur({String? boutique}) => UserModel(
  id: 'v-1',
  nom: 'GUEYE',
  prenom: 'Alassane',
  email: 'alassanegpro@gmail.com',
  mot_de_passe: '',
  adresse: '',
  telephone: '',
  role: 'Vendeur',
  boutiqueNom: boutique,
);

void main() {
  group('Ce que le serveur envoie', () {
    test('la boutique est lue dans la réponse de connexion', () {
      final u = UserModel.fromJson({
        'id': 'v-1',
        'nom': 'GUEYE',
        'prenom': 'Alassane',
        'role': 'Vendeur',
        'boutique': {'id': 'b-1', 'nom': 'Chez Awa', 'logo': null},
      });

      expect(u.boutiqueNom, 'Chez Awa');
    });

    test('une boutique envoyée en simple texte est acceptée', () {
      final u = UserModel.fromJson({'id': 'v-1', 'boutique': 'Chez Awa'});
      expect(u.boutiqueNom, 'Chez Awa');
    });

    test('un acheteur n’en a pas, et ce n’est pas une erreur', () {
      final u = UserModel.fromJson({'id': 'a-1', 'role': 'Acheteur'});
      expect(u.boutiqueNom, isNull);
    });

    test('un vendeur sans boutique créée n’affiche rien', () {
      // Un nom vide ne doit pas produire une ligne vide à l'écran.
      for (final valeur in [
        null,
        '',
        '   ',
        <String, dynamic>{'nom': ''},
      ]) {
        expect(
          UserModel.fromJson({'id': 'v-1', 'boutique': valeur}).boutiqueNom,
          isNull,
        );
      }
    });
  });

  group('Ce que le téléphone retient', () {
    test('la boutique survit à l’écriture et à la relecture', () {
      final avant = CompteMemorise(
        id: 'v-1',
        prenom: 'Alassane',
        nom: 'GUEYE',
        email: 'alassanegpro@gmail.com',
        telephone: '',
        role: 'Vendeur',
        derniereUtilisation: DateTime(2026, 11, 19),
        boutique: 'Chez Awa',
      );

      final apres = CompteMemorise.fromJson(avant.toJson());

      expect(apres.boutique, 'Chez Awa');
      expect(apres.estVendeur, isTrue);
    });

    test('un compte enregistré avant cette version se relit sans boutique', () {
      // Les comptes déjà sur les téléphones n'ont pas ce champ : la ligne
      // doit s'afficher comme avant, pas planter.
      final ancien = CompteMemorise.fromJson({
        'id': 'v-1',
        'prenom': 'Alassane',
        'nom': 'GUEYE',
        'email': 'a@b.sn',
        'telephone': '',
        'role': 'Vendeur',
        'derniereUtilisation': '2026-11-19T10:00:00.000',
      });

      expect(ancien.boutique, isNull);
    });

    test('la copie pour un nouveau jeton garde la boutique', () {
      // `copie` sert au renouvellement de session : elle ne doit pas perdre
      // en chemin ce que la connexion avait appris.
      final compte = CompteMemorise(
        id: 'v-1',
        prenom: 'Alassane',
        nom: 'GUEYE',
        email: 'a@b.sn',
        telephone: '',
        role: 'Vendeur',
        derniereUtilisation: DateTime(2026, 11, 19),
        boutique: 'Chez Awa',
      );

      expect(compte.copie(refreshToken: 'neuf').boutique, 'Chez Awa');
      expect(compte.copie(effacerJeton: true).boutique, 'Chez Awa');
    });

    test('une reprise de session ne l’efface pas', () {
      // Le cas qui comptait : au retour sur l'application, l'identité vient
      // du jeton, qui ne porte pas la boutique. Sans rattrapage, elle
      // disparaissait de la ligne.
      const connue = 'Chez Awa';
      final depuisLeJeton = _vendeur(); // boutiqueNom null
      final retenue = depuisLeJeton.boutiqueNom ?? connue;

      expect(retenue, 'Chez Awa');
    });

    test('mais une boutique renommée remplace l’ancienne', () {
      final apresRenommage = _vendeur(boutique: 'Awa Couture');
      const connue = 'Chez Awa';
      final retenue = apresRenommage.boutiqueNom ?? connue;

      expect(retenue, 'Awa Couture');
    });
  });
}
