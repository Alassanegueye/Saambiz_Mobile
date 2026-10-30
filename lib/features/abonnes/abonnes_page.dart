import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:saambiz/core/utils/image_url.dart';

import '../../core/theme/app_color.dart';
import '../../injection_container.dart';

/// Un client abonné à la boutique du vendeur.
class Abonne {
  final String id;
  final String prenom;
  final String nom;
  final String? photo;
  final bool clocheActive;
  final DateTime? depuis;

  const Abonne({
    required this.id,
    required this.prenom,
    required this.nom,
    this.photo,
    this.clocheActive = false,
    this.depuis,
  });

  String get nomComplet => '$prenom $nom'.trim().isEmpty ? 'Client' : '$prenom $nom'.trim();

  factory Abonne.fromJson(Map<String, dynamic> j) => Abonne(
        id: j['id']?.toString() ?? '',
        prenom: j['prenom']?.toString() ?? '',
        nom: j['nom']?.toString() ?? '',
        photo: (j['photo'] ?? '').toString().isEmpty ? null : j['photo'].toString(),
        clocheActive: j['clocheActive'] == true,
        depuis: j['depuis'] == null ? null : DateTime.tryParse(j['depuis'].toString())?.toLocal(),
      );
}

/// Les abonnés de la boutique (GET /vendeur/abonnes).
class AbonnesService {
  AbonnesService._();

  static Future<List<Abonne>> charger() async {
    final res = await sl<Dio>().get('/vendeur/abonnes');
    final brut = res.data is Map ? res.data as Map : const {};
    final data = brut['data'] is Map ? brut['data'] as Map : brut;
    return (data['abonnes'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Abonne.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// Liste des clients abonnés à la boutique. Seuls ceux qui ont activé la
/// cloche reçoivent les notifications (promotions, messages, nouveautés).
class AbonnesPage extends StatefulWidget {
  const AbonnesPage({super.key});

  @override
  State<AbonnesPage> createState() => _AbonnesPageState();
}

class _AbonnesPageState extends State<AbonnesPage> {
  List<Abonne>? _abonnes;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      final liste = await AbonnesService.charger();
      if (mounted) setState(() => _abonnes = liste);
    } catch (_) {
      if (mounted) setState(() => _erreur = 'Impossible de charger vos abonnés. Vérifiez votre connexion.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final liste = _abonnes;
    final avecCloche = liste?.where((a) => a.clocheActive).length ?? 0;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: AppColor.kWhite,
        elevation: 0.5,
        foregroundColor: AppColor.kGrayscaleDark100,
        title: Text(liste == null ? 'Mes abonnés' : 'Mes abonnés (${liste.length})',
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColor.kPrimary,
        onRefresh: _charger,
        child: _erreur != null
            ? ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(_erreur!, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: AppColor.kGrayscale40)),
                ),
              ])
            : liste == null
                ? const Center(child: CircularProgressIndicator(color: AppColor.kPrimary, strokeWidth: 2.5))
                : liste.isEmpty
                    ? ListView(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
                          child: Column(children: [
                            const Icon(Icons.people_outline_rounded, size: 46, color: AppColor.kGrayscale30),
                            const SizedBox(height: 12),
                            Text('Aucun abonné pour l\'instant',
                                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100)),
                            const SizedBox(height: 6),
                            Text('Les clients qui suivent votre boutique apparaîtront ici.',
                                textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40)),
                          ]),
                        ),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: liste.length + 1,
                        separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 12 : 8),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColor.kPrimaryLight, borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                const Icon(Icons.notifications_active_outlined, size: 20, color: AppColor.kPrimary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '$avecCloche sur ${liste.length} ont activé la cloche : ce sont eux qui reçoivent vos promotions et messages.',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColor.kPrimary, height: 1.4),
                                  ),
                                ),
                              ]),
                            );
                          }
                          return _LigneAbonne(abonne: liste[i - 1]);
                        },
                      ),
      ),
    );
  }
}

class _LigneAbonne extends StatelessWidget {
  final Abonne abonne;
  const _LigneAbonne({required this.abonne});

  @override
  Widget build(BuildContext context) {
    final a = abonne;
    final initiale = a.prenom.isNotEmpty ? a.prenom[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.kLine),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColor.kPrimaryLight,
          backgroundImage: a.photo != null ? CachedNetworkImageProvider(imageOptimisee(a.photo!, largeur: 128)) : null,
          child: a.photo == null
              ? Text(initiale, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColor.kPrimary))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.nomComplet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100)),
            if (a.depuis != null)
              Text('Abonné depuis le ${DateFormat('dd/MM/yyyy').format(a.depuis!)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
          ]),
        ),
        Tooltip(
          message: a.clocheActive ? 'Reçoit vos notifications' : 'Cloche désactivée : ne reçoit pas vos notifications',
          child: Icon(
            a.clocheActive ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
            color: a.clocheActive ? AppColor.kSucces : AppColor.kGrayscale30,
            size: 22,
          ),
        ),
      ]),
    );
  }
}
