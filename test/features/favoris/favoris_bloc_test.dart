import 'package:saambiz/core/widgets/barre_pagination.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/errors/failure.dart';
import 'package:saambiz/features/favoris/domain/entities/boutique_suivie.dart';
import 'package:saambiz/features/favoris/domain/entities/suivi_boutique.dart';
import 'package:saambiz/features/favoris/domain/repositories/favoris_repository.dart';
import 'package:saambiz/features/favoris/domain/usecases/basculer_cloche.dart';
import 'package:saambiz/features/favoris/domain/usecases/get_boutiques_suivies.dart';
import 'package:saambiz/features/favoris/domain/usecases/ne_plus_suivre_boutique.dart';
import 'package:saambiz/features/favoris/domain/usecases/suivre_boutique.dart';
import 'package:saambiz/features/favoris/presentation/bloc/favoris_bloc.dart';
import 'package:saambiz/features/favoris/presentation/bloc/favoris_event.dart';
import 'package:saambiz/features/favoris/presentation/bloc/favoris_state.dart';

/// Dépôt en mémoire : chaque opération réussit, sauf celles qu'on fait
/// échouer.
class _Depot implements FavorisRepository {
  List<BoutiqueSuivie> boutiques;
  bool listeEnPanne = false;
  bool actionsEnPanne = false;

  _Depot(this.boutiques);

  final _panne = ServerFailure(errorMessage: 'Serveur injoignable');

  @override
  Future<Either<Failure, (List<BoutiqueSuivie>, Pagination)>>
  mesBoutiquesSuivies({int page = 1}) async => listeEnPanne
      ? Left(_panne)
      // Une seule page : le depot factice n'a pas a simuler la pagination,
      // ce sont les regles du bloc qu'on verifie ici.
      : Right((List.of(boutiques), Pagination(total: boutiques.length)));

  @override
  Future<Either<Failure, void>> nePlusSuivre(String boutiqueId) async {
    if (actionsEnPanne) return Left(_panne);
    boutiques = boutiques.where((b) => b.id != boutiqueId).toList();
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> suivre(String boutiqueId) async =>
      actionsEnPanne ? Left(_panne) : const Right(null);

  @override
  Future<Either<Failure, bool>> basculerCloche(
    String boutiqueId,
    bool active,
  ) async => actionsEnPanne ? Left(_panne) : Right(active);

  @override
  Future<Either<Failure, SuiviBoutique>> statutSuivi(String boutiqueId) async =>
      Right(SuiviBoutique.aucun(boutiqueId));
}

void main() {
  const footShop = BoutiqueSuivie(id: 'b1', nom: 'FootShop');
  const aloShop = BoutiqueSuivie(id: 'b2', nom: 'Aloushop', clocheActive: true);

  late _Depot depot;
  late FavorisBloc bloc;

  setUp(() {
    depot = _Depot([footShop, aloShop]);
    bloc = FavorisBloc(
      getBoutiquesSuivies: GetBoutiquesSuivies(depot),
      suivreBoutique: SuivreBoutique(depot),
      nePlusSuivreBoutique: NePlusSuivreBoutique(depot),
      basculerCloche: BasculerCloche(depot),
    );
  });

  tearDown(() => bloc.close());

  /// Charge la liste et attend qu'elle soit affichée.
  Future<void> charger() async {
    bloc.add(LoadFavoris());
    await bloc.stream.firstWhere((e) => e is FavorisLoaded);
  }

  group('Un refus du serveur n’efface pas les boutiques suivies', () {
    test(
      'ne plus suivre échoue : la liste revient, sans faux succès',
      () async {
        await charger();
        depot.actionsEnPanne = true;

        final suite = expectLater(
          bloc.stream,
          emitsInOrder([
            FavorisError('Serveur injoignable'),
            FavorisLoaded(const [footShop, aloShop]),
          ]),
        );
        bloc.add(SupprimerFavori('b1'));
        await suite;
      },
    );

    test('la cloche échoue : elle revient à son état d’avant', () async {
      await charger();
      depot.actionsEnPanne = true;

      final suite = expectLater(
        bloc.stream,
        emitsInOrder([
          // Bascule optimiste, puis retour en arrière.
          FavorisLoaded([footShop.copyWith(clocheActive: true), aloShop]),
          FavorisError('Serveur injoignable'),
          FavorisLoaded(const [footShop, aloShop]),
        ]),
      );
      bloc.add(ToggleClocheFavori('b1', true));
      await suite;
    });

    test('l’actualisation échoue : la liste affichée reste', () async {
      await charger();
      depot.listeEnPanne = true;

      final suite = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<FavorisLoading>(),
          FavorisError('Serveur injoignable'),
          FavorisLoaded(const [footShop, aloShop]),
        ]),
      );
      bloc.add(LoadFavoris());
      await suite;
    });

    test('sans liste à remettre, l’erreur reste affichée', () async {
      depot.listeEnPanne = true;

      final suite = expectLater(
        bloc.stream,
        emitsInOrder([isA<FavorisLoading>(), isA<FavorisError>()]),
      );
      bloc.add(LoadFavoris());
      await suite;
      expect(bloc.state, isA<FavorisError>());
    });
  });

  test(
    'ne plus suivre réussit : la liste se met à jour et le confirme',
    () async {
      await charger();

      final suite = expectLater(
        bloc.stream,
        emits(
          FavorisLoaded(const [
            aloShop,
          ], succes: 'Vous ne suivez plus cette boutique.'),
        ),
      );
      bloc.add(SupprimerFavori('b1'));
      await suite;
    },
  );
}
