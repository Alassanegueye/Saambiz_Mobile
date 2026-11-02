import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    // Charte SaamBiz : bleu marine et or, police Inter, formes sobres
    // (rayons de 8 à 12), aucun ornement.
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
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: AppColor.kPrimary,
      scaffoldBackgroundColor: AppColor.kBackground,

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

      // AppBar blanche, titre et icônes au bleu de la marque
      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.kWhite,
        foregroundColor: AppColor.kPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColor.kPrimary.withValues(alpha: 0.15),
        centerTitle: false,
        // Fond clair : icônes de la barre d'état en sombre.
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: AppColor.kPrimary, size: 22),
        actionsIconTheme: const IconThemeData(
          color: AppColor.kPrimary,
          size: 22,
        ),
        titleTextStyle: GoogleFonts.inter(
          color: AppColor.kPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),

      // Onglets : trait marine sous l'onglet actif
      tabBarTheme: TabBarThemeData(
        labelColor: AppColor.kPrimary,
        unselectedLabelColor: AppColor.kGrayscale40,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColor.kPrimary, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColor.kLine,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      // Bouton flottant jaune, icône bleue (comme le carré jaune du pictogramme)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColor.kSecondary,
        foregroundColor: AppColor.kPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Puces de choix : sélection marine, texte blanc
      chipTheme: ChipThemeData(
        selectedColor: AppColor.kPrimary,
        backgroundColor: AppColor.kWhite,
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.selected)
                ? AppColor.kPrimary
                : AppColor.kGrayscale20,
          ),
        ),
        checkmarkColor: AppColor.kWhite,
        showCheckmark: false,
        // Couleur dépendant de l'état dans un style ordinaire : la puce la résout
        // elle-même (un WidgetStateTextStyle est perdu lors de la fusion avec les
        // styles par défaut, et le libellé devenait invisible).
        labelStyle: GoogleFonts.inter(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColor.kWhite
                : AppColor.kPrimary,
          ),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Boutons segmentés : segment choisi en jaune
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
          side: const WidgetStatePropertyAll(BorderSide(color: AppColor.kLine)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ),

      // Interrupteurs : piste bleue, pastille jaune
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColor.kSecondary
              : AppColor.kWhite,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColor.kPrimary
              : AppColor.kLine,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColor.kPrimary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColor.kSecondary),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColor.kPrimary,
        linearTrackColor: AppColor.kSecondaryLight,
      ),

      dividerTheme: const DividerThemeData(color: AppColor.kLine, space: 1),

      listTileTheme: ListTileThemeData(
        iconColor: AppColor.kPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColor.kGrayscaleDark100,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AppColor.kGrayscale40,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      cardTheme: CardThemeData(
        color: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColor.kLine),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColor.kGrayscaleDark100,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
          color: AppColor.kGrayscaleDark100,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColor.kLine,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColor.kGrayscaleDark100,
        ),
      ),

      drawerTheme: const DrawerThemeData(backgroundColor: AppColor.kWhite),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kPrimary,
          foregroundColor: AppColor.kWhite,
          disabledBackgroundColor: AppColor.kPrimary.withValues(alpha: 0.4),
          disabledForegroundColor: AppColor.kWhite,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.kPrimary,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          side: const BorderSide(color: AppColor.kPrimary, width: 1.5),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.kPrimary,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // Champs de saisie
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.kWhite,
        hintStyle: GoogleFonts.inter(
          color: AppColor.kGrayscale40,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColor.kGrayscaleDark100,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: AppColor.kPrimary,
        suffixIconColor: AppColor.kGrayscale40,
        floatingLabelStyle: GoogleFonts.inter(
          color: AppColor.kPrimary,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColor.kErreur),
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.kLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.kPrimary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.kLine),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.kErreur),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.kErreur, width: 1.5),
        ),
      ),

      // SnackBar stylé
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.kPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Typographie générale
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColor.kGrayscaleDark100,
        displayColor: AppColor.kGrayscaleDark100,
      ),

      // Barre de navigation : fond blanc, onglet actif en marine
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColor.kSecondaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColor.kPrimary
                : AppColor.kGrayscale40,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColor.kPrimary
                : AppColor.kGrayscale30,
          ),
        ),
      ),
    );
  }
}
