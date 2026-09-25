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

    test('le défaut vise l\'émulateur Android', () {
      // 10.0.2.2 est l'alias de la machine hôte vu depuis l'émulateur.
      expect(Env.apiBaseUrl, contains('10.0.2.2'));
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
