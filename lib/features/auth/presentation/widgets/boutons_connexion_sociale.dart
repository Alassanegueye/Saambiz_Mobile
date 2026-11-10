import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/connexion_sociale_source.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'Divider_row.dart';

/// « ou » puis « Continuer avec Apple » / « Continuer avec Google ».
///
/// Chaque bouton n'apparaît que si sa connexion est possible sur cet appareil
/// (Apple : iPhone ; Google : tout téléphone — sans identifiant client, un
/// toucher affiche un message au lieu d'ouvrir Google).
/// Sans aucun des deux, rien ne s'affiche.
class BoutonsConnexionSociale extends StatelessWidget {
  const BoutonsConnexionSociale({
    super.key,
    this.separateur = 'ou',
    this.separateurApres = false,
  });

  /// Texte du séparateur entre ces boutons et le reste du formulaire.
  final String separateur;

  /// `true` : boutons en tête, séparateur en dessous (avant le formulaire).
  final bool separateurApres;

  @override
  Widget build(BuildContext context) {
    final source = sl<ConnexionSocialeSource>();
    final fournisseurs = [
      if (source.appleDisponible) FournisseurSocial.apple,
      // `googleDisponible`, et non `googleAffiche` : tant que l'identifiant
      // client n'est pas fourni à la compilation, le bouton répondait « la
      // connexion avec Google arrive bientôt ». Un bouton qui annonce une
      // fonctionnalité absente est précisément ce que le relecteur de l'App
      // Store refuse (directive 2.1, fonctionnalité non opérationnelle) —
      // et il touche chaque bouton de l'écran de connexion.
      if (source.googleDisponible) FournisseurSocial.google,
    ];
    if (fournisseurs.isEmpty) return const SizedBox.shrink();

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final occupe = state is AuthLoading;
        final enCours = state is AuthSocialEnCours ? state.fournisseur : null;
        return Column(
          children: [
            if (!separateurApres) ...[
              const SizedBox(height: 14),
              DividerRow(title: separateur),
              const SizedBox(height: 12),
            ],
            for (final f in fournisseurs) ...[
              _BoutonFournisseur(
                fournisseur: f,
                chargement: enCours == f,
                onPressed: occupe
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        context.read<AuthBloc>().add(
                          ConnexionSocialeDemandee(f),
                        );
                      },
              ),
              if (f != fournisseurs.last) const SizedBox(height: 10),
            ],
            if (separateurApres) ...[
              const SizedBox(height: 22),
              DividerRow(title: separateur),
              const SizedBox(height: 22),
            ],
          ],
        );
      },
    );
  }
}

class _BoutonFournisseur extends StatelessWidget {
  const _BoutonFournisseur({
    required this.fournisseur,
    required this.chargement,
    required this.onPressed,
  });

  final FournisseurSocial fournisseur;
  final bool chargement;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Les deux boutons blancs bordés : variante « blanc avec contour »
    // admise par Apple, et style standard de Google. Logo Apple noir, « G »
    // en couleurs.
    final apple = fournisseur == FournisseurSocial.apple;
    const fond = AppColor.kWhite;
    const texte = AppColor.kNoir;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: fond,
          foregroundColor: texte,
          disabledBackgroundColor: fond.withValues(alpha: 0.6),
          disabledForegroundColor: texte.withValues(alpha: 0.6),
          side: const BorderSide(color: AppColor.kGrayscale20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: chargement
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(texte),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  apple
                      ? const Icon(Icons.apple, size: 24)
                      : SvgPicture.string(_logoGoogle, width: 20, height: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      apple ? 'Continuer avec Apple' : 'Continuer avec Google',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kPolice,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: texte,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// « G » de Google, quatre couleurs.
const String _logoGoogle = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';
