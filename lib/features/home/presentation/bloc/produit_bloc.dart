import 'package:flutter_bloc/flutter_bloc.dart';
import 'produit_event.dart';
import 'produit_state.dart';
import '../../data/repositories/produit_repository_impl.dart';

class ProduitBloc extends Bloc<ProduitEvent, ProduitState> {
  final ProduitRepository repository;

  ProduitBloc(this.repository) : super(ProduitInitial()) {
    on<LoadProduits>((event, emit) async {
      emit(ProduitLoading());
      try {
        final produits = await repository.getProduits();
        emit(ProduitLoaded(produits));
      } catch (e) {
        emit(ProduitError(e.toString()));
      }
    });

    on<SearchProduits>((event, emit) async {
      emit(ProduitLoading());
      try {
        final produits = await repository.rechercher(event.query);
        emit(ProduitLoaded(produits));
      } catch (e) {
        emit(ProduitError(e.toString()));
      }
    });

    on<FilterVille>((event, emit) async {
      emit(ProduitLoading());
      try {
        final produits = await repository.filtrerVille(event.ville);
        emit(ProduitLoaded(produits));
      } catch (e) {
        emit(ProduitError(e.toString()));
      }
    });
  }
}