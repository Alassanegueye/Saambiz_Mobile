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

  /// Pages demandées, dans l'ordre : c'est ce qui dit si le bloc a gardé sa
  /// place ou s'il est reparti en page un.
  final demandees = <int>[];

  /// Dix par page, comme le serveur.
  @override
  Future<Either<Failure, (List<BoutiqueSuivie>, Pagination)>>
  mesBoutiquesSuivies({int page = 1}) async {
    demandees.add(page);
    if (listeEnPanne) return Left(_panne);
    const parPage = 10;
    final total = boutiques.length;
    final debut = (page - 1) * parPage;
    final tranche = debut >= total
        ? <BoutiqueSuivie>[]
        : boutiques.sublist(debut, (debut + parPage).clamp(0, total));
    return Right((
      tranche,
      Pagination(
        page: page,
        pages: total == 0 ? 1 : (total / parPage).ceil(),
        total: total,
      ),
    ));
  }

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

  group('La place dans la liste, dix boutiques par page', () {
    /// Vingt-cinq boutiques suivies : trois pages.
    void beaucoup() => depot.boutiques = List.generate(
      25,
      (i) => BoutiqueSuivie(id: 'b$i', nom: 'Boutique $i'),
    );

    Future<FavorisLoaded> allerA(int page) async {
      bloc.add(LoadFavoris(page: page));
      return await bloc.stream.firstWhere((e) => e is FavorisLoaded)
          as FavorisLoaded;
    }

    test('« Suivant » demande la page d’après au serveur', () async {
      beaucoup();
      final etat = await allerA(2);

      expect(etat.boutiques.length, 10);
      expect(etat.pagination.page, 2);
      expect(etat.pagination.pages, 3);
      expect(etat.pagination.total, 25);
    });

    test('ne plus suivre ne renvoie pas en page un', () async {
      // Avant, le rechargement qui suit l'action repartait de la page un :
      // on perdait sa place à chaque boutique retirée.
      beaucoup();
      await allerA(3);
      depot.demandees.clear();

      bloc.add(SupprimerFavori('b20'));
      final etat =
          await bloc.stream.firstWhere(
                (e) => e is FavorisLoaded && e.succes != null,
              )
              as FavorisLoaded;

      expect(depot.demandees, [3]);
      expect(etat.pagination.page, 3);
    });

    test('la barre survit à une bascule de cloche', () async {
      // La bascule optimiste reconstruisait l'état sans sa pagination : la
      // barre « Précédent / Suivant » disparaissait au premier appui sur
      // une cloche, et la page affichée n'était plus atteignable.
      beaucoup();
      await allerA(2);

      bloc.add(ToggleClocheFavori('b12', true));
      final etat =
          await bloc.stream.firstWhere(
                (e) => e is FavorisLoaded && e.succes != null,
              )
              as FavorisLoaded;

      expect(etat.pagination.page, 2);
      expect(etat.pagination.pages, 3);
    });

    test('un refus du serveur garde la barre', () async {
      beaucoup();
      await allerA(2);
      depot.actionsEnPanne = true;

      bloc.add(SupprimerFavori('b12'));
      final etat =
          await bloc.stream.firstWhere(
                (e) => e is FavorisLoaded && e.pagination.pages == 3,
              )
              as FavorisLoaded;

      expect(etat.pagination.page, 2);
    });

    test('vider la dernière page ramène sur la précédente', () async {
      // Vingt et une boutiques : la page trois n'en porte qu'une. La retirer
      // vide la page ; sans rattrapage l'écran affichait « aucune boutique
      // suivie » alors qu'il en restait vingt, sans moyen de revenir.
      depot.boutiques = List.generate(
        21,
        (i) => BoutiqueSuivie(id: 'b$i', nom: 'Boutique $i'),
      );
      await allerA(3);

      bloc.add(SupprimerFavori('b20'));
      final etat =
          await bloc.stream.firstWhere(
                (e) => e is FavorisLoaded && e.boutiques.isNotEmpty,
              )
              as FavorisLoaded;

      expect(etat.pagination.page, 2);
      expect(etat.boutiques.length, 10);
    });

    test('une panne réseau n’est pas masquée par un second essai', () async {
      beaucoup();
      await allerA(3);
      depot.listeEnPanne = true;
      depot.demandees.clear();

      bloc.add(LoadFavoris(page: 3));
      await bloc.stream.firstWhere((e) => e is FavorisError);

      expect(depot.demandees, [3], reason: 'un seul appel');
    });
  });
}
