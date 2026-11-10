import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/config/env.dart';

/// Configuration compilée.
///
/// `Env.verifier()` est la dernière barrière avant qu'une application de
/// production ne parte contre l'API de développement, ou en HTTP simple.
void main() {
  group('Env', () {
    test('fournit une adresse d\'API par défaut', () {
      expect(Env.apiBaseUrl, isNotEmpty);
    });

    test('le défaut vise l\'API de production', () {
      // Le build qui part en magasin par erreur, c'est celui lancé sans
      // --dart-define : il doit viser la production, pas un émulateur.
      // (Ce test attendait encore 10.0.2.2, resté de l'ancien défaut, et
      // échouait depuis que l'adresse a changé.)
      expect(Env.apiBaseUrl, 'https://api.saambiz.com/saambiz/v1');
    });

    test('hors release, le .env sert de repli', () {
      Env.resoudreApiBaseUrl('http://10.0.2.2:5000/saambiz/v1');
      expect(Env.apiBaseUrlEffective, contains('10.0.2.2'));

      // En RELEASE, ce repli est ignoré : le .env part dans l'IPA avec
      // l'adresse de l'émulateur, et une application publiée qui la prenait
      // n'appelait rien du tout, sans le moindre message. Pas vérifiable
      // ici — `flutter test` tourne toujours en débogage —, d'où ce rappel.
      Env.resoudreApiBaseUrl(null);
      expect(Env.apiBaseUrlEffective, Env.apiBaseUrl);
    });

    test('l\'environnement par défaut est le développement', () {
      expect(Env.estDeveloppement, isTrue);
      expect(Env.estProduction, isFalse);
    });

    test('l\'épinglage est inactif sans empreintes', () {
      expect(Env.epinglageActif, isFalse);
    });

    test('les rapports de plantage sont coupés hors production', () {
      // Sinon chaque rechargement à chaud pollue la console de plantages
      // qui n'existent pas chez les utilisateurs.
      expect(Env.crashlyticsActif, isFalse);
    });

    test('la vérification passe en développement', () {
      expect(Env.verifier, returnsNormally);
    });

    test('le résumé expose la configuration effective', () {
      expect(Env.resume.keys, containsAll(['environnement', 'apiBaseUrl']));
    });
  });
}
