import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_color.dart';
import '../../core/theme/police.dart';
import '../../core/widgets/app_app_bar.dart';
import '../../injection_container.dart';
import 'certification_service.dart';

/// Certification du vendeur : il envoie le recto et le verso de sa pièce
/// d'identité, l'équipe SaamBiz examine la demande, et sa boutique reçoit le
/// badge « Boutique certifiée ».
///
/// L'écran suit l'état de la demande : à faire, en cours d'examen,
/// certifié, ou refusée (avec le motif, et la possibilité de renvoyer).
class CertificationPage extends StatefulWidget {
  const CertificationPage({super.key});

  @override
  State<CertificationPage> createState() => _CertificationPageState();
}

class _CertificationPageState extends State<CertificationPage> {
  late final CertificationService _service = CertificationService(sl<Dio>());

  StatutCertification? _statut;
  bool _chargement = true;
  String? _erreur;

  String? _recto;
  String? _verso;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final s = await _service.statut();
      if (!mounted) return;
      setState(() {
        _statut = s;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = 'Impossible de charger votre certification.';
      });
    }
  }

  /// Appareil photo ou galerie, au choix du vendeur.
  Future<void> _choisir({required bool recto}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColor.kWhite,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (x == null || !mounted) return;
      setState(() {
        if (recto) {
          _recto = x.path;
        } else {
          _verso = x.path;
        }
      });
    } catch (_) {
      _dire("La photo n'a pas pu être récupérée. Réessayez.");
    }
  }

  Future<void> _envoyer() async {
    if (_recto == null || _verso == null) {
      _dire('Ajoutez la photo du recto et celle du verso.');
      return;
    }
    setState(() => _envoi = true);
    try {
      final message = await _service.soumettre(
        rectoPath: _recto!,
        versoPath: _verso!,
      );
      if (!mounted) return;
      _dire(message);
      setState(() {
        _recto = null;
        _verso = null;
      });
      await _charger();
    } on DioException catch (e) {
      final data = e.response?.data;
      _dire(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Envoi impossible. Vérifiez votre connexion et réessayez.',
      );
    } catch (_) {
      _dire('Envoi impossible. Réessayez.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _dire(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: const AppAppBar(title: 'Certification'),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_erreur!, style: const TextStyle(color: Color(0xFF5B6C8A))),
                  TextButton(onPressed: _charger, child: const Text('Réessayer')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: _contenu(_statut!),
            ),
    );
  }

  List<Widget> _contenu(StatutCertification s) {
    if (s.certifie) {
      return [
        const _Etat(
          icone: Icons.verified_rounded,
          couleur: AppColor.kSucces,
          fond: AppColor.kSuccesLight,
          titre: 'Votre boutique est certifiée',
          texte:
              'Le badge de certification s\'affiche sur votre boutique et sur '
              'votre site. Vos clients savent qu\'ils achètent chez un vendeur '
              'dont l\'identité a été vérifiée.',
        ),
      ];
    }
    if (s.enAttente) {
      return [
        const _Etat(
          icone: Icons.hourglass_top_rounded,
          couleur: AppColor.kPrimary,
          fond: AppColor.kPrimaryLight,
          titre: 'Demande en cours d\'examen',
          texte:
              'Nous avons bien reçu votre pièce d\'identité. Notre équipe '
              'l\'examine sous 48 h ; vous serez prévenu dès que c\'est fait.',
        ),
      ];
    }
    return [
      if (s.rejete) ...[
        _Etat(
          icone: Icons.error_outline_rounded,
          couleur: AppColor.kErreur,
          fond: AppColor.kErreurLight,
          titre: 'Demande refusée',
          texte: (s.motifRejet ?? '').trim().isEmpty
              ? 'Votre demande n\'a pas pu être acceptée. Vous pouvez envoyer '
                    'de nouvelles photos.'
              : '${s.motifRejet!.trim()}\n\nVous pouvez envoyer de nouvelles photos.',
        ),
        const SizedBox(height: 18),
      ],
      const Text(
        'Faites certifier votre boutique',
        style: TextStyle(
          fontFamily: kPolice,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColor.kPrimary,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Une boutique certifiée inspire confiance : vos clients voient le '
        'badge de certification et commandent plus facilement.',
        style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF5B6C8A)),
      ),
      const SizedBox(height: 16),
      const _Avantage(
        icone: Icons.verified_outlined,
        texte: 'Un badge de certification sur votre boutique et votre site',
      ),
      const _Avantage(
        icone: Icons.handshake_outlined,
        texte: 'Plus de confiance chez vos clients, donc plus de commandes',
      ),
      const _Avantage(
        icone: Icons.trending_up_rounded,
        texte: 'Votre boutique est mieux mise en avant dans l\'application',
      ),
      const SizedBox(height: 22),
      const Text(
        'Votre pièce d\'identité',
        style: TextStyle(
          fontFamily: kPolice,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColor.kPrimary,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Carte d\'identité ou passeport. Photos nettes, sans reflet, avec '
        'toutes les informations lisibles.',
        style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF5B6C8A)),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _ZonePhoto(
              libelle: 'Recto',
              chemin: _recto,
              onTap: _envoi ? null : () => _choisir(recto: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ZonePhoto(
              libelle: 'Verso',
              chemin: _verso,
              onTap: _envoi ? null : () => _choisir(recto: false),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _envoi ? null : _envoyer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.kSecondary,
            foregroundColor: AppColor.kPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _envoi
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColor.kPrimary,
                  ),
                )
              : const Text(
                  'Envoyer ma demande',
                  style: TextStyle(fontFamily: kPolice, fontWeight: FontWeight.w700),
                ),
        ),
      ),
      const SizedBox(height: 12),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF5B6C8A)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vos photos servent uniquement à vérifier votre identité. '
              'Elles ne sont jamais montrées à vos clients.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF5B6C8A)),
            ),
          ),
        ],
      ),
    ];
  }
}

class _Etat extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final Color fond;
  final String titre;
  final String texte;
  const _Etat({
    required this.icone,
    required this.couleur,
    required this.fond,
    required this.titre,
    required this.texte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: couleur, size: 34),
          const SizedBox(height: 10),
          Text(
            titre,
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: couleur,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            texte,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avantage extends StatelessWidget {
  final IconData icone;
  final String texte;
  const _Avantage({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: AppColor.kSucces),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emplacement d'une photo (recto ou verso) : vide, il invite à l'ajouter ;
/// rempli, il la montre, et un appui permet de la remplacer.
class _ZonePhoto extends StatelessWidget {
  final String libelle;
  final String? chemin;
  final VoidCallback? onTap;
  const _ZonePhoto({required this.libelle, required this.chemin, this.onTap});

  @override
  Widget build(BuildContext context) {
    final remplie = chemin != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 128,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColor.kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: remplie ? AppColor.kSucces : const Color(0xFFD5DBE6),
            width: 1.5,
          ),
        ),
        child: remplie
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(chemin!), fit: BoxFit.cover),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColor.kSucces,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$libelle · changer',
                        style: const TextStyle(
                          color: AppColor.kWhite,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColor.kPrimary,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    libelle,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kPrimary,
                    ),
                  ),
                  const Text(
                    'Ajouter la photo',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5B6C8A)),
                  ),
                ],
              ),
      ),
    );
  }
}
