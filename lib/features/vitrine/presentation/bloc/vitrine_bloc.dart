import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/vitrine.dart';
import '../../domain/usecases/analyser_logo.dart';
import '../../domain/usecases/generer_vitrine.dart';
import '../../domain/usecases/get_ma_vitrine.dart';
import '../../domain/usecases/get_secteurs_vitrine.dart';
import '../../domain/usecases/modifier_vitrine.dart';
import 'vitrine_event.dart';
import 'vitrine_state.dart';

class VitrineBloc extends Bloc<VitrineEvent, VitrineState> {
  final GetMaVitrine getMaVitrine;
  final GetSecteursVitrine getSecteurs;
  final AnalyserLogo analyserLogo;
  final GenererVitrine genererVitrine;
  final ModifierVitrine modifierVitrine;

  /// Les secteurs ne changent pas d'un écran à l'autre : une fois chargés, on
  /// les garde pour ne pas les redemander à chaque retour dans l'assistant.
  List<SecteurVitrine> _secteurs = const [];

  VitrineBloc({
    required this.getMaVitrine,
    required this.getSecteurs,
    required this.analyserLogo,
    required this.genererVitrine,
    required this.modifierVitrine,
  }) : super(VitrineInitial()) {
    on<ChargerVitrine>(_onCharger);
    on<AnalyserLogoDemande>(_onAnalyser);
    on<GenererVitrineDemande>(_onGenerer);
    on<ModifierVitrineDemande>(_onModifier);
  }

  Future<void> _onCharger(ChargerVitrine event, Emitter<VitrineState> emit) async {
    emit(VitrineChargement());

    // Les deux appels sont lancés AVANT le premier `await` : ils voyagent donc
    // en parallèle. Les enchaîner doublerait l'attente sur une connexion lente,
    // alors que l'écran a besoin des deux pour s'afficher.
    final futureVitrine = getMaVitrine();
    final futureSecteurs = _secteurs.isEmpty ? getSecteurs() : null;

    final etat = await futureVitrine;
    if (futureSecteurs != null) {
      // Un échec sur les secteurs n'empêche pas d'afficher l'écran : ils ne
      // servent qu'à l'assistant, et la liste sera redemandée au prochain
      // passage puisqu'elle reste vide.
      (await futureSecteurs).fold((_) {}, (liste) => _secteurs = liste);
    }

    etat.fold(
      (f) {
        // 404 : pas de boutique du tout. Ce n'est pas une panne, c'est une
        // étape — l'écran renvoie vers la création de la boutique.
        if (f is ServerFailure && f.statusCode == 404) {
          emit(VitrineSansBoutique(f.errorMessage));
        } else {
          emit(VitrineErreur(f.errorMessage));
        }
      },
      (v) => emit(VitrineChargee(vitrine: v, secteurs: _secteurs)),
    );
  }

  Future<void> _onAnalyser(
      AnalyserLogoDemande event, Emitter<VitrineState> emit) async {
    emit(VitrineAnalyseEnCours());
    final r = await analyserLogo(
      logoPath: event.logoPath,
      secteur: event.secteur,
      activite: event.activite,
    );
    r.fold(
      (f) => emit(VitrineErreur(f.errorMessage)),
      (resultat) => emit(VitrineAnalysee(resultat)),
    );
  }

  Future<void> _onGenerer(
      GenererVitrineDemande event, Emitter<VitrineState> emit) async {
    emit(VitrineGenerationEnCours());
    final r = await genererVitrine(
      logoPath: event.logoPath,
      secteur: event.secteur,
      activite: event.activite,
      modele: event.modele,
      accent: event.accent,
      slogan: event.slogan,
      apropos: event.apropos,
      horaires: event.horaires,
      annonce: event.annonce,
      commande: event.commande,
      paiementLivraison: event.paiementLivraison,
      blocs: event.blocs,
    );
    r.fold(
      (f) => emit(VitrineErreur(f.errorMessage)),
      (v) => emit(VitrineCreee(v)),
    );
  }

  Future<void> _onModifier(
      ModifierVitrineDemande event, Emitter<VitrineState> emit) async {
    emit(VitrineChargement());
    final r = await modifierVitrine(event.champs);
    r.fold(
      (f) => emit(VitrineErreur(f.errorMessage)),
      (v) => emit(VitrineEnregistree(v)),
    );
  }
}
