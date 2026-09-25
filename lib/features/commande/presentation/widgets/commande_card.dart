import 'package:flutter/material.dart';
import '../../data/models/commande_model.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
}

Color couleurStatutCommande(String statut) {
  switch (statut) {
    case 'livree':
      return _C.green;
    case 'annulee':
      return Colors.red;
    case 'en_livraison':
    case 'prete':
      return const Color(0xFFFF9800);
    default:
      return _C.sub;
  }
}

class CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  final VoidCallback onTap;
  const CommandeCard({super.key, required this.commande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatutCommande(commande.statut);
    final nbArticles =
        commande.lignes.fold<int>(0, (s, l) => s + l.quantite);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(commande.referenceCommande,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: _C.black)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    kStatutCommandeLabels[commande.statut] ?? commande.statut,
                    style: TextStyle(
                        color: couleur,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$nbArticles article(s)',
                style: const TextStyle(color: _C.sub, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${commande.montantTotal.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                        color: _C.green, fontWeight: FontWeight.w800)),
                Text(
                  commande.statutPaiement == 'paye'
                      ? 'Payé'
                      : commande.statutPaiement == 'rembourse'
                          ? 'Remboursé'
                          : 'Non payé',
                  style: TextStyle(
                      fontSize: 12,
                      color: commande.statutPaiement == 'paye'
                          ? _C.green
                          : _C.sub),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
