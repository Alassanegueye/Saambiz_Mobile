import 'package:flutter/material.dart';
import 'package:saambiz/features/auth/presentation/pages/login_page.dart';
import 'package:saambiz/features/home/presentation/pages/home.dart';
import 'package:saambiz/features/home/presentation/pages/acheteur/main_client_page.dart';
import 'package:saambiz/features/home/presentation/pages/vendeur/main_vendeur_page.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:saambiz/features/commande/presentation/pages/panier_page.dart';
import 'package:saambiz/features/commande/presentation/pages/checkout_page.dart';
import 'package:saambiz/features/commande/presentation/pages/mes_commandes_page.dart';
import 'package:saambiz/features/commande/presentation/pages/vendeur_commandes_page.dart';
import 'package:saambiz/features/commande/presentation/pages/commande_detail_page.dart';
import 'package:saambiz/features/compte/presentation/pages/forgot_password_page.dart';
import 'package:saambiz/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:saambiz/features/auth/presentation/signup/profile_choice_page.dart';
import 'package:saambiz/features/auth/presentation/signup/signup_form_page.dart';
import 'package:saambiz/features/auth/presentation/signup/email_verification_page.dart';
import 'package:saambiz/features/auth/presentation/signup/interets_page.dart';
import 'package:saambiz/features/auth/presentation/signup/localisation_page.dart';
import 'package:saambiz/features/auth/presentation/signup/creer_boutique_page.dart';
import 'package:saambiz/features/auth/presentation/signup/boutique_prete_page.dart';
import 'package:saambiz/features/auth/presentation/signup/vendeur_bienvenue_page.dart';

class AppRouter {
  static const String loginRoute = '/login';
  static const String onboardingRoute = '/onboarding';
  static const String homeRoute = '/home';
  static const String acheteurRoute = '/acheteur';
  static const String vendeurRoute = '/vendeur';
  static const String panierRoute = '/panier';
  static const String checkoutRoute = '/checkout';
  static const String mesCommandesRoute = '/mes-commandes';
  static const String vendeurCommandesRoute = '/vendeur-commandes';
  static const String commandeDetailRoute = '/commande-detail';
  static const String forgotPasswordRoute = '/forgot-password';

  // ─── Parcours d'inscription (onboarding → profil → email vérifié) ───
  static const String profileChoiceRoute = '/choix-profil';
  static const String clientSignupRoute = '/inscription-client';
  static const String vendeurSignupRoute = '/inscription-vendeur';
  static const String emailVerificationRoute = '/verification-email';
  static const String interetsRoute = '/centres-interet';
  static const String localisationRoute = '/localisation';
  static const String creerBoutiqueRoute = '/creer-boutique';
  static const String boutiquePreteRoute = '/boutique-prete';
  static const String vendeurBienvenueRoute = '/bienvenue-vendeur';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case acheteurRoute:
        // arguments : un User (connecté) OU {'isGuest': true} (mode invité)
        final args = settings.arguments;
        final isGuest = args is Map && args['isGuest'] == true;
        final user = args is User ? args : null;
        return MaterialPageRoute(
          builder: (_) => MainAcheteurPage(user: user, isGuest: isGuest),
        );

      case vendeurRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => MainVendeurPage(user: user),
        );

      case panierRoute:
        return MaterialPageRoute(builder: (_) => const PanierPage());

      case checkoutRoute:
        return MaterialPageRoute(builder: (_) => const CheckoutPage());

      case mesCommandesRoute:
        return MaterialPageRoute(builder: (_) => const MesCommandesPage());

      case vendeurCommandesRoute:
        return MaterialPageRoute(builder: (_) => const VendeurCommandesPage());

      case commandeDetailRoute:
        return MaterialPageRoute(
          builder: (_) => const CommandeDetailPage(),
          settings: settings,
        );

      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      case profileChoiceRoute:
        return MaterialPageRoute(builder: (_) => const ProfileChoicePage());

      case clientSignupRoute:
        return MaterialPageRoute(
          builder: (_) => const SignupFormPage(role: 'Acheteur'),
        );

      case vendeurSignupRoute:
        return MaterialPageRoute(
          builder: (_) => const SignupFormPage(role: 'Vendeur'),
        );

      case emailVerificationRoute:
        // arguments : le SignupDraft construit par le formulaire d'inscription
        final draft = settings.arguments as SignupDraft;
        return MaterialPageRoute(
          builder: (_) => EmailVerificationPage(draft: draft),
        );

      case interetsRoute: {
        // arguments : un User (nouveau compte) ou {'isGuest': true} (invité)
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => InteretsPage(
            user: args is User ? args : null,
            isGuest: args is Map && args['isGuest'] == true,
          ),
        );
      }

      case localisationRoute: {
        final args = (settings.arguments as Map?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => LocalisationPage(
            user: args['user'] as User?,
            isGuest: args['isGuest'] == true,
          ),
        );
      }

      case creerBoutiqueRoute:
        return MaterialPageRoute(
          builder: (_) => CreerBoutiquePage(user: settings.arguments as User?),
        );

      case boutiquePreteRoute: {
        final args = (settings.arguments as Map?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => BoutiquePretePage(
            user: args['user'] as User?,
            nomBoutique: (args['nomBoutique'] as String?) ?? 'Ma boutique',
          ),
        );
      }

      case vendeurBienvenueRoute: {
        final args = (settings.arguments as Map?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => VendeurBienvenuePage(
            user: args['user'] as User?,
            nomBoutique: (args['nomBoutique'] as String?) ?? 'Ma boutique',
          ),
        );
      }

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
    }
  }
}