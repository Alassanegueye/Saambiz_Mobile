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

  /// Page affichee, conservee entre deux rechargements : ne plus suivre une
  /// boutique, ou basculer une cloche, ne doit pas renvoyer en page un.
  int _page = 1;

  Future<void> _onCharger(LoadFavoris event, Emitter<FavorisState> emit) async {
    final avant = state;
    _page = event.page;
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
    var resultat = await getBoutiquesSuivies(page: _page);

    // Ne plus suivre la derniere boutique d'une page la vide. Sans ce
    // rattrapage, l'ecran affichait « aucune boutique suivie » sur la page
    // trois alors qu'il en restait vingt, sans moyen de revenir en arriere.
    // Uniquement sur une reponse recue : en cas de panne, la liste est vide
    // elle aussi, et relancer la requete masquerait le message d'erreur.
    final recue = resultat.fold((_) => null, (r) => r);
    if (recue != null && recue.$1.isEmpty && _page > 1) {
      _page = recue.$2.pages;
      resultat = await getBoutiquesSuivies(page: _page);
    }

    resultat.fold(
      (panne) => _echec(emit, panne.errorMessage, avant ?? state),
      (recue) =>
          emit(FavorisLoaded(recue.$1, succes: succes, pagination: recue.$2)),
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
    // La pagination de l'etat remis est celle d'avant : sans elle, la barre
    // « Precedent / Suivant » disparaissait au premier refus du serveur.
    if (avant is FavorisLoaded) {
      emit(FavorisLoaded(avant.boutiques, pagination: avant.pagination));
    }
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
        ], pagination: avant.pagination),
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
              pagination: courant.pagination,
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
