import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/basculer_cloche.dart';
import '../../domain/usecases/get_boutiques_suivies.dart';
import '../../domain/usecases/ne_plus_suivre_boutique.dart';
import '../../domain/usecases/suivre_boutique.dart';
import 'favoris_event.dart';
import 'favoris_state.dart';

/// Le bloc dépend de cas d'usage, jamais d'un repository concret.
///
/// C'est ce qui permet de le tester sans réseau : on injecte quatre doublures
/// et on vérifie la suite d'états émis.
class FavorisBloc extends Bloc<FavorisEvent, FavorisState> {
  final GetBoutiquesSuivies getBoutiquesSuivies;
  final SuivreBoutique suivreBoutique;
  final NePlusSuivreBoutique nePlusSuivreBoutique;
  final BasculerCloche basculerCloche;

  FavorisBloc({
    required this.getBoutiquesSuivies,
    required this.suivreBoutique,
    required this.nePlusSuivreBoutique,
    required this.basculerCloche,
  }) : super(FavorisInitial()) {
    on<LoadFavoris>(_onCharger);
    on<AjouterFavori>(_onSuivre);
    on<SupprimerFavori>(_onNePlusSuivre);
    on<ToggleClocheFavori>(_onBasculerCloche);
  }

  Future<void> _onCharger(LoadFavoris event, Emitter<FavorisState> emit) async {
    final avant = state;
    emit(FavorisLoading());
    await _recharger(emit, avant: avant);
  }

  /// Recharge la liste ; [succes] accompagne la liste quand elle suit une
  /// action, pour que l'écran la confirme.
  Future<void> _recharger(
    Emitter<FavorisState> emit, {
    String? succes,
    FavorisState? avant,
  }) async {
    final resultat = await getBoutiquesSuivies();
    resultat.fold(
      (panne) => _echec(emit, panne.errorMessage, avant ?? state),
      (boutiques) => emit(FavorisLoaded(boutiques, succes: succes)),
    );
  }

  /// Signale l'échec, puis remet la liste qui était affichée.
  ///
  /// Sans ce retour, l'état restait `FavorisError` : l'écran, qui n'a rien
  /// à montrer pour une erreur, effaçait toutes les boutiques suivies au
  /// premier refus du serveur (ne plus suivre, alertes, actualisation).
  /// La liste remise ne porte pas de message de succès : celui de l'action
  /// précédente ne doit pas s'afficher une seconde fois.
  void _echec(Emitter<FavorisState> emit, String message, FavorisState avant) {
    emit(FavorisError(message));
    if (avant is FavorisLoaded) emit(FavorisLoaded(avant.boutiques));
  }

  Future<void> _onSuivre(
    AjouterFavori event,
    Emitter<FavorisState> emit,
  ) async {
    final avant = state;
    final resultat = await suivreBoutique(event.boutiqueId);
    await resultat.fold(
      (panne) async => _echec(emit, panne.errorMessage, avant),
      (_) => _recharger(emit, succes: 'Boutique ajoutée à vos favoris.'),
    );
  }

  Future<void> _onNePlusSuivre(
    SupprimerFavori event,
    Emitter<FavorisState> emit,
  ) async {
    final avant = state;
    final resultat = await nePlusSuivreBoutique(event.boutiqueId);
    await resultat.fold(
      (panne) async => _echec(emit, panne.errorMessage, avant),
      (_) => _recharger(emit, succes: 'Vous ne suivez plus cette boutique.'),
    );
  }

  Future<void> _onBasculerCloche(
    ToggleClocheFavori event,
    Emitter<FavorisState> emit,
  ) async {
    final avant = state;

    // Bascule optimiste : l'interrupteur suit le doigt sans attendre le
    // serveur. Sur un réseau lent, l'attente donnait l'impression que le
    // bouton ne répondait pas.
    if (avant is FavorisLoaded) {
      emit(
        FavorisLoaded([
          for (final b in avant.boutiques)
            b.id == event.boutiqueId
                ? b.copyWith(clocheActive: event.active)
                : b,
        ]),
      );
    }

    final resultat = await basculerCloche(
      event.boutiqueId,
      active: event.active,
    );

    resultat.fold(
      // Échec : on remet l'état d'avant, sinon l'interface affiche une
      // cloche activée que le serveur n'a jamais enregistrée.
      (panne) => _echec(emit, panne.errorMessage, avant),
      (etatReel) {
        // Le serveur peut renvoyer autre chose que ce qu'on a demandé.
        final courant = state;
        if (courant is FavorisLoaded) {
          emit(
            FavorisLoaded(
              [
                for (final b in courant.boutiques)
                  b.id == event.boutiqueId
                      ? b.copyWith(clocheActive: etatReel)
                      : b,
              ],
              succes: etatReel
                  ? 'Alertes activées : vous serez prévenu des promotions et nouveautés.'
                  : 'Alertes désactivées pour cette boutique.',
            ),
          );
        }
      },
    );
  }
}
