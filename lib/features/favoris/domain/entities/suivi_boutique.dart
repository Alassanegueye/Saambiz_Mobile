import 'package:equatable/equatable.dart';

/// L'état de suivi d'une boutique par un acheteur.
///
/// Deux notions distinctes que l'interface confondait :
///   • `suivi` — la boutique est dans mes favoris, elle apparaît dans mon fil ;
///   • `clocheActive` — je veux en plus recevoir une notification push.
///
/// On peut suivre sans cloche : c'est même le cas par défaut. Les mélanger
/// conduit à envoyer des notifications à des gens qui ne les ont pas demandées.
class SuiviBoutique extends Equatable {
  final String boutiqueId;
  final bool suivi;
  final bool clocheActive;

  const SuiviBoutique({
    required this.boutiqueId,
    required this.suivi,
    required this.clocheActive,
  });

  /// État d'une boutique jamais suivie.
  const SuiviBoutique.aucun(this.boutiqueId)
      : suivi = false,
        clocheActive = false;

  SuiviBoutique copyWith({bool? suivi, bool? clocheActive}) => SuiviBoutique(
        boutiqueId: boutiqueId,
        suivi: suivi ?? this.suivi,
        clocheActive: clocheActive ?? this.clocheActive,
      );

  @override
  List<Object?> get props => [boutiqueId, suivi, clocheActive];
}
