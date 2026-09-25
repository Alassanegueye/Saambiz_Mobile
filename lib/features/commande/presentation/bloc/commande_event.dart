import 'package:equatable/equatable.dart';

abstract class CommandeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Acheteur : charger mes commandes
class LoadMesCommandes extends CommandeEvent {
  final String? statut;
  LoadMesCommandes({this.statut});
  @override
  List<Object?> get props => [statut];
}

/// Vendeur : charger les commandes reçues
class LoadCommandesVendeur extends CommandeEvent {
  final String? statut;
  LoadCommandesVendeur({this.statut});
  @override
  List<Object?> get props => [statut];
}

/// Acheteur : créer une commande à partir du panier
class CreerCommande extends CommandeEvent {
  final List<Map<String, dynamic>> items;
  final String modeLivraison;
  final String modePaiement;
  final String? adresseLivraison;
  final String? numeroTelephone;
  final String? note;

  CreerCommande({
    required this.items,
    this.modeLivraison = 'livraison',
    this.modePaiement = 'en_ligne',
    this.adresseLivraison,
    this.numeroTelephone,
    this.note,
  });

  @override
  List<Object?> get props =>
      [items, modeLivraison, modePaiement, adresseLivraison, numeroTelephone, note];
}

/// Acheteur : payer une commande en ligne
class PayerCommande extends CommandeEvent {
  final String commandeId;
  final String methode; // 'orange_money' | 'wave'
  final String? numeroTelephone;
  PayerCommande(this.commandeId, {required this.methode, this.numeroTelephone});
  @override
  List<Object?> get props => [commandeId, methode, numeroTelephone];
}

/// Acheteur : annuler une commande
class AnnulerCommande extends CommandeEvent {
  final String commandeId;
  AnnulerCommande(this.commandeId);
  @override
  List<Object?> get props => [commandeId];
}

/// Vendeur : faire avancer le statut
class ChangerStatutCommande extends CommandeEvent {
  final String commandeId;
  final String statut;
  ChangerStatutCommande(this.commandeId, this.statut);
  @override
  List<Object?> get props => [commandeId, statut];
}

/// Acheteur : demander un retour sur une commande livrée
class DemanderRetourCommande extends CommandeEvent {
  final String commandeId;
  final String raison;
  DemanderRetourCommande(this.commandeId, this.raison);
  @override
  List<Object?> get props => [commandeId, raison];
}
