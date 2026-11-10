import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../core/theme/app_color.dart';
import '../../core/utils/texte.dart';
import '../../core/utils/url_externe.dart';
import '../../injection_container.dart';
import '../messagerie/presentation/pages/chat_page.dart';
import 'abonnes_page.dart';

/// Activité d'un abonné dans la boutique (GET /vendeur/abonnes/:id).
class FicheAbonne {
  final int commandes;
  final int produitsCommandes;
  final DateTime? derniereCommande;
  final bool fidele;

  const FicheAbonne({
    required this.commandes,
    required this.produitsCommandes,
    required this.derniereCommande,
    required this.fidele,
  });

  factory FicheAbonne.fromJson(Map<String, dynamic> j) {
    final activite = j['activite'] is Map ? j['activite'] as Map : const {};
    return FicheAbonne(
      commandes: (activite['commandes'] as num?)?.toInt() ?? 0,
      produitsCommandes: (activite['produitsCommandes'] as num?)?.toInt() ?? 0,
      derniereCommande: DateTime.tryParse(
        activite['derniereCommande']?.toString() ?? '',
      )?.toLocal(),
      fidele: j['fidelite'] == 'fidele',
    );
  }

  static Future<FicheAbonne> charger(String id) async {
    final res = await sl<Dio>().get('/vendeur/abonnes/$id');
    final brut = res.data is Map ? res.data as Map : const {};
    final data = brut['data'] is Map ? brut['data'] as Map : brut;
    return FicheAbonne.fromJson(Map<String, dynamic>.from(data));
  }
}

/// Fiche d'un abonné : profil, activité dans la boutique et fidélité.
class AbonneDetailPage extends StatefulWidget {
  final Abonne abonne;
  const AbonneDetailPage({super.key, required this.abonne});

  @override
  State<AbonneDetailPage> createState() => _AbonneDetailPageState();
}

class _AbonneDetailPageState extends State<AbonneDetailPage> {
  FicheAbonne? _fiche;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = false);
    try {
      final fiche = await FicheAbonne.charger(widget.abonne.id);
      if (mounted) setState(() => _fiche = fiche);
    } catch (_) {
      if (mounted) setState(() => _erreur = true);
    }
  }

  void _contacter() {
    final a = widget.abonne;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColor.kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (feuille) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: const Text('Envoyer un message'),
              onTap: () {
                Navigator.pop(feuille);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      interlocuteurId: a.id,
                      interlocuteurNom: a.nomComplet,
                    ),
                  ),
                );
              },
            ),
            if (a.telephone != null)
              ListTile(
                leading: const Icon(Icons.call_outlined),
                title: Text('Appeler le ${a.telephone}'),
                onTap: () {
                  Navigator.pop(feuille);
                  _ouvrir('tel:${a.telephone}');
                },
              ),
            if (a.email != null)
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: Text('Écrire à ${a.email}'),
                onTap: () {
                  Navigator.pop(feuille);
                  _ouvrir('mailto:${a.email}');
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _ouvrir(String url) async {
    final messager = ScaffoldMessenger.of(context);
    if (await UrlExterne.lancer(url)) return;
    messager.showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir ce contact.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.abonne;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: const Text(
          'Fiche abonné',
          style: TextStyle(
            fontFamily: kPolice,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColor.kPrimary,
        onRefresh: _charger,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Bloc(
              child: Column(
                children: [
                  AvatarAbonne(abonne: a, rayon: 36),
                  const SizedBox(height: 12),
                  Text(
                    a.nomComplet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                  if (a.email != null) _LigneProfil(a.email!),
                  if (a.telephone != null) _LigneProfil(a.telephone!),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _contacter,
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Contacter'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _corpsActivite(),
          ],
        ),
      ),
    );
  }

  Widget _corpsActivite() {
    final fiche = _fiche;
    if (_erreur && fiche == null) {
      return _Bloc(
        child: Column(
          children: [
            const Text(
              'Impossible de charger l\'activité de cet abonné.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kPolice,
                color: AppColor.kGrayscale40,
              ),
            ),
            TextButton(onPressed: _charger, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (fiche == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColor.kPrimary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    final derniere = fiche.derniereCommande;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Bloc(
          titre: 'Activité',
          child: Column(
            children: [
              _LigneActivite('Commandes', '${fiche.commandes}'),
              _LigneActivite(
                'Produits commandés',
                '${fiche.produitsCommandes}',
              ),
              _LigneActivite(
                'Dernière commande',
                derniere == null ? 'Aucune' : dateLongue(derniere),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Bloc(
          titre: 'Statut de fidélité',
          child: Align(
            alignment: Alignment.centerLeft,
            child: _BadgeFidelite(fidele: fiche.fidele),
          ),
        ),
      ],
    );
  }
}

class _Bloc extends StatelessWidget {
  final String? titre;
  final Widget child;
  const _Bloc({this.titre, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titre != null) ...[
            Text(
              titre!,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _LigneProfil extends StatelessWidget {
  final String texte;
  const _LigneProfil(this.texte);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        texte,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: kPolice,
          fontSize: 14,
          color: AppColor.kGrayscale40,
        ),
      ),
    );
  }
}

class _LigneActivite extends StatelessWidget {
  final String libelle;
  final String valeur;
  const _LigneActivite(this.libelle, this.valeur);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              libelle,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 14,
                color: AppColor.kGrayscale40,
              ),
            ),
          ),
          Text(
            valeur,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeFidelite extends StatelessWidget {
  final bool fidele;
  const _BadgeFidelite({required this.fidele});

  @override
  Widget build(BuildContext context) {
    final couleur = fidele ? AppColor.kSucces : AppColor.kPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fidele ? AppColor.kSuccesLight : AppColor.kPrimaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            fidele ? Icons.star_rounded : Icons.fiber_new_rounded,
            size: 18,
            color: couleur,
          ),
          const SizedBox(width: 6),
          Text(
            fidele ? 'Client fidèle' : 'Nouveau client',
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}
