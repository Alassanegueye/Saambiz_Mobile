import 'package:saambiz/core/widgets/messages.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/widgets/logo_boutique.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/widgets/degrade_fond.dart';
import '../../../../injection_container.dart';
import '../../data/catalogue_remote_datasource.dart';
import '../../data/produit_catalogue.dart';
import '../../../signalements/presentation/ouvrir_signalement.dart';
import '../widgets/bouton_panier.dart';
import '../widgets/compte_a_rebours.dart';
import '../widgets/produit_card.dart';
import 'boutique_publique_page.dart';

/// Fiche d'un produit : galerie, prix et promotion (compte à rebours),
/// options à choisir (taille, parfum…), quantité, caractéristiques,
/// boutique, produits similaires, barre d'achat fixe.
class ProduitDetailPage extends StatefulWidget {
  final ProduitCatalogue produit;
  const ProduitDetailPage({super.key, required this.produit});

  @override
  State<ProduitDetailPage> createState() => _ProduitDetailPageState();
}

class _ProduitDetailPageState extends State<ProduitDetailPage> {
  final _galerie = PageController();
  int _page = 0;

  /// La photo a défilé : la barre devient blanche et prend le nom du
  /// produit.
  final _defilement = ScrollController();
  bool _replie = false;

  late ProduitCatalogue p = widget.produit;
  List<ProduitCatalogue> _similaires = [];
  bool _similairesEnCours = true;

  /// Options choisies : { libellé: valeur }.
  final Map<String, String> _choix = {};
  bool _choixManquant = false;
  int _quantite = 1;

  int get _quantiteMax => p.stock > 0 ? p.stock : 99;

  @override
  void initState() {
    super.initState();
    _defilement.addListener(() {
      final replie = _defilement.offset > 260;
      if (replie != _replie) setState(() => _replie = replie);
    });
    _charger();
  }

