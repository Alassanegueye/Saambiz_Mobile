import 'package:equatable/equatable.dart';
import '../../data/models/produit_model.dart';

abstract class ProduitState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProduitInitial extends ProduitState {}

class ProduitLoading extends ProduitState {}

class ProduitLoaded extends ProduitState {
  final List<ProduitModel> produits;
  ProduitLoaded(this.produits);

  @override
  List<Object?> get props => [produits];
}

class ProduitError extends ProduitState {
  final String message;
  ProduitError(this.message);

  @override
  List<Object?> get props => [message];
}