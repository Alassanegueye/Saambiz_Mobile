import 'package:equatable/equatable.dart';

abstract class ProduitEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProduits extends ProduitEvent {}

class SearchProduits extends ProduitEvent {
  final String query;
  SearchProduits(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterVille extends ProduitEvent {
  final String ville;
  FilterVille(this.ville);

  @override
  List<Object?> get props => [ville];
}