import 'dart:async';

import 'package:flutter/material.dart';

import '../../injection_container.dart';
import '../services/socket_service.dart';

/// Relit les données dès qu'une commande change d'état, où que le changement
/// ait eu lieu.
///
/// Le rafraîchissement au retour d'onglet et au retour de la fiche couvre déjà
/// le cas d'un vendeur seul sur son téléphone. Il ne couvre pas celui-ci :
/// l'acheteur paie, le vendeur accepte depuis un autre appareil, le site de
/// la boutique enregistre une commande — et l'écran affiché pendant ce temps
/// reste sur ce qu'il a lu en arrivant. Le serveur diffuse
/// `commande:statut` aux deux parties ; il suffit de l'écouter.
///
/// À placer SOUS le `BlocProvider` dont dépend [onChange].
class EcouteurCommandes extends StatefulWidget {
  /// Appelé à chaque changement. La charge reçue est `{id, statut,
  /// statutPaiement}` ; le plus souvent on ignore son contenu et on recharge.
  final void Function(BuildContext context, Map<String, dynamic> commande)
  onChange;
  final Widget child;

  const EcouteurCommandes({
    super.key,
    required this.onChange,
    required this.child,
  });

  @override
  State<EcouteurCommandes> createState() => _EcouteurCommandesState();
}

class _EcouteurCommandesState extends State<EcouteurCommandes> {
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    // Le socket n'est pas enregistré dans tous les bancs d'essai : un écran
    // testé isolément ne doit pas tomber pour autant.
    if (!sl.isRegistered<SocketService>()) return;
    _sub = sl<SocketService>().onCommandeChangee.listen((donnees) {
      if (mounted) widget.onChange(context, donnees);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
