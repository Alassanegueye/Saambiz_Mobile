import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/utils/journal_sensible.dart';

/// Les corps de requêtes et de réponses passent par le journal de débogage.
/// Ces tests figent ce qui ne doit JAMAIS s'y retrouver en clair, et ce qui
/// doit au contraire y rester lisible — un journal entièrement masqué ne sert
/// plus à déboguer.
void main() {
  group('Ce qui doit être masqué', () {
    test('le mot de passe de connexion', () {
      final masque =
          masquerDonneesSensibles({
                'identifiant': 'awa@diop.sn',
                'mot_de_passe': 'Secret123!',
              })
              as Map;

      expect(masque['mot_de_passe'], isNot(contains('Secret')));
      // L'identifiant reste lisible : c'est lui qui sert à retrouver la trace.
      expect(masque['identifiant'], 'awa@diop.sn');
    });

    test('les deux mots de passe du changement', () {
      final masque =
          masquerDonneesSensibles({
                'ancienMotDePasse': 'avant',
                'nouveauMotDePasse': 'apres',
              })
              as Map;

      expect(masque['ancienMotDePasse'], isNot(contains('avant')));
      expect(masque['nouveauMotDePasse'], isNot(contains('apres')));
    });

    test('le jeton d’identité Google ou Apple', () {
      final masque =
          masquerDonneesSensibles({
                'fournisseur': 'google',
                'idToken': 'eyJhbGciOiJSUzI1NiJ9.charge.signature',
                'nonce': 'graine-aleatoire',
              })
              as Map;

      expect(masque['idToken'], isNot(contains('eyJ')));
      expect(masque['nonce'], isNot(contains('graine')));
      // Le fournisseur reste lisible : il n'a rien de secret et il explique
      // la requête.
      expect(masque['fournisseur'], 'google');
    });

    test('le jeton de session et son jeton de renouvellement', () {
      final masque =
          masquerDonneesSensibles({
                'token': 'eyJ.jeton.session',
                'refreshToken': 'r-123456',
                'utilisateur': {'id': 'u1', 'nom': 'Diop'},
              })
              as Map;

      expect(masque['token'], isNot(contains('jeton')));
      expect(masque['refreshToken'], isNot(contains('123456')));
    });

    test('un jeton niché au fond de la réponse', () {
      // Le masquage doit descendre dans les structures imbriquées, pas
      // s'arrêter au premier niveau.
      final masque =
          masquerDonneesSensibles({
                'data': {
                  'session': [
                    {'accessToken': 'abcdef', 'expire': 3600},
                  ],
                },
              })
              as Map;

      final session = ((masque['data'] as Map)['session'] as List).first as Map;
      expect(session['accessToken'], isNot(contains('abcdef')));
      expect(session['expire'], 3600);
    });

    test('un champ multipart sensible', () {
      expect(
        masquerChampMultipart('motDePasse', 'Secret123!'),
        isNot(contains('Secret')),
      );
    });

    test('l’en-tête Authorization', () {
      expect(
        masquerEntete('Authorization', 'Bearer eyJ...'),
        isNot(contains('eyJ')),
      );
    });
  });

  group('Ce qui doit rester lisible', () {
    test('les champs ordinaires d’une commande', () {
      final masque =
          masquerDonneesSensibles({
                'modeLivraison': 'livraison',
                'adresseLivraison': 'Sacré-Cœur 3',
                'items': [
                  {'produitId': 'p1', 'quantite': 2},
                ],
              })
              as Map;

      expect(masque['modeLivraison'], 'livraison');
      expect(masque['adresseLivraison'], 'Sacré-Cœur 3');
      expect(((masque['items'] as List).first as Map)['quantite'], 2);
    });

    test('une valeur nulle ou une chaîne simple traverse sans dommage', () {
      expect(masquerDonneesSensibles(null), isNull);
      expect(masquerDonneesSensibles('bonjour'), 'bonjour');
      expect(masquerDonneesSensibles(42), 42);
    });
  });
}
