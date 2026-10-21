import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/mise_en_page_auth.dart';

/// Connexion par e-mail ou téléphone : en-tête bleu marine, carte blanche
/// posée à cheval sur l'en-tête, lien vers l'inscription (parcours en
/// plusieurs étapes : choix du profil, formulaire, code reçu par e-mail…).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifiantController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final input = _identifiantController.text.trim();
    // E-mail ou téléphone : le serveur attend l'un ou l'autre.
    final isEmail = RegExp(r'\S+@\S+\.\S+').hasMatch(input);
    context.read<AuthBloc>().add(
          LoginRequested(
            email: isEmail ? input : null,
            telephone: isEmail ? null : input,
            mot_de_passe: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev != curr,
        listener: (context, state) {
          // AuthBloc est global : cette page ne réagit que lorsqu'elle est la
          // route visible.
          if (ModalRoute.of(context)?.isCurrent != true) return;

          if (state is AuthSuccess) {
            final role = state.user.role.toUpperCase();
            final String? route = switch (role) {
              'ACHETEUR' || 'CLIENT' => AppRouter.acheteurRoute,
              'VENDEUR' => AppRouter.vendeurRoute,
              _ => null,
            };
            if (route == null) {
              showToast(
                context,
                'Échec de la connexion',
                'Ce type de compte ne peut pas se connecter à l\'application.',
                ToastificationType.error,
              );
              return;
            }
            // Toast avant la navigation : la page de connexion est ensuite
            // retirée de la pile.
            showToast(
              context,
              'Connexion réussie',
              'Bienvenue sur SaamBiz !',
              ToastificationType.success,
            );
            Navigator.of(context).pushNamedAndRemoveUntil(
              route,
              (_) => false,
              arguments: state.user,
            );
          } else if (state is AuthFailure) {
            showToast(
              context,
              'Échec de la connexion',
              state.message.trim().isEmpty
                  ? 'Identifiant ou mot de passe incorrect.'
                  : state.message,
              ToastificationType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Form(
            key: _formKey,
            child: AutofillGroup(
              child: CorpsAuth(
                titre: 'Se connecter',
                sousTitre: 'Retrouvez vos boutiques, vos commandes et vos favoris.',
                enfants: [
                  CarteAuth(child: _formulaire(isLoading)),
                  LienAuth(
                    question: 'Pas encore de compte ? ',
                    action: 'Créer un compte',
                    onTap: () => Navigator.of(context).pushNamed(AppRouter.profileChoiceRoute),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formulaire(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChampFormulaire(
          libelle: 'E-mail ou téléphone',
          hint: 'Votre e-mail ou numéro',
          controller: _identifiantController,
          icone: Icons.person_outline_rounded,
          clavier: TextInputType.emailAddress,
          action: TextInputAction.next,
          autofill: const [AutofillHints.username, AutofillHints.email],
          validator: (v) => (v == null || v.trim().isEmpty) ? 'E-mail ou téléphone requis' : null,
        ),
        const SizedBox(height: 16),
        const LibelleChamp('Mot de passe'),
        ChampMotDePasse(
          controller: _passwordController,
          action: TextInputAction.done,
          onSubmitted: (_) => _onLoginPressed(),
          validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.forgotPasswordRoute),
            child: Text(
              'Mot de passe oublié ?',
              style: GoogleFonts.plusJakartaSans(
                color: AppColor.kPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        BoutonAuth(
          texte: 'Se connecter',
          onPressed: _onLoginPressed,
          chargement: isLoading,
        ),
      ],
    );
  }
}
