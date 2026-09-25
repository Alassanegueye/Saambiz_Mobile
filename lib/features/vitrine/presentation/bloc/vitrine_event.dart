import 'package:equatable/equatable.dart';

abstract class VitrineEvent extends Equatable {
  const VitrineEvent();
  @override
  List<Object?> get props => [];
}

/// Ouverture de l'écran « Mon site web » : état du site + secteurs.
class ChargerVitrine extends VitrineEvent {}

/// Le vendeur a choisi un logo — on l'analyse et on compose une proposition.
class AnalyserLogoDemande extends VitrineEvent {
  final String logoPath;
  final String? secteur;
  final String? activite;

  const AnalyserLogoDemande({required this.logoPath, this.secteur, this.activite});

  @override
  List<Object?> get props => [logoPath, secteur, activite];
}

/// Dernière étape de l'assistant : on crée le site et on le publie.
class GenererVitrineDemande extends VitrineEvent {
  final String? logoPath;
  final String secteur;
  final String? activite;
  final String? modele;
  final String? accent;
  final String? slogan;
  final String? apropos;
  final String? horaires;
  final String? annonce;
  final bool commande;
  final bool paiementLivraison;

  const GenererVitrineDemande({
    this.logoPath,
    required this.secteur,
    this.activite,
    this.modele,
    this.accent,
    this.slogan,
    this.apropos,
    this.horaires,
    this.annonce,
    this.commande = true,
    this.paiementLivraison = true,
  });

  @override
  List<Object?> get props => [
        logoPath, secteur, activite, modele, accent, slogan, apropos,
        horaires, annonce, commande, paiementLivraison,
      ];
}

/// Retouche d'un site déjà créé.
class ModifierVitrineDemande extends VitrineEvent {
  final Map<String, dynamic> champs;
  const ModifierVitrineDemande(this.champs);

  @override
  List<Object?> get props => [champs];
}
