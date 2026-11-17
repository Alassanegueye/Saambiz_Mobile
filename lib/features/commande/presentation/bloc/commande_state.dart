import 'package:saambiz/core/widgets/barre_pagination.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/commande_model.dart';

abstract class CommandeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CommandeInitial extends CommandeState {}

class CommandeLoading extends CommandeState {}

/// Liste de commandes (acheteur ou vendeur)
class CommandesLoaded extends CommandeState {
  final List<CommandeModel> commandes;

  /// Où l'on est dans la liste. Une page unique replie la barre.
  final Pagination pagination;

  CommandesLoaded(this.commandes, [this.pagination = const Pagination()]);
  @override
  List<Object?> get props => [commandes, pagination.page, pagination.pages];
}

/// Une commande vient d'être créée
class CommandeCreee extends CommandeState {
  final CommandeModel commande;
  CommandeCreee(this.commande);
  @override
  List<Object?> get props => [commande];
}

/// Paiement initié : URL vers laquelle rediriger l'acheteur (peut être null)
class PaiementInitie extends CommandeState {
  final String commandeId;
  final String? paymentUrl;
  PaiementInitie(this.commandeId, this.paymentUrl);
  @override
  List<Object?> get props => [commandeId, paymentUrl];
}

/// Une commande a été mise à jour (statut, annulation)
class CommandeMiseAJour extends CommandeState {
  final CommandeModel commande;
  CommandeMiseAJour(this.commande);
  @override
  List<Object?> get props => [commande];
}

class CommandeError extends CommandeState {
  final String message;
  CommandeError(this.message);
  @override
  List<Object?> get props => [message];
}

/// La demande de retour a été envoyée avec succès
class RetourDemande extends CommandeState {
  final String commandeId;
  RetourDemande(this.commandeId);
  @override
  List<Object?> get props => [commandeId];
}
