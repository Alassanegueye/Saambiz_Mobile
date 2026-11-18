import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/errors/failure.dart';
import 'package:saambiz/features/signalements/data/datasources/signalements_remote_datasource.dart';
import 'package:saambiz/features/signalements/data/models/signalement_model.dart';
import 'package:saambiz/features/signalements/data/repositories/signalements_repository.dart';
import 'package:saambiz/features/signalements/presentation/bloc/signalements_bloc.dart';
import 'package:saambiz/features/signalements/presentation/pages/signaler_form_page.dart';
import 'package:saambiz/injection_container.dart';

/// Retient ce qui serait parti au serveur, sans réseau.
class _DepotFactice extends SignalementsRepository {
  _DepotFactice() : super(SignalementsRemoteDataSourceImpl(Dio()));

  String? raison;
  String? description;

  @override
  Future<Either<Failure, SignalementModel>> creerSignalement({
    required String type,
    required String raison,
    required String description,
    required String cibleId,
  }) async {
    this.raison = raison;
    this.description = description;
    return Left(ServerFailure(errorMessage: 'hors ligne'));
  }
}

void main() {
  late _DepotFactice depot;

  setUp(() async {
    await sl.reset();
    depot = _DepotFactice();
    sl.registerFactory<SignalementsBloc>(() => SignalementsBloc(depot));
  });

  Future<void> ouvrir(WidgetTester tester, String type) async {
    // Un écran de téléphone : toute la page tient, bouton compris.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SignalerFormPage(type: type, cibleId: 'p1'),
      ),
    );
    await tester.pump();
  }

  ElevatedButton bouton(WidgetTester tester) => tester.widget<ElevatedButton>(
    find.ancestor(
      of: find.text('Envoyer le signalement'),
      matching: find.byType(ElevatedButton),
    ),
  );

  test('chaque cible a ses motifs, « Autre » toujours en dernier', () {
    expect(
      motifsSignalement('produit'),
      contains('Contrefaçon ou faux produit'),
    );
    expect(motifsSignalement('boutique'), contains('Usurpation d’identité'));
    expect(motifsSignalement('produit').last, kMotifAutre);
    expect(motifsSignalement('boutique').last, kMotifAutre);
  });

  testWidgets('rien ne part sans motif ; le motif choisi part comme raison', (
    tester,
  ) async {
    await ouvrir(tester, 'produit');
    expect(bouton(tester).onPressed, isNull);

    await tester.tap(find.text('Contrefaçon ou faux produit'));
    await tester.pump();
    expect(bouton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();
    // La feuille de confirmation : son bouton porte le même libellé.
    await tester.tap(find.text('Envoyer le signalement').last);
    await tester.pumpAndSettle();

    expect(depot.raison, 'Contrefaçon ou faux produit');
    expect(depot.description, isEmpty);
  });

  testWidgets('« Autre » oblige à préciser', (tester) async {
    await ouvrir(tester, 'boutique');
    await tester.tap(find.text(kMotifAutre));
    await tester.pump();

    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();

    expect(find.text('Précisez ce qui ne va pas'), findsOneWidget);
    expect(depot.raison, isNull);
  });
}
