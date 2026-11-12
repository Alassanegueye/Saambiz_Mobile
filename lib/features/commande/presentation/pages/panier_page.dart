import 'package:flutter/material.dart';
import '../../../../core/widgets/degrade_fond.dart';
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
      body: FondDegradeSubtil(
        child: ListenableBuilder(
          listenable: panier,
          builder: (context, _) {
            if (panier.estVide) {
              return const _PanierVide();
            }
            final groupes = panier.parBoutique;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Une commande = une boutique : le client coche les
                      // produits d'une seule boutique avant de commander.
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Cochez les produits à commander. Une commande '
                          'regroupe les produits d\'une seule boutique.',
                          style: TextStyle(fontSize: 13, color: _C.sub),
                        ),
                      ),
                      for (final entree in groupes.entries) ...[
                        _EnteteBoutique(
                          nom: entree.value.first.vendeurNom,
                          coche: panier.boutiqueEntierementSelectionnee(
                            entree.key,
                          ),
                          onChanged: () {
                            if (panier.basculerBoutique(entree.key)) {
                              _prevenirChangement(context);
                            }
                          },
                        ),
                        for (final item in entree.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: panier.estSelectionne(item.cle),
                                  activeColor: _C.green,
                                  onChanged: (_) {
                                    if (panier.basculer(item.cle)) {
                                      _prevenirChangement(context);
                                    }
                                  },
                                ),
                                Expanded(
                                  child: Container(
                                decoration: BoxDecoration(
                                  color: _C.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _C.border),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: item.image.isNotEmpty
                                          ? ImageReseau(
                                              item.image,
                                              width: 64,
                                              height: 64,
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
                                          Text(
                                            item.nom,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: _C.black,
                                            ),
                                          ),
                                          if (item.options.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 3),
                                              child: Text(
                                                item.libelleOptions,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _C.sub,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            montantFcfa(item.prix),
                                            style: const TextStyle(
                                              color: _C.green,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // La corbeille au-dessus des quantités : retire
                                    // l'article d'un geste, sans descendre à zéro.
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          tooltip: 'Retirer du panier',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => panier.retirer(item.cle),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 21,
                                            color: AppColor.kErreur,
                                          ),
                                        ),
                                        _QtyStepper(
                                          quantite: item.quantite,
                                          onMoins: () => panier.changerQuantite(
                                            item.cle,
                                            item.quantite - 1,
                                          ),
                                          onPlus: () => panier.changerQuantite(
                                            item.cle,
                                            item.quantite + 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
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
      ),
    );
  }
}

/// Explique pourquoi la sélection vient de changer de boutique.
void _prevenirChangement(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'Une commande regroupe une seule boutique : la sélection a été '
          'remplacée.',
        ),
      ),
    );
}

/// Nom d'une boutique au-dessus de ses produits, avec la case qui les coche
/// tous.
class _EnteteBoutique extends StatelessWidget {
  final String nom;
  final bool coche;
  final VoidCallback onChanged;
  const _EnteteBoutique({
    required this.nom,
    required this.coche,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Checkbox(
            value: coche,
            activeColor: _C.green,
            onChanged: (_) => onChanged(),
          ),
          const Icon(Icons.storefront_rounded, size: 20, color: _C.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nom.trim().isEmpty ? 'Boutique' : nom.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: _C.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Row(
      children: [
        _circle(Icons.remove, onMoins),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '$quantite',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _C.black,
            ),
          ),
        ),
        _circle(Icons.add, onPlus),
      ],
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: _C.bg,
        shape: BoxShape.circle,
        border: Border.all(color: _C.border),
      ),
      child: Icon(icon, size: 16, color: _C.black),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: _C.white,
        boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 12)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre == 0
                        ? 'Aucun produit coché'
                        : 'Total ($nombre article${nombre > 1 ? 's' : ''})',
                    style: const TextStyle(color: _C.sub),
                  ),
                  Text(
                    montantFcfa(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _C.black,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onCommander,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: _C.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Commander',
                style: TextStyle(fontWeight: FontWeight.w700),
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: _C.sub),
          SizedBox(height: 12),
          Text(
            'Votre panier est vide',
            style: TextStyle(color: _C.sub, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();
  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    color: _C.bg,
    child: const Icon(Icons.image_not_supported_outlined, color: _C.sub),
  );
}
