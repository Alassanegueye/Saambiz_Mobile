import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/services/localisation_service.dart';
import '../../../../injection_container.dart';
import '../../../home/data/datasources/accueil_remote_datasource.dart';
import '../../domain/entities/user.dart';
import 'signup_kit.dart';

/// Dernière étape avant l'accueil : proposer la géolocalisation.
///
/// Écran dédié plutôt qu'une fenêtre système surgie de nulle part : le client
/// doit d'abord comprendre ce qu'il y gagne — voir les boutiques de son
/// quartier — avant qu'on lui demande quoi que ce soit. Le refus est un
/// chemin normal, pas une impasse.
class LocalisationPage extends StatefulWidget {
  final User? user;
  final bool isGuest;

  const LocalisationPage({super.key, this.user, this.isGuest = false});

  @override
  State<LocalisationPage> createState() => _LocalisationPageState();
}

class _LocalisationPageState extends State<LocalisationPage> {
  bool _enCours = false;

  Future<void> _entrer() async {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.acheteurRoute,
      (_) => false,
      arguments: widget.isGuest
          ? const {'isGuest': true}
          : (widget.user ?? const {'isGuest': false}),
    );
  }

  Future<void> _autoriser() async {
    setState(() => _enCours = true);
    const service = LocalisationService();
    final position = await service.demanderPosition();
    await service.marquerDemandee();

    // Un client connecté garde sa position côté serveur : elle personnalise
    // aussi son accueil depuis un autre appareil.
    if (position != null && !widget.isGuest) {
      await AccueilRemoteDataSource(sl<Dio>()).majPreferences(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }

    if (!mounted) return;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Position non disponible. Vous verrez quand même les boutiques qui vous correspondent.',
          ),
        ),
      );
    }
    await _entrer();
  }

  Future<void> _plusTard() async {
    await const LocalisationService().marquerDemandee();
    await _entrer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Sb.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Sb.goldSoft,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.place_outlined, size: 44, color: Sb.navy),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Les boutiques près de vous',
                textAlign: TextAlign.center,
                style: Sb.title(23),
              ),
              const SizedBox(height: 14),
              Text(
                'Autorisez la localisation et nous vous montrerons d’abord les '
                'boutiques de votre quartier, avec la distance depuis chez vous.',
                textAlign: TextAlign.center,
                style: Sb.body(14.5),
              ),
              const SizedBox(height: 24),

              const _Argument(
                icon: Icons.storefront_outlined,
                texte: 'Les commerces de votre ville en premier',
              ),
              const _Argument(
                icon: Icons.local_shipping_outlined,
                texte: 'Des retraits et livraisons plus rapides',
              ),
              const _Argument(
                icon: Icons.lock_outline_rounded,
                texte: 'Votre position n’est jamais partagée avec les vendeurs',
              ),

              const Spacer(),

              SbPrimaryButton(
                label: 'Autoriser la localisation',
                loading: _enCours,
                onPressed: _autoriser,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _enCours ? null : _plusTard,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Sb.navy,
                    side: const BorderSide(color: Sb.border, width: 1.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Plus tard',
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vous pourrez l’activer à tout moment depuis votre profil.',
                textAlign: TextAlign.center,
                style: Sb.body(12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Argument extends StatelessWidget {
  final IconData icon;
  final String texte;
  const _Argument({required this.icon, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Sb.navySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: Sb.navy),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texte, style: Sb.body(13.5))),
        ],
      ),
    );
  }
}
