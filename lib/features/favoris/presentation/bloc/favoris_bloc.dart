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
    emit(FavorisLoading());
    final resultat = await getBoutiquesSuivies();
    resultat.fold(
      (panne) => emit(FavorisError(panne.errorMessage)),
      (boutiques) => emit(FavorisLoaded(boutiques)),
    );
  }

  Future<void> _onSuivre(AjouterFavori event, Emitter<FavorisState> emit) async {
    final resultat = await suivreBoutique(event.boutiqueId);
    resultat.fold(
      (panne) => emit(FavorisError(panne.errorMessage)),
      (_) => add(LoadFavoris()),
    );
  }

  Future<void> _onNePlusSuivre(
      SupprimerFavori event, Emitter<FavorisState> emit) async {
    final resultat = await nePlusSuivreBoutique(event.boutiqueId);
    resultat.fold(
      (panne) => emit(FavorisError(panne.errorMessage)),
      (_) => add(LoadFavoris()),
    );
  }

  Future<void> _onBasculerCloche(
      ToggleClocheFavori event, Emitter<FavorisState> emit) async {
    final avant = state;

    // Bascule optimiste : l'interrupteur suit le doigt sans attendre le
    // serveur. Sur un réseau lent, l'attente donnait l'impression que le
    // bouton ne répondait pas.
    if (avant is FavorisLoaded) {
      emit(FavorisLoaded([
        for (final b in avant.boutiques)
          b.id == event.boutiqueId ? b.copyWith(clocheActive: event.active) : b,
      ]));
    }

    final resultat = await basculerCloche(event.boutiqueId, active: event.active);

    resultat.fold(
      (panne) {
        // Échec : on remet l'état d'avant, sinon l'interface affiche une
        // cloche activée que le serveur n'a jamais enregistrée.
        if (avant is FavorisLoaded) emit(avant);
        emit(FavorisError(panne.errorMessage));
      },
      (etatReel) {
        // Le serveur peut renvoyer autre chose que ce qu'on a demandé.
        final courant = state;
        if (courant is FavorisLoaded) {
          emit(FavorisLoaded([
            for (final b in courant.boutiques)
              b.id == event.boutiqueId ? b.copyWith(clocheActive: etatReel) : b,
          ]));
        }
      },
    );
  }
}
