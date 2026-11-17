import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/commande/data/datasources/commande_remote_datasource.dart';
import 'package:saambiz/features/commande/data/models/commande_model.dart';
import 'package:saambiz/features/commande/data/repositories/commande_repository.dart';
import 'package:saambiz/features/commande/presentation/bloc/commande_bloc.dart';
import 'package:saambiz/features/commande/presentation/pages/commande_detail_page.dart';
import 'package:saambiz/injection_container.dart';

/// Les deux boutons du vendeur sur la fiche d'une commande.
///
/// Tous deux ont échoué, chacun à sa façon, et aucun test ne les traversait :
/// la page ne s'ouvre que par une route porteuse d'arguments, ce qui suffit à
/// la tenir hors de portée des bancs d'essai ordinaires.
class _FauxServeur implements CommandeRemoteDataSource {
  int appels = 0;

  /// Statuts demandés par l'écran, dans l'ordre.
  final List<String> demandes = [];

  /// Ce que le serveur a vraiment enregistré, comme une vraie base. La fiche
  /// se relit à l'ouverture : sans cet état initial, elle repartait sur
  /// « en attente » et les boutons testés disparaissaient.
  String statutServeur;

  /// Bloque jusqu'à ce que le test le décide, comme un réseau lent.
  final Completer<void> _attente = Completer<void>();
  void repondre() => _attente.complete();

  /// Le mode de paiement enregistré : la relecture doit le rendre tel quel,
  /// sinon une commande à régler en ligne redevient « à la réception ».
  final String modePaiement;

  _FauxServeur({
    bool rapide = false,
    this.statutServeur = 'en_attente',
    this.modePaiement = 'a_la_livraison',
  }) {
    if (rapide) repondre();
  }

  @override
  Future<CommandeModel> changerStatut(String id, String statut) async {
    appels++;
    demandes.add(statut);
    await _attente.future;
    statutServeur = statut;
    return _modele(id, statut);
  }

  @override
  Future<CommandeModel> getCommande(String id) async =>
      // Relecture : le serveur rend l'état qu'il a réellement enregistré.
      _modele(id, statutServeur);

  CommandeModel _modele(String id, String statut) => CommandeModel.fromJson({
    'id': id,
    'referenceCommande': 'CMD-2026-TEST',
    'montantProduits': 9000,
    'montantTotal': 9000,
    'statut': statut,
    'modePaiement': modePaiement,
    'modeLivraison': 'retrait',
  });

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non prévu ici');
}

CommandeModel _commande({
  String statut = 'en_attente',
  String modePaiement = 'a_la_livraison',
}) => CommandeModel.fromJson({
  'id': 'cmd-1',
  'referenceCommande': 'CMD-2026-TEST',
  'montantProduits': 9000,
  'montantTotal': 9000,
  'statut': statut,
  'modePaiement': modePaiement,
  'modeLivraison': 'retrait',
});

void main() {
  late _FauxServeur serveur;

  /// Enregistre un serveur neuf et rend la page prête à être posée.
  void preparer({
    bool rapide = false,
    String statut = 'en_attente',
    String modePaiement = 'a_la_livraison',
  }) {
    serveur = _FauxServeur(
      rapide: rapide,
      statutServeur: statut,
      modePaiement: modePaiement,
    );
    sl.registerLazySingleton<CommandeRemoteDataSource>(() => serveur);
    sl.registerFactory(() => CommandeBloc(CommandeRepository(sl())));
  }

  setUp(() async => sl.reset());
  tearDown(() => sl.reset());

  /// Pose la fiche d'une commande, vue par le vendeur.
  ///
  /// La page lit ses arguments dans la route : on la pousse donc nous-mêmes,
  /// comme le fait la liste des commandes.
  Future<void> ouvrir(WidgetTester t, CommandeModel commande) async {
    final cle = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(navigatorKey: cle, home: const Scaffold()));
    cle.currentState!.push(
      MaterialPageRoute(
        settings: RouteSettings(
          arguments: CommandeDetailArgs(commande, isVendeur: true),
        ),
        builder: (_) => const CommandeDetailPage(),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('un deuxième appui sur « Accepter » ne part pas', (t) async {
    // Les boutons vivent dans la barre du bas, donc hors du corps de la page
    // — et le voile de chargement, lui, ne couvre que le corps. Ils restaient
    // cliquables pendant la requête. Le vendeur, devant un écran qui ne
    // bougeait pas, appuyait une seconde fois : le serveur traitait le premier
    // appel (en_attente → acceptee) puis refusait le second, et renvoyait
    // « Transition impossible : acceptee → acceptee ». La commande était
    // pourtant bien acceptée ; seul l'écran disait le contraire.
    preparer();
    await ouvrir(t, _commande());

    final accepter = find.widgetWithText(ElevatedButton, 'Accepter');
    expect(accepter, findsOneWidget, reason: 'le bouton doit être proposé');

    await t.tap(accepter);
    await t.pump();
    expect(serveur.appels, 1);

    // Deuxième appui, pendant que le premier n'a pas répondu.
    await t.tap(accepter, warnIfMissed: false);
    await t.pump();
    expect(
      serveur.appels,
      1,
      reason: 'le bouton doit être neutralisé tant que la réponse n’est pas là',
    );

    // On laisse la réponse arriver, sans `pumpAndSettle` : le bandeau de
    // succès s'anime en boucle et ne laisserait jamais l'arbre au repos.
    serveur.repondre();
    await t.pump();
    // Le bandeau de succès pose un minuteur : on le laisse expirer, sinon le
    // banc d'essai refuse de rendre la main (« a Timer is still pending »).
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets(
    'acceptée et réglée à la réception : « Passer à : En préparation » part',
    (t) async {
      // Exactement l'écran signalé : commande acceptée, retrait en boutique,
      // paiement à la réception. Le bouton s'affichait et ne faisait RIEN,
      // parce que l'affichage traitait le cas `acceptee` à part tandis que le
      // gestionnaire du clic lisait la table nue, qui ne le contient pas. Le
      // statut suivant valait donc `null`, le `if` était faux, et aucun appel
      // ne partait : pas d'erreur, pas de message, rien.
      preparer(rapide: true, statut: 'acceptee');
      await ouvrir(t, _commande(statut: 'acceptee'));

      final bouton = find.widgetWithText(
        ElevatedButton,
        'Passer à : En préparation',
      );
      expect(bouton, findsOneWidget, reason: 'le bouton doit être proposé');

      await t.tap(bouton);
      await t.pump();
      await t.pump(const Duration(seconds: 10));

      expect(
        serveur.demandes,
        ['en_preparation'],
        reason: 'le clic doit demander la mise en préparation, une seule fois',
      );
    },
  );

  testWidgets('acceptée mais à régler en ligne : aucun bouton d’avancement', (
    t,
  ) async {
    // Le serveur refuse la préparation tant que le client n'a pas payé :
    // proposer le bouton serait promettre une action qui échouerait.
    preparer(rapide: true, statut: 'acceptee', modePaiement: 'en_ligne');
    await ouvrir(t, _commande(statut: 'acceptee', modePaiement: 'en_ligne'));

    expect(
      find.widgetWithText(ElevatedButton, 'Passer à : En préparation'),
      findsNothing,
    );
  });
}
