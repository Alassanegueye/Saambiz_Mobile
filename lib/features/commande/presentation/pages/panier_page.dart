import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/theme/app_color.dart';
import '../../data/services/panier_service.dart';
import 'package:saambiz/core/utils/image_url.dart';

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
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_open_rounded, size: 40, color: _C.green),
            const SizedBox(height: 12),
            const Text('Connectez-vous pour commander',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.black)),
            const SizedBox(height: 6),
            const Text('Votre panier est conservé. Il vous suffit d\'un compte pour valider et suivre la livraison.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.4, color: _C.sub)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed(AppRouter.clientSignupRoute);
              },
              child: const Text('Créer un compte', style: TextStyle(fontWeight: FontWeight.w700, color: _C.green)),
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

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Mon panier'),
      ),
      body: ListenableBuilder(
        listenable: panier,
        builder: (context, _) {
          if (panier.estVide) {
            return const _PanierVide();
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: panier.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = panier.items[i];
                    return Container(
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
                                ? CachedNetworkImage(
                                    imageUrl: imageOptimisee(item.image),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const _ImgFallback(),
                                  )
                                : const _ImgFallback(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.nom,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _C.black)),
                                if (item.options.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(item.libelleOptions,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12, color: _C.sub)),
                                  ),
                                const SizedBox(height: 4),
                                Text('${item.prix.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                        color: _C.green,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          _QtyStepper(
                            quantite: item.quantite,
                            onMoins: () => panier.changerQuantite(
                                item.cle, item.quantite - 1),
                            onPlus: () => panier.changerQuantite(
                                item.cle, item.quantite + 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _BarreTotal(
                total: panier.total,
                onCommander: () => _commander(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantite;
  final VoidCallback onMoins;
  final VoidCallback onPlus;
  const _QtyStepper(
      {required this.quantite, required this.onMoins, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _circle(Icons.remove, onMoins),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$quantite',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _C.black)),
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
  final VoidCallback onCommander;
  const _BarreTotal({required this.total, required this.onCommander});

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
                  const Text('Total', style: TextStyle(color: _C.sub)),
                  Text('${total.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _C.black)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onCommander,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: _C.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Commander',
                  style: TextStyle(fontWeight: FontWeight.w700)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.shopping_cart_outlined, size: 64, color: _C.sub),
          SizedBox(height: 12),
          Text('Votre panier est vide',
              style: TextStyle(color: _C.sub, fontSize: 16)),
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
