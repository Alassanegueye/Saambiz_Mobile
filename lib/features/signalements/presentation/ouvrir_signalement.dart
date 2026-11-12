import 'package:saambiz/core/widgets/messages.dart';
import 'package:flutter/material.dart';

import '../../../core/services/token_service.dart';
import '../../../injection_container.dart';
import 'pages/signaler_form_page.dart';

/// Porte d'entrée unique vers le signalement d'un contenu.
///
/// Le formulaire, le bloc et la route `POST /signalements` existaient déjà,
/// complets et testés — mais aucun écran ne les ouvrait. L'application
/// affichait même « Mes signalements » dans le profil, une liste condamnée à
/// rester vide faute de pouvoir en créer un.
///
/// Ce n'est pas qu'un manque de confort : le règlement de Google Play exige
/// un moyen de signaler, dans l'application, pour toute application qui
/// héberge du contenu publié par ses utilisateurs — ce que SaamBiz fait, avec
/// les fiches produits, les boutiques, les avis et la messagerie.
///
/// L'API refuse un signalement anonyme (`authMiddleware`), d'où le contrôle
/// ici : mieux vaut une invitation à se connecter qu'un 401 silencieux au
/// moment de l'envoi, une fois le formulaire rempli.
Future<void> ouvrirSignalement(
  BuildContext context, {
  required String type, // 'produit' | 'boutique'
  required String cibleId,
}) async {
  assert(type == 'produit' || type == 'boutique');

  final connecte = await sl<TokenService>().isAuthenticated;
  if (!context.mounted) return;

  if (!connecte) {
    afficherInfo(context, 'Connectez-vous pour signaler un contenu.');
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SignalerFormPage(type: type, cibleId: cibleId),
    ),
  );
}

/// Le bouton « ⋮ » des barres de navigation, avec l'entrée « Signaler ».
///
/// Un menu plutôt qu'une icône drapeau en clair : signaler reste une action
/// rare, et une icône permanente à côté du panier inquiète plus qu'elle ne
/// rassure. Google demande que le moyen existe et soit accessible, pas qu'il
/// soit mis en avant.
class MenuSignaler extends StatelessWidget {
  final String type;
  final String cibleId;

  const MenuSignaler({super.key, required this.type, required this.cibleId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Plus d\'options',
      onSelected: (_) =>
          ouvrirSignalement(context, type: type, cibleId: cibleId),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'signaler',
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, size: 20),
              const SizedBox(width: 12),
              Text(
                type == 'boutique'
                    ? 'Signaler cette boutique'
                    : 'Signaler ce produit',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
