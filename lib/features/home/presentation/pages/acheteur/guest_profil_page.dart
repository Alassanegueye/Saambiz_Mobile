import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/routes/app_router.dart';

// ─── Palette SaamBiz ───────────────────────────────────────────────────────────
class _C {
  static const navy    = Color(0xFF1B3A6B);
  static const navyDk  = Color(0xFF0F2547);
  static const gold    = Color(0xFFD4A72C);
  static const white   = Color(0xFFFFFFFF);
  static const bg      = Color(0xFFF5F7F2);
  static const black   = Color(0xFF1A1A1A);
  static const sub     = Color(0xFF7A8473);
  static const border  = Color(0xFFE6EAF0);
}

/// Page profil affichée pour un visiteur NON connecté (mode invité).
/// Elle diffère volontairement du profil d'un client connecté : au lieu des
/// informations personnelles, elle invite à se connecter ou à créer un compte.
class GuestProfilPage extends StatelessWidget {
  const GuestProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // En-tête navy avec bouton retour
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.navy, _C.navyDk],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 18, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (canPop)
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: _C.white, size: 18),
                          )
                        else
                          const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Profil',
                            style: GoogleFonts.sora(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _C.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Avatar invité
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _C.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.gold.withOpacity(0.6), width: 2),
                      ),
                      child: const Icon(Icons.person_outline_rounded,
                          color: _C.white, size: 44),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Vous naviguez en invité',
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _C.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connectez-vous pour commander,\nsuivre vos achats et gérer votre compte.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        height: 1.5,
                        color: _C.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRouter.loginRoute),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text('Se connecter',
                        style: GoogleFonts.sora(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.gold,
                      foregroundColor: _C.navy,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRouter.profileChoiceRoute),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text('Créer un compte',
                        style: GoogleFonts.sora(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.navy,
                      side: const BorderSide(color: _C.navy, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Aperçu des fonctionnalités réservées aux membres
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              children: [
                _lockedTile(context, Icons.receipt_long_outlined, 'Mes commandes',
                    'Suivez vos achats en temps réel'),
                _lockedTile(context, Icons.favorite_border_rounded, 'Mes favoris',
                    'Retrouvez vos boutiques préférées'),
                _lockedTile(context, Icons.notifications_none_rounded, 'Notifications',
                    'Restez informé des nouveautés'),
                _lockedTile(context, Icons.settings_outlined, 'Paramètres du compte',
                    'Gérez vos informations personnelles'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedTile(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _C.navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _C.navy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _C.black)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.dmSans(fontSize: 12, color: _C.sub)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 16, color: _C.sub),
        ],
      ),
    );
  }
}
