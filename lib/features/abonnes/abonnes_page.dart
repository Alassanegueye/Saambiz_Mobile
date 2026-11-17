import 'package:saambiz/core/widgets/page_vendeur.dart';
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

/// Qui reçoit les notifications, accordé au nombre : « 0 sur 2 ont activé la
/// cloche : ce sont eux qui… » ne désignait personne.
String libelleCloche(int avecCloche, int total) {
  if (avecCloche <= 0) {
    return 'Aucun abonné n’a encore activé la cloche : seuls ceux qui '
        'l’activent reçoivent vos promotions et messages.';
  }
  if (avecCloche >= total) {
    return total == 1
        ? 'Votre abonné a activé la cloche : vos promotions et messages '
              'lui parviennent.'
        : 'Vos $total abonnés ont activé la cloche : vos promotions et '
              'messages leur parviennent.';
  }
  return avecCloche == 1
      ? '1 abonné sur $total a activé la cloche : lui seul reçoit vos '
            'promotions et messages.'
      : '$avecCloche abonnés sur $total ont activé la cloche : eux seuls '
            'reçoivent vos promotions et messages.';
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
    return ScaffoldMarine(
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
                              libelleCloche(avecCloche, liste.length),
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

/// Un abonné sur une ligne : photo ou initiales, nom, date d'abonnement,
/// cloche. Le toucher ouvre sa fiche (coordonnées, activité, contact) :
/// chaque carte portait son propre bouton « Voir plus » pleine largeur.
class _LigneAbonne extends StatelessWidget {
  final Abonne abonne;
  const _LigneAbonne({required this.abonne});

  @override
  Widget build(BuildContext context) {
    final a = abonne;
    return Material(
      color: AppColor.kWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => AbonneDetailPage(abonne: a))),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.kLine),
          ),
          child: Row(
            children: [
              AvatarAbonne(abonne: a, rayon: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.nomComplet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    if (a.depuis != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Abonné depuis le ${dateLongue(a.depuis!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 12.5,
                          color: AppColor.kGrayscale40,
                        ),
                      ),
                    ],
                  ],
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
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColor.kGrayscale30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo de l'abonné, ou ses initiales.
class AvatarAbonne extends StatelessWidget {
  final Abonne abonne;
  final double rayon;
  const AvatarAbonne({super.key, required this.abonne, required this.rayon});

  @override
  Widget build(BuildContext context) {
    final photo = abonne.photo;
    final lettres = initialesDe('${abonne.prenom} ${abonne.nom}');
    final initiales = lettres.isEmpty ? '?' : lettres;
    return CircleAvatar(
      radius: rayon,
      backgroundColor: AppColor.kPrimaryLight,
      backgroundImage: photo != null
          ? fournisseurImageReseau(photo, largeurServeur: 128)
          : null,
      child: photo == null
          ? Text(
              initiales,
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: rayon * (initiales.length > 1 ? 0.7 : 0.8),
                fontWeight: FontWeight.w800,
                color: AppColor.kPrimary,
              ),
            )
          : null,
    );
  }
}