  @override
  void dispose() {
    _galerie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  /// Fiche complète (galerie, prix à jour) et similaires. La carte ouverte
  /// reste affichée pendant le chargement.
  Future<void> _charger() async {
    final source = CatalogueRemoteDataSource(sl<Dio>());

    // La vue est comptée par le serveur à cette lecture de la fiche. Un
    // second appel (POST /acheteurs/produit/:id/vue) la comptait en double.
    try {
      final res = await source.detail(widget.produit.id);
      if (!mounted) return;
      setState(() {
        p = res.produit;
        _similaires = res.similaires;
        _similairesEnCours = false;
      });
    } catch (_) {
      if (mounted) setState(() => _similairesEnCours = false);
    }
  }

  bool get _optionsCompletes =>
      p.options.every((o) => _choix.containsKey(o.libelle));

  Future<void> _ajouter() async {
    if (!_optionsCompletes) {
      setState(() => _choixManquant = true);
      final manquante = p.options.firstWhere(
        (o) => !_choix.containsKey(o.libelle),
      );
      afficherErreur(
        context,
        'Choisissez : ${manquante.libelle.toLowerCase()}',
      );
      return;
    }
    await ajouterAuPanier(
      context,
      p,
      quantite: _quantite,
      options: Map.of(_choix),
    );
  }

  Future<void> _whatsapp() async {
    final tel = (p.boutique?.telephone ?? '').replaceAll(RegExp(r'\D'), '');
    if (tel.isEmpty) {
      afficherInfo(
        context,
        'Cette boutique n\'a pas indiqué de numéro WhatsApp.',
      );
      return;
    }
    final numero = tel.length == 9 ? '221$tel' : tel;
    final texte = Uri.encodeComponent(
      'Bonjour, je suis intéressé(e) par « ${p.nom} » vu sur SaamBiz.',
    );
    final ok = await UrlExterne.lancer('https://wa.me/$numero?text=$texte');
    if (!ok && mounted) {
      afficherErreur(
        context,
        'WhatsApp n\'est pas disponible sur cet appareil.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        body: Stack(
          children: [
            FondDegradeSubtil(
              child: RefreshIndicator(
                color: AppColor.kPrimary,
                edgeOffset: haut + 56,
                onRefresh: _charger,
                child: ListView(
                  controller: _defilement,
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    _blocGalerie(haut),
                    _blocPrincipal(),
                    if (p.caracteristiques.isNotEmpty) _blocCaracteristiques(),
                    if (p.description.trim().isNotEmpty) _blocDescription(),
                    if (p.boutique != null) _blocBoutique(),
                    _blocSimilaires(),
                  ],
                ),
              ),
            ),
            // Barre flottante : retour, panier, signaler, posés sur la
            // photo ; blanche et titrée du nom du produit une fois la photo
            // passée.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: _replie ? AppColor.kWhite : Colors.transparent,
                  boxShadow: _replie ? AppDim.ombreCarte : null,
                ),
                padding: EdgeInsets.fromLTRB(12, haut + 6, 12, 8),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      _Pastille(
                        child: IconButton(
                          tooltip: 'Retour',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColor.kPrimary,
                          ),
                        ),
                      ),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: _replie ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            p.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColor.kGrayscaleDark100,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const _Pastille(child: BoutonPanier()),
                    const SizedBox(width: 8),
                    _Pastille(
                      child: MenuSignaler(
                        type: 'produit',
                        cibleId: widget.produit.id,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _barreAchat(),
      ),
    );
  }

  // Galerie : pleine largeur, jusque sous la barre d'état ; la photo
  // commence sous les boutons flottants.
  Widget _blocGalerie(double haut) {
    final images = p.visuels;
    return Container(
      height: 340 + haut,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          if (images.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: haut + 40),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 56,
                  color: AppColor.kGrayscale30,
                ),
              ),
            )
          else
            PageView.builder(
              controller: _galerie,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Padding(
                padding: EdgeInsets.fromLTRB(20, haut + 60, 20, 28),
                child: ImageReseau(
                  images[i],
                  fit: BoxFit.contain,
                  repli: const Icon(
                    Icons.image_outlined,
                    color: AppColor.kGrayscale30,
                  ),
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final actif = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: actif ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: actif ? AppColor.kPrimary : AppColor.kLine,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // Nom, prix, promotion, options, quantité
  Widget _blocPrincipal() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: decorationCarte(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.nom,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                    height: 1.3,
                  ),
                ),
              ),
              if (p.remise > 0) ...[
                const SizedBox(width: 10),
                PastilleReduction(pourcentage: p.remise, taille: 15),
              ],
            ],
          ),
          if (p.enRupture) ...[
            const SizedBox(height: 10),
            const BadgeRupture(),
          ],
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            children: [
              Text(
                formaterPrix(p.prixPaye),
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kPrimary,
                ),
              ),
              if (p.prixBarre != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    formaterPrix(p.prixBarre!),
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14,
                      color: AppColor.kGrayscale40,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),
          if (p.finPromotion != null && p.prixBarre != null) ...[
            const SizedBox(height: 12),
            CompteARebours(fin: p.finPromotion!, onTermine: _charger),
          ],
          // Options à choisir : une ligne de puces par option.
          for (final option in p.options) ...[
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: option.libelle,
                children: [
                  if (_choix[option.libelle] != null)
                    TextSpan(
                      text: '  ${_choix[option.libelle]}',
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontWeight: FontWeight.w500,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                ],
              ),
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _choixManquant && !_choix.containsKey(option.libelle)
                    ? AppColor.kErreur
                    : AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in option.valeurs)
                  _puceOption(
                    v,
                    _choix[option.libelle] == v,
                    () => setState(() => _choix[option.libelle] = v),
                  ),
              ],
            ),
          ],
          if (p.disponible && !p.enRupture) ...[
            const SizedBox(height: 18),
            _selecteurQuantite(),
          ],
          if (p.categorie != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.kPrimaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                p.categorie!.nom,
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _puceOption(String texte, bool choisie, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 46),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: choisie ? AppColor.kPrimary : AppColor.kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: choisie ? AppColor.kPrimary : AppColor.kLine,
            width: 1.3,
          ),
        ),
        child: Text(
          texte,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kPolice,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: choisie ? AppColor.kWhite : AppColor.kGrayscaleDark100,
          ),
        ),
      ),
    );
  }

  Widget _selecteurQuantite() {
    Widget bouton(IconData icone, VoidCallback? action) => Material(
      color: action == null ? AppColor.kLine : AppColor.kPrimaryLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: action,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icone,
            size: 18,
            color: action == null ? AppColor.kGrayscale30 : AppColor.kPrimary,
          ),
        ),
      ),
    );

    return Row(
      children: [
        const Text(
          'Quantité',
          style: TextStyle(
            fontFamily: kPolice,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
        const SizedBox(width: 10),
        bouton(
          Icons.remove_rounded,
          _quantite > 1 ? () => setState(() => _quantite--) : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$_quantite',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        bouton(
          Icons.add_rounded,
          _quantite < _quantiteMax ? () => setState(() => _quantite++) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formaterPrix(p.prixPaye * _quantite),
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.kPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blocCaracteristiques() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: decorationCarte(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Caractéristiques', style: titreSection(15.5)),
          const SizedBox(height: 10),
          for (final c in p.caracteristiques)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(c.libelle, style: texteDiscret(13))),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      c.valeur,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _blocDescription() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: decorationCarte(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description', style: titreSection(15.5)),
          const SizedBox(height: 10),
          Text(
            p.description,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 13.5,
              color: AppColor.kGrayscale40,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// La boutique qui vend : logo, nom et badge, ville, et « Visiter ».
  Widget _blocBoutique() {
    final b = p.boutique!;
    void ouvrir() => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoutiquePubliquePage(boutiqueId: b.id, apercu: b),
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: decorationCarte(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDim.rayonCarte),
          onTap: ouvrir,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: (b.logo ?? '').isNotEmpty
                        ? ImageReseau(
                            b.logo!,
                            largeurServeur: 200,
                            fit: BoxFit.cover,
                            repli: const LogoBoutiqueParDefaut(),
                          )
                        : const LogoBoutiqueParDefaut(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vendu par',
                        style: TextStyle(
                          fontFamily: kPolice,
                          fontSize: 11.5,
                          color: AppColor.kGrayscale40,
                        ),
                      ),
                      // Le nom entier, sur deux lignes au besoin, le badge
                      // à sa suite.
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: b.nom),
                            if (b.verifiee)
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: AppColor.kSecondary,
                                    semanticLabel: 'Boutique vérifiée',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: AppColor.kGrayscaleDark100,
                        ),
                      ),
                      if (b.localisation.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColor.kGrayscale40,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                b.localisation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: texteDiscret(12),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: AppColor.kPrimaryLight,
                    borderRadius: BorderRadius.circular(AppDim.rayonPastille),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Visiter',
                        style: TextStyle(
                          fontFamily: kPolice,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColor.kPrimary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColor.kPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blocSimilaires() {
    if (_similairesEnCours) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColor.kPrimary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    if (_similaires.isEmpty) return const SizedBox.shrink();
    const largeur = 158.0;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: EnteteSection(
              'Produits similaires',
              sousTitre: p.categorie?.nom,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: largeur / ratioCarteProduit,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _similaires.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: largeur,
                child: ProduitCard(produit: _similaires[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barreAchat() {
    final actif = p.disponible && !p.enRupture;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Tooltip(
                message: 'Écrire au vendeur sur WhatsApp',
                child: InkWell(
                  onTap: _whatsapp,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColor.kWhatsapp,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      color: AppColor.kWhite,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: actif ? _ajouter : null,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    label: Text(
                      !p.disponible
                          ? 'Indisponible'
                          : p.enRupture
                          ? 'Rupture de stock'
                          : 'Ajouter au panier',
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.kPrimary,
                      foregroundColor: AppColor.kWhite,
                      disabledBackgroundColor: AppColor.kLine,
                      disabledForegroundColor: AppColor.kGrayscale30,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille blanche autour d'un bouton posé sur la photo.
class _Pastille extends StatelessWidget {
  final Widget child;
  const _Pastille({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColor.kWhite.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
