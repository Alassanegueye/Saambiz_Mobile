import 'package:equatable/equatable.dart';

import '../../data/models/vitrine_model.dart';
import '../../domain/entities/vitrine.dart';

abstract class VitrineState extends Equatable {
  const VitrineState();
  @override
  List<Object?> get props => [];
}

class VitrineInitial extends VitrineState {}

class VitrineChargement extends VitrineState {}

/// Le logo part vers le serveur. État distinct du chargement général : c'est
/// le seul moment où l'attente se compte en secondes sur un réseau mobile, et
/// l'écran doit pouvoir dire « nous analysons votre logo » plutôt que de
/// faire tourner un rond muet.
class VitrineAnalyseEnCours extends VitrineState {}

/// Le site est en cours de création.
class VitrineGenerationEnCours extends VitrineState {}

/// État courant du site, avec les secteurs disponibles pour l'assistant.
class VitrineChargee extends VitrineState {
  final Vitrine vitrine;
  final List<SecteurVitrine> secteurs;

  const VitrineChargee({required this.vitrine, this.secteurs = const []});

  @override
  List<Object?> get props => [vitrine, secteurs];
}

/// Le vendeur n'a pas encore de boutique : rien à habiller.
class VitrineSansBoutique extends VitrineState {
  final String message;
  const VitrineSansBoutique(this.message);

  @override
  List<Object?> get props => [message];
}

/// Le logo a été analysé : voici ce qui a été trouvé, et le site proposé.
class VitrineAnalysee extends VitrineState {
  final ResultatAnalyse resultat;
  const VitrineAnalysee(this.resultat);

  @override
  List<Object?> get props => [resultat];
}

/// Le site vient d'être créé. État distinct de `VitrineChargee` : c'est lui
/// qui déclenche l'écran « votre site vitrine est prêt ».
class VitrineCreee extends VitrineState {
  final Vitrine vitrine;
  const VitrineCreee(this.vitrine);

  @override
  List<Object?> get props => [vitrine];
}

class VitrineEnregistree extends VitrineState {
  final Vitrine vitrine;
  const VitrineEnregistree(this.vitrine);

  @override
  List<Object?> get props => [vitrine];
}

class VitrineErreur extends VitrineState {
  final String message;
  const VitrineErreur(this.message);

  @override
  List<Object?> get props => [message];
}
