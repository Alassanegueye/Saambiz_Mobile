import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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
    return SbPageAuth(
      icone: Icons.place_outlined,
      titre: 'Près de chez vous',
      sousTitre: 'Voir d’abord les boutiques de votre quartier.',
      carte: const [
        _Argument(icon: Icons.storefront_outlined, texte: 'Commerces proches en premier'),
        _Argument(icon: Icons.local_shipping_outlined, texte: 'Livraisons plus rapides'),
        _Argument(icon: Icons.lock_outline_rounded, texte: 'Jamais partagée aux vendeurs'),
      ],
      apres: [
        SbPrimaryButton(
          label: 'Autoriser la localisation',
          loading: _enCours,
          onPressed: _autoriser,
        ),
        const SizedBox(height: 10),
        SbSecondaryButton(label: 'Plus tard', onPressed: _enCours ? null : _plusTard),
      ],
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
