import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color.dart';
import '../theme/police.dart';

/// Espace à laisser en bas d'un onglet vendeur pour que rien ne passe sous
/// la barre d'onglets flottante.
///
/// Le Scaffold principal (`extendBody`) range la hauteur de cette barre,
/// zone basse de l'iPhone comprise, dans le `padding` du bas ; on y ajoute
/// un peu d'air. Le repli (barre 68 + 16 de marge) sert si ce padding
/// n'est pas transmis.
double espaceBasVendeur(BuildContext context) {
  // `paddingOf` et `viewPaddingOf` ne réabonnent le widget qu'aux marges
  // système ; `MediaQuery.of` le reconstruisait aussi à chaque ouverture du
  // clavier et à chaque changement de densité de texte, alors que cette
  // fonction n'en dépend pas.
  final marges = MediaQuery.paddingOf(context);
  final margesVue = MediaQuery.viewPaddingOf(context);
  return math.max(marges.bottom, 84 + margesVue.bottom) + 16;
}

/// Gabarit commun des onglets vendeur, dans l'esprit de la page de
/// connexion : en-tête marine (titre blanc, sous-titre, actions rondes),
/// puis une feuille claire aux coins arrondis qui porte le contenu.
///
/// [boutonFlottant] est relevé au-dessus de la barre d'onglets flottante,
/// pour ne jamais passer dessous.
class PageVendeur extends StatelessWidget {
  final String titre;
  final String? sousTitre;

  /// Remplace le titre (par exemple un champ de recherche ouvert).
  final Widget? titreWidget;
  final List<Widget> actions;
  final Widget corps;
  final Widget? boutonFlottant;

  const PageVendeur({
    super.key,
    required this.titre,
    required this.corps,
    this.sousTitre,
    this.titreWidget,
    this.actions = const [],
    this.boutonFlottant,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColor.kPrimary,
        floatingActionButton: boutonFlottant == null
            ? null
            : Padding(
                // Le bouton a deja 16 de marge propre sous lui.
                padding: EdgeInsets.only(
                  bottom: espaceBasVendeur(context) - 16,
                ),
                child: boutonFlottant,
              ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 14, 20),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop()) ...[
                      BoutonEnteteVendeur(
                        icone: Icons.arrow_back_rounded,
                        infobulle: 'Retour',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: titreWidget ?? _Titre(titre, sousTitre)),
                    for (final a in actions) ...[const SizedBox(width: 8), a],
                  ],
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Material(color: AppColor.kBackground, child: corps),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  const _Titre(this.titre, this.sousTitre);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColor.kWhite,
          ),
        ),
        if (sousTitre != null) ...[
          const SizedBox(height: 2),
          Text(
            sousTitre!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 13.5,
              color: AppColor.kWhite.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bouton rond translucide de l'en-tête marine.
class BoutonEnteteVendeur extends StatelessWidget {
  final IconData icone;
  final String infobulle;
  final VoidCallback? onTap;

  /// Jaune de la marque : l'action principale de l'écran.
  final bool principal;

  const BoutonEnteteVendeur({
    super.key,
    required this.icone,
    required this.infobulle,
    this.onTap,
    this.principal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: infobulle,
      child: Material(
        color: principal
            ? AppColor.kSecondary
            : AppColor.kWhite.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icone,
              size: 21,
              color: principal ? AppColor.kPrimary : AppColor.kWhite,
            ),
          ),
        ),
      ),
    );
  }
}

/// Scaffold des sous-pages, au même style que les onglets : en-tête marine
/// (titre et icônes en blanc), puis une feuille claire aux coins arrondis.
///
/// S'utilise comme un [Scaffold] : l'[AppBar] passée est habillée en marine
/// par le thème, sans rien changer à son contenu.
class ScaffoldMarine extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;

  /// Couleur de la feuille qui porte le contenu.
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  const ScaffoldMarine({
    super.key,
    this.appBar,
    this.body,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const style = TextStyle(
      fontFamily: kPolice,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      color: AppColor.kWhite,
    );
    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: AppColor.kPrimary,
          foregroundColor: AppColor.kWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: style,
          toolbarHeight: 64,
          iconTheme: const IconThemeData(color: AppColor.kWhite, size: 24),
          actionsIconTheme: const IconThemeData(
            color: AppColor.kWhite,
            size: 24,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColor.kPrimary,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Material(
              color: backgroundColor ?? AppColor.kBackground,
              child: body ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
