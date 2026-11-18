import 'package:saambiz/core/widgets/barre_pagination.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/models/produit_model.dart';
import '../../domain/usecases/get_mes_produits.dart';
import '../../domain/usecases/supprimer_produit.dart';
import '../../domain/usecases/toggle_disponibilite_produit.dart';

// Events
abstract class VendeurProduitEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMesProduits extends VendeurProduitEvent {
  /// Page demandée : le serveur en rend dix à la fois.
  final int page;
  LoadMesProduits({this.page = 1});
  @override
  List<Object?> get props => [page];
}

class SupprimerProduit extends VendeurProduitEvent {
  final String id;
  SupprimerProduit(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleDispoProduit extends VendeurProduitEvent {
  final String id;
  ToggleDispoProduit(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class VendeurProduitState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VendeurProduitLoading extends VendeurProduitState {}

class VendeurProduitLoaded extends VendeurProduitState {
  final List<ProduitModel> produits;

  /// Message à confirmer à l'utilisateur après une action réussie.
  final String? succes;

  /// Où l'on est dans la liste. Une page unique replie la barre.
  final Pagination pagination;

  VendeurProduitLoaded(
    this.produits, {
    this.succes,
    this.pagination = const Pagination(),
  });
  @override
  List<Object?> get props => [produits, succes];
}

class VendeurProduitError extends VendeurProduitState {
  final String message;
  VendeurProduitError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class VendeurProduitBloc
    extends Bloc<VendeurProduitEvent, VendeurProduitState> {
  final GetMesProduits getMesProduits;
  final SupprimerProduitUsecase supprimerProduit;
  final ToggleDisponibiliteProduitUsecase toggleDisponibilite;

  VendeurProduitBloc({
    required this.getMesProduits,
    required this.supprimerProduit,
    required this.toggleDisponibilite,
  }) : super(VendeurProduitLoading()) {
    on<LoadMesProduits>(_onLoad);
    on<SupprimerProduit>(_onSupprimer);
    on<ToggleDispoProduit>(_onToggle);
  }

  /// Page affichée, conservée entre deux rechargements : une suppression
  /// ou une bascule de disponibilité ne doit pas renvoyer en page un.
  int _page = 1;

  Future<void> _reloadOrError(
    Emitter<VendeurProduitState> emit, {
    String? succes,
    int? page,
  }) async {
    if (page != null) _page = page;
    var result = await getMesProduits(page: _page);

    // Supprimer le dernier produit d'une page la vide. Sans ce rattrapage,
    // l'écran affichait « aucun produit » sur la page trois alors qu'il en
    // restait vingt, sans aucun moyen de revenir en arrière.
    // Uniquement sur une réponse reçue : en cas de panne, la liste est vide
    // elle aussi, et relancer la requête masquerait le message d'erreur.
    final recue = result.fold((_) => null, (r) => r);
    if (recue != null && recue.$1.isEmpty && _page > 1) {
      _page = recue.$2.pages;
      result = await getMesProduits(page: _page);
    }

    result.fold(
      (failure) => emit(VendeurProduitError(failure.errorMessage)),
      (recue) => emit(
        VendeurProduitLoaded(recue.$1, succes: succes, pagination: recue.$2),
      ),
    );
  }

  Future<void> _onLoad(
    LoadMesProduits event,
    Emitter<VendeurProduitState> emit,
  ) async {
    emit(VendeurProduitLoading());
    await _reloadOrError(emit, page: event.page);
  }

  Future<void> _onSupprimer(
    SupprimerProduit event,
    Emitter<VendeurProduitState> emit,
  ) async {
    final result = await supprimerProduit(event.id);
    await result.fold(
      (failure) async => emit(VendeurProduitError(failure.errorMessage)),
      (_) => _reloadOrError(emit, succes: 'Produit supprimé avec succès'),
    );
  }

  Future<void> _onToggle(
    ToggleDispoProduit event,
    Emitter<VendeurProduitState> emit,
  ) async {
    // Bascule immédiate à l'écran, puis confirmation par le serveur.
    final actuel = state;
    if (actuel is VendeurProduitLoaded) {
      emit(
        VendeurProduitLoaded([
          for (final p in actuel.produits)
            p.id == event.id ? p.avecDisponible(!p.disponible) : p,
        ], pagination: actuel.pagination),
      );
    }
    final result = await toggleDisponibilite(event.id);
    await result.fold(
      (failure) async => emit(VendeurProduitError(failure.errorMessage)),
      (_) =>
          _reloadOrError(emit, succes: 'Disponibilité du produit mise à jour'),
    );
  }
}
