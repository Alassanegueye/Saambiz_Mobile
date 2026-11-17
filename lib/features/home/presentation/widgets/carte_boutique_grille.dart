import 'package:flutter/material.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/image_reseau.dart';
import '../../../../core/widgets/logo_boutique.dart';
import '../../../catalogue/data/produit_catalogue.dart';
import '../../../catalogue/presentation/pages/boutique_publique_page.dart';

/// Carte d'une boutique dans une grille (deux par ligne sur téléphone) :
/// couverture, logo centré à cheval sur son bord, nom, catégorie, ville,
/// note ou distance quand le serveur les donne, et « Voir la boutique ».
///
/// La note n'apparaît que si la boutique en a une : une boutique sans avis
/// n'affiche pas de chiffre de remplissage.
class CarteBoutiqueGrille extends StatelessWidget {
  final Map<String, dynamic> donnees;

  /// Remplace « Voir la boutique » en bas de la carte (par exemple les
  /// alertes d'une boutique suivie). Hauteur attendue : 36.
  final Widget? action;

  /// Posé dans l'angle haut droit de la couverture (par exemple le cœur).
  final Widget? coin;

  const CarteBoutiqueGrille({
    super.key,
    required this.donnees,
    this.action,
    this.coin,
  });

  static const double _hauteurCouverture = 74;
  static const double _tailleLogo = 60;

  /// Hauteur d'une carte, agrandie avec la taille de texte du système pour
  /// que rien ne déborde.
  static double hauteur(BuildContext context) {
    final echelle = MediaQuery.textScalerOf(context).scale(10) / 10;
    // 262 : le nom tient sur deux lignes. « Atelier Wax & Cuir » ou
    // « Maison Ndiaye Couture » se coupaient en plein milieu sur une seule.
    return 262 + (echelle - 1).clamp(0.0, 2.0).toDouble() * 64;
  }

  /// Largeur de la même carte dans un carrousel horizontal (l'accueil).
  ///
  /// Deux cartes entières, plus l'amorce d'une troisième : c'est cette amorce
  /// qui dit qu'on peut faire défiler. Sans elle, une rangée pleine ressemble
  /// à une grille arrêtée, et personne ne pense à glisser.
  static double largeurCarrousel(BuildContext context) {
    final ecran = MediaQuery.sizeOf(context).width;
    // 32 de marges, 12 d'écart entre deux cartes, 28 laissés à l'amorce.
    return ((ecran - 32 - 12 - 28) / 2).clamp(155.0, 230.0);
  }

