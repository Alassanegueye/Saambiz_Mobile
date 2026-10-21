import 'package:equatable/equatable.dart';

abstract class BoutiqueEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMaBoutique extends BoutiqueEvent {}

class CreerBoutiqueRequested extends BoutiqueEvent {
  final String nom;
  final String description;
  final String localisation;
  final String telephone;
  final String? categorie;
  final List<String>? categories;
  final String? slogan;
  final String? logoPath;

  CreerBoutiqueRequested({
    required this.nom,
    required this.description,
    required this.localisation,
    required this.telephone,
    this.categorie,
    this.categories,
    this.slogan,
    this.logoPath,
  });

  @override
  List<Object?> get props =>
      [nom, description, localisation, telephone, categorie, categories, slogan, logoPath];
}

class ModifierBoutiqueRequested extends BoutiqueEvent {
  final String? nom;
  final String? description;
  final String? localisation;
  final String? telephone;
  final String? categorie;
  final List<String>? categories;
  final String? slogan;
  final String? logoPath;

  ModifierBoutiqueRequested({
    this.nom,
    this.description,
    this.localisation,
    this.telephone,
    this.categorie,
    this.categories,
    this.slogan,
    this.logoPath,
  });

  @override
  List<Object?> get props =>
      [nom, description, localisation, telephone, categorie, categories, slogan, logoPath];
}

class PauseBoutiqueRequested extends BoutiqueEvent {}

class ReactiverBoutiqueRequested extends BoutiqueEvent {}
