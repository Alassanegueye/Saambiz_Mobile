import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_color.dart';
import 'app_dimensions.dart';
import 'police.dart';

/// Thème de l'application.
///
/// Fond clair, en-têtes clairs, une seule police. Le marine porte la
/// structure, l'or n'apparaît que sur ce qui doit attirer l'œil. Les
/// composants Material (boutons, champs, puces, feuilles) reçoivent tous leur
/// réglage ici : une page qui n'impose rien hérite déjà de la charte.
class AppTheme {
  AppTheme._();

  static TextStyle _texte({
    double? taille,
    FontWeight? graisse,
    Color? couleur,
    double? hauteur,
    double? espacement,
  }) => TextStyle(
    fontFamily: kPolice,
    fontSize: taille,
    fontWeight: graisse,
    color: couleur,
    height: hauteur,
    letterSpacing: espacement,
  );

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColor.kPrimary,
      primary: AppColor.kPrimary,
      onPrimary: AppColor.kWhite,
      primaryContainer: AppColor.kPrimaryLight,
      onPrimaryContainer: AppColor.kPrimaryDark,
      secondary: AppColor.kSecondary,
      onSecondary: AppColor.kPrimary,
      secondaryContainer: AppColor.kSecondaryLight,
      onSecondaryContainer: AppColor.kPrimaryDark,
      error: AppColor.kErreur,
      surface: AppColor.kWhite,
      onSurface: AppColor.kGrayscaleDark100,
      onSurfaceVariant: AppColor.kGrayscale40,
      outline: AppColor.kGrayscale20,
      outlineVariant: AppColor.kLine,
      surfaceContainerLowest: AppColor.kWhite,
      surfaceContainerLow: AppColor.kBackground,
      surfaceContainer: AppColor.kBackground,
      surfaceContainerHigh: AppColor.kBackground2,
      brightness: Brightness.light,
    );

    final rayonControle = BorderRadius.circular(AppDim.rayonMoyen);

    OutlineInputBorder bordure(Color couleur, [double epaisseur = 1]) =>
        OutlineInputBorder(
          borderRadius: rayonControle,
          borderSide: BorderSide(color: couleur, width: epaisseur),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: kPolice,
      colorScheme: colorScheme,
      primaryColor: AppColor.kPrimary,
      scaffoldBackgroundColor: AppColor.kBackground,
      canvasColor: AppColor.kBackground,

      // Transitions : glissé natif sur iOS (retour par balayage du bord),
      // fondu enchaîné sur Android plutôt que le zoom par défaut.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColor.kPrimary.withValues(alpha: 0.06),
      highlightColor: Colors.transparent,
      visualDensity: VisualDensity.standard,

      // En-tête clair, du ton de l'écran : titre et icônes au marine, filet
      // discret seulement quand le contenu défile dessous.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.kBackground,
        foregroundColor: AppColor.kPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.6,
        shadowColor: AppColor.kPrimary.withValues(alpha: 0.18),
        centerTitle: false,
        // Fond clair : icônes de la barre d'état en sombre.
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColor.kWhite,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: AppColor.kPrimary, size: 24),
        actionsIconTheme: const IconThemeData(
          color: AppColor.kPrimary,
          size: 24,
        ),
        titleTextStyle: _texte(
          couleur: AppColor.kGrayscaleDark100,
          graisse: FontWeight.w700,
          taille: 18,
          espacement: -0.2,
        ),
      ),

      // Onglets : texte marine, trait or arrondi sous l'onglet actif.
      tabBarTheme: TabBarThemeData(
        labelColor: AppColor.kPrimary,
        unselectedLabelColor: AppColor.kGrayscale40,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColor.kSecondary, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColor.kLine,
        labelStyle: _texte(graisse: FontWeight.w700, taille: 14),
        unselectedLabelStyle: _texte(graisse: FontWeight.w500, taille: 14),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // Bouton flottant or, icône marine (comme le carré or du pictogramme).
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColor.kSecondary,
        foregroundColor: AppColor.kPrimary,
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle: _texte(graisse: FontWeight.w700, taille: 14.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Puces de choix : pilule blanche ; sélection marine, texte blanc.
      chipTheme: ChipThemeData(
        selectedColor: AppColor.kPrimary,
        backgroundColor: AppColor.kWhite,
        disabledColor: AppColor.kSurface,
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.selected)
                ? AppColor.kPrimary
                : AppColor.kGrayscale20,
          ),
        ),
        checkmarkColor: AppColor.kWhite,
        showCheckmark: false,
        // Couleur dépendant de l'état dans un style ordinaire : la puce la
        // résout elle-même (un WidgetStateTextStyle est perdu lors de la
        // fusion avec les styles par défaut, et le libellé devenait
        // invisible).
        labelStyle: TextStyle(
          fontFamily: kPolice,
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColor.kWhite
                : AppColor.kGrayscaleDark100,
          ),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
      ),

      // Boutons segmentés : segment choisi en marine.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColor.kPrimary
                : AppColor.kWhite,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColor.kWhite
                : AppColor.kPrimary,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColor.kSecondary
                : AppColor.kPrimary,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColor.kGrayscale20),
          ),
          textStyle: WidgetStatePropertyAll(
            _texte(graisse: FontWeight.w700, taille: 13),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: rayonControle),
          ),
        ),
      ),

      // Interrupteurs : piste marine, pastille or.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColor.kSecondary
              : AppColor.kWhite,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColor.kPrimary
              : AppColor.kGrayscale20,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColor.kPrimary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColor.kWhite),
        side: const BorderSide(color: AppColor.kGrayscale30, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColor.kPrimary
              : AppColor.kGrayscale30,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColor.kPrimary,
        linearTrackColor: AppColor.kPrimaryLight,
        circularTrackColor: Colors.transparent,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColor.kLine,
        space: 1,
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AppColor.kPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: _texte(
          taille: 14.5,
          graisse: FontWeight.w600,
          couleur: AppColor.kGrayscaleDark100,
        ),
        subtitleTextStyle: _texte(taille: 12.5, couleur: AppColor.kGrayscale40),
        shape: RoundedRectangleBorder(borderRadius: rayonControle),
      ),

      // Carte blanche sans contour : elle se détache du fond bleuté.
      cardTheme: CardThemeData(
        color: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDim.rayonGrand),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDim.rayonFeuille),
        ),
        titleTextStyle: _texte(
          taille: 18,
          graisse: FontWeight.w700,
          couleur: AppColor.kGrayscaleDark100,
        ),
        contentTextStyle: _texte(
          taille: 14.5,
          hauteur: 1.5,
          couleur: AppColor.kGrayscale60,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColor.kWhite,
        showDragHandle: true,
        dragHandleColor: AppColor.kGrayscale20,
        dragHandleSize: Size(36, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDim.rayonFeuille),
          ),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: AppColor.kPrimary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: rayonControle),
        textStyle: _texte(taille: 14, couleur: AppColor.kGrayscaleDark100),
      ),

      drawerTheme: const DrawerThemeData(backgroundColor: AppColor.kWhite),

      // Boutons : un seul gabarit (52 de haut, coins de 12) décliné en
      // plein marine, plein or (FilledButton), contour et texte.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kPrimary,
          foregroundColor: AppColor.kWhite,
          disabledBackgroundColor: AppColor.kGrayscale20,
          disabledForegroundColor: AppColor.kGrayscale40,
          textStyle: _texte(graisse: FontWeight.w700, taille: 15),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, AppDim.hauteurBouton),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: rayonControle),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.kPrimary,
          foregroundColor: AppColor.kWhite,
          disabledBackgroundColor: AppColor.kGrayscale20,
          disabledForegroundColor: AppColor.kGrayscale40,
          textStyle: _texte(graisse: FontWeight.w700, taille: 15),
          minimumSize: const Size(0, AppDim.hauteurBouton),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: rayonControle),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.kPrimary,
          backgroundColor: AppColor.kWhite,
          textStyle: _texte(graisse: FontWeight.w700, taille: 14.5),
          side: const BorderSide(color: AppColor.kGrayscale20, width: 1.2),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: rayonControle),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.kPrimary,
          textStyle: _texte(graisse: FontWeight.w700, taille: 14),
          shape: RoundedRectangleBorder(borderRadius: rayonControle),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColor.kPrimary),
      ),

      // Champs de saisie : fond blanc, filet clair, marine au focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.kWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: _texte(
          couleur: AppColor.kGrayscale30,
          taille: 14.5,
          graisse: FontWeight.w400,
        ),
        labelStyle: _texte(
          couleur: AppColor.kGrayscale40,
          graisse: FontWeight.w500,
          taille: 14.5,
        ),
        prefixIconColor: AppColor.kGrayscale40,
        suffixIconColor: AppColor.kGrayscale40,
        floatingLabelStyle: _texte(
          couleur: AppColor.kPrimary,
          graisse: FontWeight.w600,
        ),
        helperStyle: _texte(taille: 12, couleur: AppColor.kGrayscale40),
        errorStyle: _texte(taille: 12, couleur: AppColor.kErreur),
        errorMaxLines: 2,
        border: bordure(AppColor.kGrayscale20),
        enabledBorder: bordure(AppColor.kGrayscale20),
        focusedBorder: bordure(AppColor.kPrimary, 1.6),
        errorBorder: bordure(AppColor.kErreur),
        focusedErrorBorder: bordure(AppColor.kErreur, 1.6),
        disabledBorder: bordure(AppColor.kLine),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColor.kPrimary,
        selectionColor: AppColor.kSecondary.withValues(alpha: 0.35),
        selectionHandleColor: AppColor.kPrimary,
      ),

      // Bandeau d'information : marine, coins arrondis, au-dessus du bas.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.kPrimary,
        contentTextStyle: _texte(
          couleur: Colors.white,
          taille: 14,
          graisse: FontWeight.w500,
        ),
        actionTextColor: AppColor.kSecondary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: rayonControle),
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: AppColor.kErreur,
        textColor: AppColor.kWhite,
        textStyle: _texte(taille: 10, graisse: FontWeight.w700),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColor.kPrimary,
          borderRadius: BorderRadius.circular(AppDim.rayonPetit),
        ),
        textStyle: _texte(taille: 12, couleur: AppColor.kWhite),
      ),

      // Barre de navigation : voir BarreNavigationVerre, qui l'habille.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColor.kPrimaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => _texte(
            taille: 11,
            graisse: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            couleur: states.contains(WidgetState.selected)
                ? AppColor.kPrimary
                : AppColor.kGrayscale40,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColor.kPrimary
                : AppColor.kGrayscale30,
          ),
        ),
      ),
    );
  }
}
