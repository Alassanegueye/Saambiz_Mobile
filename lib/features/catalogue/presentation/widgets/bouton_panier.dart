import 'package:flutter/material.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';
import '../../../commande/data/services/panier_service.dart';
import '../../../commande/presentation/pages/panier_page.dart';

/// Icône panier avec le nombre d'articles, pour les barres du haut.
class BoutonPanier extends StatelessWidget {
  final Color couleur;
  const BoutonPanier({super.key, this.couleur = AppColor.kPrimary});

  @override
  Widget build(BuildContext context) {
    final panier = sl<PanierService>();
    return IconButton(
      tooltip: 'Mon panier',
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PanierPage())),
      icon: ListenableBuilder(
        listenable: panier,
        builder: (_, __) {
          final n = panier.nombreArticles;
          return Badge(
            isLabelVisible: n > 0,
            backgroundColor: AppColor.kErreur,
            label: Text(n > 99 ? '99+' : '$n'),
            child: Icon(Icons.shopping_cart_outlined, color: couleur, size: 24),
          );
        },
      ),
    );
  }
}