  /// Grille de cartes : 2 colonnes sur téléphone, 3 sur petite tablette,
  /// 4 au-delà.
  static SliverGridDelegate grille(BuildContext context) {
    final largeur = MediaQuery.sizeOf(context).width;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: largeur >= 900
          ? 4
          : largeur >= 600
          ? 3
          : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 14,
      mainAxisExtent: hauteur(context),
    );
  }

  void _ouvrir(BuildContext context) {
    final id = donnees['id']?.toString();
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoutiquePubliquePage(
          boutiqueId: id,
          apercu: BoutiqueResume.fromJson(donnees),
        ),
      ),
    );
  }

  static String _decimal(num n) => n.toStringAsFixed(1).replaceAll('.', ',');

  String _texte(String cle) => (donnees[cle] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final nom = _texte('nom').isEmpty ? 'Boutique' : _texte('nom');
    final logo = _texte('logo');
    final banniere = _texte('banniere');
    final verifiee = donnees['verifiee'] == true;
    final categorie = _texte('categorie').isNotEmpty
        ? _texte('categorie')
        : _texte('slogan');
    final ville = _texte('localisation');
    final note = donnees['note'];
    final nombreAvis = donnees['nombreAvis'];
    final aUneNote =
        note is num && note > 0 && (nombreAvis is! num || nombreAvis > 0);
    final distance = donnees['distanceKm'];

    // La note reste entière ; la ville (ou la distance) cède la place si la
    // carte est étroite.
    final infos = <_Info>[
      if (aUneNote)
        _Info(
          icone: Icons.star_rounded,
          couleurIcone: AppColor.kSecondary,
          texte: _decimal(note),
          fort: true,
        ),
      if (distance is num)
        _Info(
          icone: Icons.near_me_outlined,
          texte: '${_decimal(distance)} km',
          souple: true,
        )
      else if (ville.isNotEmpty)
        _Info(icone: Icons.location_on_outlined, texte: ville, souple: true),
    ];

    // Sans bannière : un aplat bleu très clair, sur lequel le logo ressort.
    // En marine, sous l'en-tête marine, la page devenait un mur sombre et
    // les logos par défaut (marine eux aussi) s'y fondaient.
    const fondCouverture = ColoredBox(color: AppColor.kPrimaryLight);

    return Semantics(
      button: true,
      label: 'Voir la boutique $nom',
      child: Pressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _ouvrir(context),
          child: Container(
            // Le contenu (couverture comprise) suit les coins arrondis.
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColor.kWhite,
              borderRadius: AppDim.brCarte,
              border: Border.all(color: AppColor.kLine),
              boxShadow: AppDim.ombreCarte,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Couverture, puis le logo centré à cheval sur son bord.
                SizedBox(
                  height: _hauteurCouverture + _tailleLogo / 2,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: _hauteurCouverture,
                        child: banniere.isNotEmpty
                            ? ImageReseau(
                                banniere,
                                largeurServeur: 480,
                                fit: BoxFit.cover,
                                repli: fondCouverture,
                              )
                            : fondCouverture,
                      ),
                      Positioned(
                        top: _hauteurCouverture - _tailleLogo / 2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: _tailleLogo,
                            height: _tailleLogo,
                            decoration: BoxDecoration(
                              color: AppColor.kWhite,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColor.kWhite,
                                width: 3,
                              ),
                              boxShadow: AppDim.ombreFlottante,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: logo.isNotEmpty
                                        ? ImageReseau(
                                            logo,
                                            largeurServeur: 180,
                                            fit: BoxFit.cover,
                                            repli:
                                                const LogoBoutiqueParDefaut(),
                                          )
                                        : const LogoBoutiqueParDefaut(),
                                  ),
                                ),
                                if (verifiee)
                                  Positioned(
                                    right: -3,
                                    bottom: -3,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColor.kWhite,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: AppColor.kSecondary,
                                        semanticLabel: 'Boutique vérifiée',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (coin != null)
                        Positioned(top: 4, right: 4, child: coin!),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        // Le nom seul. La pastille « vérifiée » vit sur le
                        // logo : dans le fil du texte elle se retrouvait
                        // seule sur la deuxième ligne des que le nom
                        // remplissait la première, et une espace insécable
                        // ne lie pas un WidgetSpan.
                        Text(
                          nom,
                          // Deux lignes : les noms de boutique sont souvent
                          // longs, et un nom coupé est un nom qu'on ne
                          // reconnaît pas.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                        if (categorie.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            categorie,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 12,
                              height: 1.3,
                              color: AppColor.kGrayscale40,
                            ),
                          ),
                        ],
                        if (infos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < infos.length; i++) ...[
                                if (i > 0)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '·',
                                      style: TextStyle(
                                        color: AppColor.kGrayscale30,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                if (infos[i].souple)
                                  Flexible(child: infos[i])
                                else
                                  infos[i],
                              ],
                            ],
                          ),
                        ],
                        const Spacer(),
                        action ??
                            Container(
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColor.kPrimaryLight,
                                borderRadius: AppDim.brMoyen,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Voir la boutique',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: kPolice,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.kPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: AppColor.kPrimary,
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Une information courte de la carte : note, distance ou ville.
class _Info extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Color couleurIcone;
  final bool fort;

  /// Peut rétrécir (texte coupé) : à placer dans un [Flexible].
  final bool souple;
  const _Info({
    required this.icone,
    required this.texte,
    this.couleurIcone = AppColor.kGrayscale40,
    this.fort = false,
    this.souple = false,
  });

  @override
  Widget build(BuildContext context) {
    final libelle = Text(
      texte,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: kPolice,
        fontSize: 12,
        height: 1.3,
        fontWeight: fort ? FontWeight.w700 : FontWeight.w500,
        color: fort ? AppColor.kGrayscaleDark100 : AppColor.kGrayscale40,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: couleurIcone),
        const SizedBox(width: 3),
        // Sans contrainte de largeur (élément non souple), un Flexible
        // ferait échouer la mise en page.
        if (souple) Flexible(child: libelle) else libelle,
      ],
    );
  }
}

/// Squelette d'une grille de boutiques pendant le chargement.
class SqueletteCartesBoutiques extends StatelessWidget {
  const SqueletteCartesBoutiques({super.key});

  @override
  Widget build(BuildContext context) {
    return Reflet(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        gridDelegate: CarteBoutiqueGrille.grille(context),
        itemCount: 6,
        itemBuilder: (_, __) =>
            const Os(hauteur: double.infinity, rayon: AppDim.rayonCarte),
      ),
    );
  }
}
