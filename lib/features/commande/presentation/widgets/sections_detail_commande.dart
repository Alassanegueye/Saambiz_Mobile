import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/utils/texte.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../core/widgets/image_produit.dart';
import '../../../../core/widgets/image_reseau.dart';
import '../../../../core/widgets/logo_boutique.dart';
import '../../../../core/widgets/messages.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import '../../../catalogue/data/produit_catalogue.dart';
import '../../../catalogue/presentation/pages/boutique_publique_page.dart';
import '../../../catalogue/presentation/pages/produit_detail_page.dart';
import '../../../messagerie/presentation/pages/chat_page.dart';
import '../../data/models/commande_model.dart';
import 'commande_card.dart' show couleurStatutCommande, montantFcfa;

/// Sections de la fiche commande : détails de la commande, articles,
/// boutique et vendeur. Chacune est une carte blanche à titre, comme les
/// autres blocs de la fiche.

/// « 15 novembre 2026 à 10 h 42 ».
String dateEtHeure(DateTime date) {
  final l = date.toLocal();
  final minutes = l.minute.toString().padLeft(2, '0');
  return '${dateLongue(l)} à ${l.hour} h $minutes';
}

/// Carte blanche d'une section, avec son icône et son titre ; [action]
/// s'aligne à droite du titre.
class CarteSectionCommande extends StatelessWidget {
  final String titre;
  final IconData icone;
  final Widget? action;
  final Widget child;
  const CarteSectionCommande({
    super.key,
    required this.titre,
    required this.icone,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColor.kPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 17, color: AppColor.kPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titre,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Une information d'une section : libellé au-dessus, valeur dessous, et
/// éventuellement un bouton au bout (copier…).
class LigneInfoCommande extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;
  final Color? couleurValeur;
  final Widget? fin;
  const LigneInfoCommande({
    super.key,
    required this.icone,
    required this.libelle,
    required this.valeur,
    this.couleurValeur,
    this.fin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icone, size: 19, color: AppColor.kPrimaryMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libelle,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12.5,
                    color: AppColor.kGrayscale40,
                  ),
                ),
                Text(
                  valeur,
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: couleurValeur ?? AppColor.kGrayscaleDark100,
                  ),
                ),
              ],
            ),
          ),
          ?fin,
        ],
      ),
    );
  }
}

// ─── Détails de la commande ────────────────────────────────────────────────

/// Le code (à copier pour le donner au vendeur ou au service client), la
/// date et l'heure, le statut en français, la dernière mise à jour.
class CarteDetailsCommande extends StatelessWidget {
  final CommandeModel commande;
  const CarteDetailsCommande({super.key, required this.commande});

  @override
  Widget build(BuildContext context) {
    final cree = commande.createdAt;
    final maj = commande.updatedAt;
    // Une mise à jour dans la minute qui suit la commande n'en est pas une.
    final majUtile =
        maj != null &&
        (cree == null || maj.difference(cree).inMinutes.abs() >= 1);
    return CarteSectionCommande(
      titre: 'Détails de la commande',
      icone: Icons.receipt_long_outlined,
      child: Column(
        children: [
          LigneInfoCommande(
            icone: Icons.tag_rounded,
            libelle: 'Code de commande',
            valeur: commande.referenceCommande,
            fin: IconButton(
              tooltip: 'Copier le code',
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: commande.referenceCommande),
                );
                if (context.mounted) afficherSucces(context, 'Code copié.');
              },
              icon: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppColor.kPrimary,
              ),
            ),
          ),
          if (cree != null)
            LigneInfoCommande(
              icone: Icons.event_outlined,
              libelle: 'Passée le',
              valeur: dateEtHeure(cree),
            ),
          LigneInfoCommande(
            icone: Icons.flag_outlined,
            libelle: 'Statut',
            valeur: kStatutCommandeLabels[commande.statut] ?? commande.statut,
            couleurValeur: couleurStatutCommande(commande.statut),
          ),
          if (majUtile)
            LigneInfoCommande(
              icone: Icons.update_rounded,
              libelle: 'Dernière mise à jour',
              valeur: dateEtHeure(maj),
            ),
        ],
      ),
    );
  }
}

// ─── Articles ──────────────────────────────────────────────────────────────

/// Chaque article (photo, nom, options, prix unitaire × quantité, sous-total,
/// et la fiche du produit au toucher), puis le détail du montant.
class CarteArticlesCommande extends StatelessWidget {
  final CommandeModel commande;
  const CarteArticlesCommande({super.key, required this.commande});

