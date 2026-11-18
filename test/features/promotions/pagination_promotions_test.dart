import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/widgets/barre_pagination.dart';
import 'package:saambiz/features/promotions/data/datasources/promotions_remote_datasource.dart';
import 'package:saambiz/features/promotions/data/models/promotion_model.dart';
import 'package:saambiz/features/promotions/data/repositories/promotions_repository.dart';
import 'package:saambiz/features/promotions/presentation/bloc/promotions_bloc.dart';
import 'package:saambiz/features/promotions/presentation/bloc/promotions_event.dart';
import 'package:saambiz/features/promotions/presentation/bloc/promotions_state.dart';

/// « Mes promotions », dix par page.
///
/// Le serveur n'en rend plus qu'une page à la fois (GET /promotions). Ce qui
/// est vérifié ici : la page demandée arrive bien au datasource, elle est
/// conservée entre deux rechargements — supprimer une promotion ne doit pas
/// renvoyer en page un —, et vider la dernière page ne laisse pas l'écran
/// bloqué sur un « aucune promotion » mensonger.

/// Un faux serveur : vingt-cinq promotions, dix par page.
class _FauxDatasource implements PromotionsRemoteDataSource {
  /// Pages demandées, dans l'ordre.
  final demandees = <int>[];

  /// Nombre total de promotions côté serveur ; une suppression le réduit.
  int total;

  _FauxDatasource({this.total = 25});

  @override
  Future<PagePromotions> mesPromotions({int page = 1}) async {
    demandees.add(page);
    const parPage = 10;
    final pages = total == 0 ? 1 : (total / parPage).ceil();
    final debut = (page - 1) * parPage;
    final combien = (total - debut).clamp(0, parPage);
    return PagePromotions(
      List.generate(
        combien,
        (i) => PromotionModel.fromJson({
          'id': 'pr${debut + i}',
          'titre': 'Promo ${debut + i}',
          'prixPromo': 1000,
        }),
      ),
      Pagination(page: page, pages: pages, total: total),
    );
  }

  @override
  Future<void> supprimerPromotion(String id) async => total -= 1;

  @override
  Future<List<PromotionModel>> promotionsActives() async => [];

  @override
  Future<PromotionModel> creerPromotion({
    required String titre,
    required String description,
    required num prixPromo,
    required String dateDebut,
    required String dateFin,
    required String produitId,
  }) => throw UnimplementedError();

  @override
  Future<PromotionModel> modifierPromotion(
    String id, {
    String? titre,
    String? description,
    num? prixPromo,
    String? dateDebut,
    String? dateFin,
  }) => throw UnimplementedError();
}

void main() {
  late _FauxDatasource faux;
  late PromotionsBloc bloc;

  setUp(() {
    faux = _FauxDatasource();
    bloc = PromotionsBloc(PromotionsRepository(faux));
  });

  tearDown(() => bloc.close());

  Future<PromotionsState> charger(LoadMesPromotions event) async {
    bloc.add(event);
    return bloc.stream.firstWhere((s) => s is! PromotionsLoading);
  }

  test('la première page en rend dix sur vingt-cinq', () async {
    final etat = await charger(LoadMesPromotions());

    expect(etat, isA<PromotionsLoaded>());
    final loaded = etat as PromotionsLoaded;
    expect(loaded.promotions.length, 10);
    expect(loaded.pagination.page, 1);
    expect(loaded.pagination.pages, 3);
    expect(loaded.pagination.total, 25);
    expect(faux.demandees, [1]);
  });

  test('« Suivant » demande la page deux au serveur', () async {
    await charger(LoadMesPromotions());
    final etat = await charger(LoadMesPromotions(page: 2));

    expect((etat as PromotionsLoaded).pagination.page, 2);
    expect(faux.demandees, [1, 2]);
  });

  test('la page affichée survit à une suppression', () async {
    // Sans cela, supprimer la troisième promotion de la page deux ramenait
    // l'écran en page un : on perdait sa place à chaque geste.
    await charger(LoadMesPromotions());
    await charger(LoadMesPromotions(page: 2));

    bloc.add(SupprimerPromotion('pr12'));
    await bloc.stream.firstWhere(
      (s) => s is PromotionsLoaded && s.pagination.page == 2,
    );

    expect(faux.demandees.last, 2, reason: 'on reste en page deux');
  });

  test('vider la dernière page ramène sur la précédente', () async {
    // Vingt et une promotions : la page trois n'en contient qu'une. La
    // supprimer vide la page. Sans rattrapage, l'écran affichait « aucune
    // promotion » alors qu'il en restait vingt, sans moyen de revenir.
    faux.total = 21;
    await charger(LoadMesPromotions(page: 3));

    bloc.add(SupprimerPromotion('pr20'));
    final etat = await bloc.stream.firstWhere(
      (s) => s is PromotionsLoaded && s.promotions.isNotEmpty,
    );

    final loaded = etat as PromotionsLoaded;
    expect(loaded.pagination.page, 2);
    expect(loaded.promotions.length, 10);
  });

  test('une erreur réseau n’est pas masquée par un second essai', () async {
    // Le rattrapage ci-dessus ne doit s'appliquer qu'à une réponse reçue :
    // sur une panne, la liste est vide elle aussi, et relancer la requête
    // effacerait le message d'erreur.
    final cassee = _DatasourceEnPanne();
    final b = PromotionsBloc(PromotionsRepository(cassee));
    addTearDown(b.close);

    b.add(LoadMesPromotions(page: 3));
    final etat = await b.stream.firstWhere((s) => s is! PromotionsLoading);

    expect(etat, isA<PromotionsError>());
    expect(cassee.essais, 1, reason: 'un seul appel, pas de second essai');
  });
}

/// Un serveur injoignable.
class _DatasourceEnPanne extends _FauxDatasource {
  int essais = 0;

  @override
  Future<PagePromotions> mesPromotions({int page = 1}) async {
    essais += 1;
    throw Exception('réseau');
  }
}
