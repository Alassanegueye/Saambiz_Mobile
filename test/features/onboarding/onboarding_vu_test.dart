import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:saambiz/core/routes/app_router.dart';
import 'package:saambiz/features/auth/presentation/pages/app_bootstrap.dart';
import 'package:saambiz/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'onboarding ne se montre qu'une fois.
///
/// Il s'affichait à CHAQUE démarrage sans session. `dejaVu()` existait,
/// posait bien son drapeau au premier affichage, et sa documentation disait
/// « ne se montre qu'à la première ouverture » — mais personne ne l'appelait.
/// Une seule occurrence dans tout le code : sa propre définition.
///
/// Le défaut passait inaperçu tant que la session durait dix ans : on
/// revenait toujours avec un jeton valide, donc jamais par ce chemin. Depuis
/// que trois heures de silence ferment la session, revenir le matin
/// signifiait rebalayer trois écrans avant d'atteindre son compte.
///
/// Ce fichier fige la lecture du drapeau. L'aiguillage qui s'en sert vit
/// dans `app_bootstrap.dart`, et son comportement est décrit là-bas.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    SharedPreferences.setMockInitialValues({});
    GetIt.I.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
  });

  tearDown(() => GetIt.I.reset());

  test('à la toute première ouverture, il n’a pas été vu', () {
    expect(OnboardingPage.dejaVu(), isFalse);
  });

  test('une fois le drapeau posé, il ne se remontre pas', () async {
    // Le drapeau est écrit par l'écran lui-même, dès son affichage.
    await GetIt.I<SharedPreferences>().setBool('onboarding_vu', true);

    expect(OnboardingPage.dejaVu(), isTrue);
  });

  test('un drapeau à faux vaut « jamais vu »', () async {
    await GetIt.I<SharedPreferences>().setBool('onboarding_vu', false);

    expect(OnboardingPage.dejaVu(), isFalse);
  });

  test('sans préférences disponibles, on le remontre', () async {
    // Prudence : mieux vaut un onboarding de trop qu'un démarrage qui
    // échoue. `dejaVu()` ne doit jamais lever.
    await GetIt.I.reset();

    expect(OnboardingPage.dejaVu(), isFalse);
  });

  group('Où va-t-on, sans session ouverte', () {
    test('jamais vu : les trois écrans de présentation', () {
      expect(
        destinationSansSession(vu: false, comptes: false),
        AppRouter.onboardingRoute,
      );
    });

    test('jamais vu, même avec des comptes : l’onboarding d’abord', () {
      // Une réinstallation laisse parfois des comptes derrière elle ; la
      // présentation reste due à qui ne l'a jamais vue.
      expect(
        destinationSansSession(vu: true, comptes: true),
        isNot(AppRouter.onboardingRoute),
      );
      expect(
        destinationSansSession(vu: false, comptes: true),
        AppRouter.onboardingRoute,
      );
    });

    test('déjà vu, des comptes : directement la liste des comptes', () {
      // LE CAS SIGNALÉ : on quitte, on revient, on retombait sur
      // l'onboarding au lieu de ses comptes.
      expect(
        destinationSansSession(vu: true, comptes: true),
        AppRouter.loginRoute,
      );
    });

    test('déjà vu, aucun compte : l’inscription', () {
      // Exactement ce que donne la fin de l'onboarding : on n'a rien à
      // proposer à quelqu'un qui n'a jamais eu de compte ici.
      expect(
        destinationSansSession(vu: true, comptes: false),
        AppRouter.profileChoiceRoute,
      );
    });

    test('l’onboarding n’est jamais le chemin de quelqu’un qui l’a vu', () {
      for (final comptes in [true, false]) {
        expect(
          destinationSansSession(vu: true, comptes: comptes),
          isNot(AppRouter.onboardingRoute),
        );
      }
    });
  });
}
