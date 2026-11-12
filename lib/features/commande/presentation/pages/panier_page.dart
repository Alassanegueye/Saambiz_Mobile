import 'package:saambiz/core/widgets/messages.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/police.dart';
import '../../data/models/panier_item.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/features/commande/presentation/widgets/commande_card.dart'
    show montantFcfa;
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/theme/app_color.dart';
import '../../data/services/panier_service.dart';
import '../../../../core/widgets/page_vendeur.dart';

class _C {
  static const green = AppColor.kPrimary;
  static const black = AppColor.kGrayscaleDark100;
  static const white = AppColor.kWhite;
  static const bg = AppColor.kBackground;
  static const sub = AppColor.kGrayscale40;
  static const border = AppColor.kLine;
}

/// Passer commande demande un compte : un invité garde son panier et
/// se connecte (ou s'inscrit) en un geste.
Future<void> _commander(BuildContext context) async {
  final connecte = await sl<TokenService>().isAuthenticated;
  if (!context.mounted) return;
  if (connecte) {
    Navigator.of(context).pushNamed(AppRouter.checkoutRoute);
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _C.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_open_rounded, size: 40, color: _C.green),
            const SizedBox(height: 12),
            const Text(
              'Connectez-vous pour commander',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Votre panier est conservé. Il vous suffit d\'un compte pour valider et suivre la livraison.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: _C.sub),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(AppRouter.loginRoute);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _C.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed(AppRouter.clientSignupRoute);
              },
              child: const Text(
                'Créer un compte',
                style: TextStyle(fontWeight: FontWeight.w700, color: _C.green),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PanierPage extends StatelessWidget {
  const PanierPage({super.key});

  @override
  Widget build(BuildContext context) {
    final panier = sl<PanierService>();

    return ScaffoldMarine(
      backgroundColor: _C.bg,
      appBar: AppBar(title: const Text('Mon panier')),
      body: ListenableBuilder(
        listenable: panier,
        builder: (context, _) {
          if (panier.estVide) return const _PanierVide();
          final groupes = panier.parBoutique;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    // Une commande = une boutique : le client coche les
                    // produits d'une seule boutique avant de commander.
                    const _Astuce(
                      'Cochez les produits à commander. Une commande '
                      'regroupe les produits d\'une seule boutique.',
                    ),
                    const SizedBox(height: 14),
                    for (final entree in groupes.entries) ...[
                      _CarteBoutique(
                        nom: entree.value.first.vendeurNom,
                        nombre: entree.value.fold(
                          0,
                          (n, it) => n + it.quantite,
                        ),
                        coche: panier.boutiqueEntierementSelectionnee(
                          entree.key,
                        ),
                        onCocher: () {
                          if (panier.basculerBoutique(entree.key)) {
                            _prevenirChangement(context);
                          }
                        },
                        lignes: [
                          for (final item in entree.value)
                            _LignePanier(
                              item: item,
                              coche: panier.estSelectionne(item.cle),
                              onCocher: () {
                                if (panier.basculer(item.cle)) {
                                  _prevenirChangement(context);
                                }
                              },
                              onMoins: () => panier.changerQuantite(
                                item.cle,
                                item.quantite - 1,
                              ),
                              onPlus: () => panier.changerQuantite(
                                item.cle,
                                item.quantite + 1,
                              ),
                              onRetirer: () async {
                                await panier.retirer(item.cle);
                                if (context.mounted) {
                                  afficherSucces(
                                    context,
                                    '« ${item.nom} » a été retiré du panier.',
                                    titre: 'Produit retiré',
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
              _BarreTotal(
                total: panier.totalSelection,
                nombre: panier.nombreSelectionnes,
                onCommander: panier.selectionVide
                    ? null
                    : () => _commander(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Explique pourquoi la sélection vient de changer de boutique.
void _prevenirChangement(BuildContext context) {
  afficherInfo(
    context,
    'Une commande regroupe une seule boutique : la sélection a été '
    'remplacée.',
  );
}

/// Rappel discret en tête de liste.
class _Astuce extends StatelessWidget {
  final String texte;
  const _Astuce(this.texte);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.kPrimaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: _C.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 12.5,
                height: 1.4,
                color: _C.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Case ronde : cochée, elle se remplit de la couleur principale.
class _Coche extends StatelessWidget {
  final bool coche;
  final VoidCallback onTap;
  final String libelle;
  const _Coche({
    required this.coche,
    required this.onTap,
    required this.libelle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: coche,
      label: libelle,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: coche ? _C.green : _C.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: coche ? _C.green : const Color(0xFFC5CDDC),
                width: 1.8,
              ),
            ),
            child: coche
                ? const Icon(Icons.check_rounded, size: 16, color: _C.white)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Une boutique et ses produits, dans une même carte.
class _CarteBoutique extends StatelessWidget {
  final String nom;
  final int nombre;
  final bool coche;
  final VoidCallback onCocher;
  final List<Widget> lignes;
  const _CarteBoutique({
    required this.nom,
    required this.nombre,
    required this.coche,
    required this.onCocher,
    required this.lignes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.green.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
            child: Row(
              children: [
                _Coche(
                  coche: coche,
                  onTap: onCocher,
                  libelle: 'Tout cocher pour cette boutique',
                ),
                const SizedBox(width: 4),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColor.kPrimaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 17,
                    color: _C.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nom.trim().isEmpty ? 'Boutique' : nom.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: _C.black,
                    ),
                  ),
                ),
                Text(
                  nombre > 1 ? '$nombre articles' : '1 article',
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12.5,
                    color: _C.sub,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < lignes.length; i++) ...[
            const Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: _C.border,
            ),
            lignes[i],
          ],
        ],
      ),
    );
  }
}

/// Un produit du panier : case, photo, nom, options, prix, quantité.
class _LignePanier extends StatelessWidget {
  final PanierItem item;
  final bool coche;
  final VoidCallback onCocher;
  final VoidCallback onMoins;
  final VoidCallback onPlus;
  final VoidCallback onRetirer;
  const _LignePanier({
    required this.item,
    required this.coche,
    required this.onCocher,
    required this.onMoins,
    required this.onPlus,
    required this.onRetirer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: _Coche(
              coche: coche,
              onTap: onCocher,
              libelle: 'Commander ${item.nom}',
            ),
          ),
          const SizedBox(width: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: item.image.isNotEmpty
                ? ImageReseau(
                    item.image,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    repli: const _ImgFallback(),
                  )
                : const _ImgFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.nom,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: _C.black,
                        ),
                      ),
                    ),
                    InkResponse(
                      onTap: onRetirer,
                      radius: 20,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6, bottom: 4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Color(0xFF9AA3B5),
                          semanticLabel: 'Retirer du panier',
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.options.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.libelleOptions,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 12,
                      color: _C.sub,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        montantFcfa(item.prix),
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _C.green,
                        ),
                      ),
                    ),
                    _QtyStepper(
                      quantite: item.quantite,
                      onMoins: onMoins,
                      onPlus: onPlus,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quantité en pilule : − 1 +.
class _QtyStepper extends StatelessWidget {
  final int quantite;
  final VoidCallback onMoins;
  final VoidCallback onPlus;
  const _QtyStepper({
    required this.quantite,
    required this.onMoins,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _bouton(Icons.remove_rounded, onMoins, 'Diminuer'),
          SizedBox(
            width: 26,
            child: Text(
              '$quantite',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kPolice,
                fontWeight: FontWeight.w800,
                color: _C.black,
              ),
            ),
          ),
          _bouton(Icons.add_rounded, onPlus, 'Augmenter'),
        ],
      ),
    );
  }

  Widget _bouton(IconData icone, VoidCallback onTap, String libelle) =>
      InkResponse(
        onTap: onTap,
        radius: 18,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icone, size: 17, color: _C.black, semanticLabel: libelle),
        ),
      );
}

class _BarreTotal extends StatelessWidget {
  final double total;
  final int nombre;

  /// Nul tant qu'aucun produit n'est coché : le bouton est grisé.
  final VoidCallback? onCommander;
  const _BarreTotal({
    required this.total,
    required this.nombre,
    required this.onCommander,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  nombre == 0
                      ? 'Aucun produit coché'
                      : 'Total · $nombre article${nombre > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13.5,
                    color: _C.sub,
                  ),
                ),
                const Spacer(),
                Text(
                  montantFcfa(total),
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: _C.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Hors frais de livraison',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 11.5,
                  color: _C.sub,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onCommander,
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: Text(nombre == 0 ? 'Cochez un produit' : 'Commander'),
                style: FilledButton.styleFrom(
                  backgroundColor: _C.green,
                  foregroundColor: _C.white,
                  disabledBackgroundColor: const Color(0xFFE3E8F0),
                  disabledForegroundColor: const Color(0xFF8A93A6),
                  textStyle: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanierVide extends StatelessWidget {
  const _PanierVide();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColor.kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 44,
                color: _C.green,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Votre panier est vide',
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _C.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajoutez des produits depuis les boutiques : ils vous attendront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 13.5,
                height: 1.45,
                color: _C.sub,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: _C.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Continuer mes achats',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();
  @override
  Widget build(BuildContext context) => Container(
    width: 76,
    height: 76,
    color: _C.bg,
    child: const Icon(Icons.shopping_bag_outlined, color: _C.sub),
  );
}
