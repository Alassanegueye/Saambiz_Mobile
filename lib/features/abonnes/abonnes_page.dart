import 'package:dio/dio.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../core/theme/app_color.dart';
import '../../core/utils/texte.dart';
import '../../injection_container.dart';
import 'abonne_detail_page.dart';

/// Un client abonné à la boutique du vendeur.
class Abonne {
  final String id;
  final String prenom;
  final String nom;
  final String? photo;
  final String? email;
  final String? telephone;
  final bool clocheActive;
  final DateTime? depuis;

  const Abonne({
    required this.id,
    required this.prenom,
    required this.nom,
    this.photo,
    this.email,
    this.telephone,
    this.clocheActive = false,
    this.depuis,
  });

  String get nomComplet =>
      '$prenom $nom'.trim().isEmpty ? 'Client' : '$prenom $nom'.trim();

  factory Abonne.fromJson(Map<String, dynamic> j) => Abonne(
    id: j['id']?.toString() ?? '',
    prenom: j['prenom']?.toString() ?? '',
    nom: j['nom']?.toString() ?? '',
    photo: (j['photo'] ?? '').toString().isEmpty ? null : j['photo'].toString(),
    email: _texteOuNull(j['email']),
    telephone: _texteOuNull(j['telephone']),
    clocheActive: j['clocheActive'] == true,
    depuis: j['depuis'] == null
        ? null
        : DateTime.tryParse(j['depuis'].toString())?.toLocal(),
  );
}

String? _texteOuNull(Object? valeur) {
  final texte = valeur?.toString().trim() ?? '';
  return texte.isEmpty ? null : texte;
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
      if (mounted) {
        setState(
          () => _erreur =
              'Impossible de charger vos abonnés. Vérifiez votre connexion.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final liste = _abonnes;
    final avecCloche = liste?.where((a) => a.clocheActive).length ?? 0;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: Text(
          liste == null ? 'Mes abonnés' : 'Mes abonnés (${liste.length})',
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColor.kPrimary,
        onRefresh: _charger,
        child: _erreur != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _erreur!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                  ),
                ],
              )
            : liste == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColor.kPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : liste.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.fromLTRB(32, 80, 32, 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 46,
                          color: AppColor.kGrayscale30,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Aucun abonné pour l\'instant',
                          style: TextStyle(
                            fontFamily: kPolice,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Les clients qui suivent votre boutique apparaîtront ici.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: kPolice,
                            fontSize: 13,
                            color: AppColor.kGrayscale40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: liste.length + 1,
                separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 12 : 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.kPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_outlined,
                            size: 20,
                            color: AppColor.kPrimary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$avecCloche sur ${liste.length} ont activé la cloche : ce sont eux qui reçoivent vos promotions et messages.',
                              style: const TextStyle(
                                fontFamily: kPolice,
                                fontSize: 12.5,
                                color: AppColor.kPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarAbonne(abonne: a, rayon: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  a.nomComplet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
              ),
              Tooltip(
                message: a.clocheActive
                    ? 'Reçoit vos notifications'
                    : 'Cloche désactivée : ne reçoit pas vos notifications',
                child: Icon(
                  a.clocheActive
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  color: a.clocheActive
                      ? AppColor.kSucces
                      : AppColor.kGrayscale30,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (a.email != null) _Info(libelle: 'E-mail', valeur: a.email!),
          if (a.telephone != null)
            _Info(libelle: 'Téléphone', valeur: a.telephone!),
          if (a.depuis != null)
            Text(
              'Abonné depuis le ${dateLongue(a.depuis!)}',
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 13,
                color: AppColor.kGrayscale40,
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AbonneDetailPage(abonne: a)),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Voir plus'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String libelle;
  final String valeur;
  const _Info({required this.libelle, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          text: '$libelle : ',
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColor.kGrayscaleDark100,
          ),
          children: [
            TextSpan(
              text: valeur,
              style: const TextStyle(
                fontFamily: kPolice,
                fontWeight: FontWeight.w400,
                color: AppColor.kGrayscale40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo de l'abonné, ou son initiale.
class AvatarAbonne extends StatelessWidget {
  final Abonne abonne;
  final double rayon;
  const AvatarAbonne({super.key, required this.abonne, required this.rayon});

  @override
  Widget build(BuildContext context) {
    final photo = abonne.photo;
    final initiale = abonne.prenom.isNotEmpty
        ? abonne.prenom[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: rayon,
      backgroundColor: AppColor.kPrimaryLight,
      backgroundImage: photo != null
          ? fournisseurImageReseau(photo, largeurServeur: 128)
          : null,
      child: photo == null
          ? Text(
              initiale,
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: rayon * 0.8,
                fontWeight: FontWeight.w800,
                color: AppColor.kPrimary,
              ),
            )
          : null,
    );
  }
}
