import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/commande/data/datasources/commande_remote_datasource.dart';
import 'package:saambiz/features/commande/data/models/commande_model.dart';
import 'package:saambiz/features/commande/data/repositories/commande_repository.dart';
import 'package:saambiz/features/commande/presentation/bloc/commande_bloc.dart';
import 'package:saambiz/features/commande/presentation/pages/commande_detail_page.dart';
import 'package:saambiz/injection_container.dart';

/// Un deuxième appui pendant que le premier est en vol.
///
/// Les boutons d'action vivent dans la barre du bas, donc hors du corps de la
/// page — et le voile de chargement, lui, ne couvre que le corps. Ils
/// restaient donc cliquables pendant la requête. Le vendeur, devant un écran
/// qui ne bougeait pas, appuyait une seconde fois : le serveur traitait le
/// premier appel (en_attente → acceptee) puis refusait le second, et renvoyait
/// « Transition impossible : acceptee → acceptee ». La commande était pourtant
/// bien acceptée ; seul l'écran disait le contraire.
class _SourceLente implements CommandeRemoteDataSource {
  int appels = 0;

  /// Ce que le serveur a vraiment enregistré, comme une vraie base.
  String statutServeur = 'en_attente';

  /// Bloque jusqu'à ce que le test le décide, comme un réseau lent.
  final _attente = Completer<void>();
  void repondre() => _attente.complete();

  @override
  Future<CommandeModel> changerStatut(String id, String statut) async {
    appels++;
    await _attente.future;
    statutServeur = statut;
    return CommandeModel.fromJson({
      'id': id,
      'referenceCommande': 'CMD-1',
      'montantProduits': 9000,
      'montantTotal': 9000,
      'statut': statut,
      'modePaiement': 'a_la_livraison',
      'modeLivraison': 'retrait',
    });
  }

  @override
  Future<CommandeModel> getCommande(String id) async {
    // Relecture : le serveur rend l'état qu'il a réellement enregistré.
    return CommandeModel.fromJson({
      'id': id,
      'referenceCommande': 'CMD-1',
      'montantProduits': 9000,
      'montantTotal': 9000,
      'statut': statutServeur,
      'modePaiement': 'a_la_livraison',
      'modeLivraison': 'retrait',
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non prévu ici');
}

CommandeModel _enAttente() => CommandeModel.fromJson({
  'id': 'cmd-1',
  'referenceCommande': 'CMD-2026-TEST',
  'montantProduits': 9000,
  'montantTotal': 9000,
  'statut': 'en_attente',
  'modePaiement': 'a_la_livraison',
  'modeLivraison': 'retrait',
});

void main() {
  late _SourceLente source;

  setUp(() async {
    await sl.reset();
    source = _SourceLente();
    sl.registerLazySingleton<CommandeRemoteDataSource>(() => source);
    sl.registerFactory(
      () => CommandeBloc(CommandeRepository(sl())),
    );
  });

  tearDown(() => sl.reset());

  testWidgets('un deuxième appui sur « Accepter » ne part pas', (t) async {
    final cle = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(navigatorKey: cle, home: const Scaffold()),
    );

    // La page lit ses arguments dans la route : on la pousse donc nous-mêmes,
    // comme le fait la liste des commandes.
    cle.currentState!.push(
      MaterialPageRoute(
        settings: RouteSettings(
          arguments: CommandeDetailArgs(_enAttente(), isVendeur: true),
        ),
        builder: (_) => const CommandeDetailPage(),
      ),
    );
    await t.pumpAndSettle();

    final accepter = find.widgetWithText(ElevatedButton, 'Accepter');
    expect(accepter, findsOneWidget, reason: 'le bouton doit être proposé');

    await t.tap(accepter);
    await t.pump();
    expect(source.appels, 1);

    // Deuxième appui, pendant que le premier n'a pas répondu.
    await t.tap(accepter, warnIfMissed: false);
    await t.pump();
    expect(
      source.appels,
      1,
      reason: 'le bouton doit être neutralisé tant que la réponse n’est pas là',
    );

    // On laisse la réponse arriver, sans `pumpAndSettle` : le bandeau de
    // succès s'anime en boucle et ne laisserait jamais l'arbre au repos.
    source.repondre();
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  });
}