  @override
  Widget build(BuildContext context) {
    final nb = commande.lignes.fold<int>(0, (n, l) => n + l.quantite);
    final retrait = commande.modeLivraison == 'retrait';
    return CarteSectionCommande(
      titre: '$nb article${nb > 1 ? 's' : ''}',
      icone: Icons.shopping_bag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < commande.lignes.length; i++) ...[
            if (i > 0) const Divider(height: 20, color: AppColor.kLine),
            _LigneArticle(ligne: commande.lignes[i]),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.kSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _Montant(
                  libelle: 'Sous-total',
                  valeur: montantFcfa(commande.montantProduits),
                ),
                _Montant(
                  libelle: 'Livraison',
                  valeur: retrait
                      ? 'Retrait en boutique'
                      : commande.fraisLivraison > 0
                      ? montantFcfa(commande.fraisLivraison)
                      : 'Offerte',
                ),
                const Divider(height: 16, color: AppColor.kLine),
                _Montant(
                  libelle: 'Total',
                  valeur: montantFcfa(commande.montantTotal),
                  fort: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Montant extends StatelessWidget {
  final String libelle;
  final String valeur;
  final bool fort;
  const _Montant({
    required this.libelle,
    required this.valeur,
    this.fort = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            libelle,
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: fort ? 15 : 13.5,
              fontWeight: fort ? FontWeight.w700 : FontWeight.w400,
              color: fort ? AppColor.kGrayscaleDark100 : AppColor.kGrayscale40,
            ),
          ),
          Text(
            valeur,
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: fort ? 16.5 : 13.5,
              fontWeight: fort ? FontWeight.w800 : FontWeight.w600,
              color: fort ? AppColor.kPrimary : AppColor.kGrayscaleDark100,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un article ; le toucher ouvre la fiche du produit, relue au serveur.
class _LigneArticle extends StatefulWidget {
  final LigneCommandeModel ligne;
  const _LigneArticle({required this.ligne});

  @override
  State<_LigneArticle> createState() => _LigneArticleState();
}

class _LigneArticleState extends State<_LigneArticle> {
  bool _ouverture = false;

  Future<void> _ouvrirProduit() async {
    final id = widget.ligne.produitId;
    if (id == null || id.isEmpty || _ouverture) return;
    setState(() => _ouverture = true);
    try {
      final detail = await CatalogueRemoteDataSource(sl<Dio>()).detail(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProduitDetailPage(produit: detail.produit),
        ),
      );
    } catch (_) {
      if (mounted) {
        afficherInfo(
          context,
          'Ce produit n’est plus en vente : sa fiche n’est plus disponible.',
        );
      }
    } finally {
      if (mounted) setState(() => _ouverture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.ligne;
    final ouvrable = (l.produitId ?? '').isNotEmpty;
    final image = l.imageProduit;
    return InkWell(
      onTap: ouvrable ? _ouvrirProduit : null,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImageProduit(image, cote: 64, largeurServeur: 200),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.nomProduit,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                // Taille, couleur, parfum… choisis par le client.
                if (l.options.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final o in l.options.entries)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.kPrimaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${o.key} : ${o.value}',
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColor.kPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${montantFcfa(l.prixUnitaire)} × ${l.quantite}',
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12.5,
                    color: AppColor.kGrayscale40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                montantFcfa(l.sousTotal),
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
              if (ouvrable) ...[
                const SizedBox(height: 10),
                _ouverture
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Voir',
                            style: TextStyle(
                              fontFamily: kPolice,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColor.kPrimaryMedium,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColor.kPrimaryMedium,
                          ),
                        ],
                      ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Boutique et vendeur ───────────────────────────────────────────────────

/// La boutique (logo, nom, badge, catégorie, note, ville), son vendeur, et
/// les moyens de les joindre : ouvrir la boutique, appeler, WhatsApp,
/// écrire. La fiche publique de la boutique est relue au serveur pour ce
/// que la commande ne porte pas ; en attendant, ou sans elle, la carte
/// montre ce que la commande sait.
class CarteBoutiqueCommande extends StatefulWidget {
  final String? boutiqueId;
  final String? boutiqueNom;
  final String? boutiqueLogo;
  final String vendeurId;
  final String? vendeurNom;
  final String? vendeurTelephone;

  /// Fiche publique d'une boutique ; remplaçable dans les tests.
  final Future<Map<String, dynamic>> Function(String id)? chargerBoutique;

  const CarteBoutiqueCommande({
    super.key,
    required this.boutiqueId,
    required this.boutiqueNom,
    required this.boutiqueLogo,
    required this.vendeurId,
    required this.vendeurNom,
    required this.vendeurTelephone,
    this.chargerBoutique,
  });

  @override
  State<CarteBoutiqueCommande> createState() => _CarteBoutiqueCommandeState();
}

class _CarteBoutiqueCommandeState extends State<CarteBoutiqueCommande> {
  Map<String, dynamic>? _fiche;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final id = widget.boutiqueId;
    if (id == null || id.isEmpty) return;
    try {
      final charger =
          widget.chargerBoutique ??
          CatalogueRemoteDataSource(sl<Dio>()).boutique;
      final fiche = await charger(id);
      if (mounted) setState(() => _fiche = fiche);
    } catch (_) {
      // Ce que la commande sait reste affiché.
    }
  }

  String? _texte(Object? v) {
    final t = (v ?? '').toString().trim();
    return t.isEmpty ? null : t;
  }

  void _ouvrirBoutique(String id, String nom, String? logo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoutiquePubliquePage(
          boutiqueId: id,
          apercu: BoutiqueResume(id: id, nom: nom, logo: logo),
        ),
      ),
    );
  }

  Future<void> _whatsapp(String telephone) async {
    var numero = telephone.replaceAll(RegExp(r'\D'), '');
    if (numero.length == 9) numero = '221$numero';
    if (!await UrlExterne.lancer('https://wa.me/$numero') && mounted) {
      afficherErreur(
        context,
        'WhatsApp n’est pas disponible sur cet appareil.',
      );
    }
  }

  Future<void> _appeler(String telephone) async {
    final numero = telephone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!await UrlExterne.lancer('tel:$numero') && mounted) {
      afficherErreur(context, 'Appel impossible depuis cet appareil.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _fiche;
    final id = widget.boutiqueId;
    final nom = _texte(f?['nom']) ?? _texte(widget.boutiqueNom);
    final logo = _texte(f?['logo']) ?? _texte(widget.boutiqueLogo);
    final verifiee = f?['verifiee'] == true;
    final categorie = _texte(f?['categorie']) ?? _texte(f?['slogan']);
    final ville = _texte(f?['localisation']);
    final note = f?['note'];
    final nombreAvis = f?['nombreAvis'] is num
        ? (f!['nombreAvis'] as num).toInt()
        : 0;
    final vendeur = _texte(widget.vendeurNom);
    final telephone =
        _texte(widget.vendeurTelephone) ?? _texte(f?['telephone']);
    final whatsapp = _texte(f?['whatsapp']) ?? telephone;

    final actions = <Widget>[
      if (id != null && nom != null)
        _Action(
          icone: Icons.storefront_rounded,
          libelle: 'Boutique',
          onTap: () => _ouvrirBoutique(id, nom, logo),
        ),
      if (telephone != null)
        _Action(
          icone: Icons.phone_rounded,
          libelle: 'Appeler',
          onTap: () => _appeler(telephone),
        ),
      if (whatsapp != null)
        _Action(
          icone: Icons.chat_rounded,
          libelle: 'WhatsApp',
          couleur: AppColor.kWhatsapp,
          onTap: () => _whatsapp(whatsapp),
        ),
      if (widget.vendeurId.isNotEmpty)
        _Action(
          icone: Icons.mail_outline_rounded,
          libelle: 'Message',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatPage(
                interlocuteurId: widget.vendeurId,
                interlocuteurNom: nom ?? vendeur ?? 'Vendeur',
              ),
            ),
          ),
        ),
    ];

    return CarteSectionCommande(
      titre: nom != null ? 'Boutique et vendeur' : 'Vendeur',
      icone: Icons.storefront_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (nom != null) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: logo != null
                        ? ImageReseau(
                            logo,
                            largeurServeur: 160,
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: kPolice,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColor.kGrayscaleDark100,
                              ),
                            ),
                          ),
                          if (verifiee) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColor.kSecondary,
                              semanticLabel: 'Boutique vérifiée',
                            ),
                          ],
                        ],
                      ),
                      if (categorie != null)
                        Text(
                          categorie,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 12.5,
                            color: AppColor.kGrayscale40,
                          ),
                        ),
                      if ((note is num && nombreAvis > 0) || ville != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (note is num && nombreAvis > 0) ...[
                              const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: AppColor.kSecondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${note.toStringAsFixed(1).replaceAll('.', ',')} ($nombreAvis avis)',
                                style: const TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.kGrayscaleDark100,
                                ),
                              ),
                              if (ville != null) const SizedBox(width: 10),
                            ],
                            if (ville != null) ...[
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColor.kGrayscale40,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  ville,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 12,
                                    color: AppColor.kGrayscale40,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColor.kLine),
          ],
          // Le vendeur : la personne qui tient la boutique.
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColor.kPrimaryLight,
                child: Text(
                  vendeur == null ? '?' : initialesDe(vendeur),
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vendeur',
                      style: TextStyle(
                        fontFamily: kPolice,
                        fontSize: 12,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                    Text(
                      vendeur ?? 'Non renseigné',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    if (telephone != null)
                      Text(
                        telephone,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 12.5,
                          color: AppColor.kGrayscale40,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Un moyen de joindre la boutique : icône dans un rond, libellé dessous.
class _Action extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final Color couleur;
  final VoidCallback onTap;
  const _Action({
    required this.icone,
    required this.libelle,
    required this.onTap,
    this.couleur = AppColor.kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 18, color: couleur),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  libelle,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscale80,
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
