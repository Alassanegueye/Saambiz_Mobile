import 'package:equatable/equatable.dart';

/// Le site web public de la boutique : `saambiz.com/b/<slug>`.
///
/// À ne pas confondre avec l'affichage de la boutique DANS l'application, qui
/// est le même pour toutes : un client qui parcourt SaamBiz doit reconnaître
/// une fiche boutique d'un coup d'œil, quelle que soit l'enseigne. Le site
/// web, lui, appartient au vendeur — c'est le sien qu'il partage à ses
/// propres clients, et il porte donc ses couleurs.
class Vitrine extends Equatable {
  final String slug;
  final String url;

  /// Le site est-il ouvert au public ? Le vendeur le ferme et le rouvre.
  final bool active;

  /// Le vendeur est-il passé par l'assistant ? Une seule fois, dans
  /// l'application. Tant que c'est faux, le tableau de bord web affiche
  /// « activez votre boutique depuis l'application ».
  final bool configuree;

  final String modele;   // 'classique' | 'galerie' | 'catalogue'
  final String accent;   // #RRGGBB
  final String? apropos;
  final String? annonce;
  final String? horaires;
  final String? secteur;
  final String? activite;
  final String logoForme; // 'rond' | 'carre' | 'bandeau' | 'libre'
  final Map<String, String> reseaux;
  final Map<String, bool> sections;
  final bool commande;
  final bool paiementLivraison;
  final int vues;

  /// Renseigné uniquement au retour de la création : faux si le vendeur avait
  /// choisi un logo mais que l'hébergeur d'images l'a refusé. Le site est créé
  /// quand même — il serait absurde de perdre quatre réponses pour une image —
  /// et l'écran d'arrivée le signale pour qu'il le reprenne.
  final bool? logoEnregistre;

  /// Contenus composés par le vendeur : { icones: {categorieId: cle},
  /// avantages: [{icone, titre, texte}] }.
  final Map<String, dynamic> blocs;

  const Vitrine({
    required this.slug,
    required this.url,
    required this.active,
    required this.configuree,
    required this.modele,
    required this.accent,
    this.apropos,
    this.annonce,
    this.horaires,
    this.secteur,
    this.activite,
    this.logoForme = 'libre',
    this.reseaux = const {},
    this.sections = const {},
    this.commande = true,
    this.paiementLivraison = true,
    this.vues = 0,
    this.logoEnregistre,
    this.blocs = const {},
  });

  @override
  List<Object?> get props => [
        slug, url, active, configuree, modele, accent, apropos, annonce,
        horaires, secteur, activite, logoForme, reseaux, sections, commande,
        paiementLivraison, vues, logoEnregistre, blocs,
      ];
}

/// Une couleur relevée dans le logo du vendeur.
class CouleurLogo extends Equatable {
  final String hex;

  /// Part de la surface du logo qu'elle occupe, en pourcentage.
  final double part;

  const CouleurLogo({required this.hex, required this.part});

  @override
  List<Object?> get props => [hex, part];
}

/// Une couleur proposée au vendeur, avec la raison de sa présence.
class CouleurProposee extends Equatable {
  final String hex;

  /// « Couleur de votre logo », « Nuance voisine »… Le vendeur doit savoir
  /// d'où sort une pastille avant de la choisir.
  final String nom;

  const CouleurProposee({required this.hex, required this.nom});

  @override
  List<Object?> get props => [hex, nom];
}

/// Ce que l'analyse du logo a trouvé.
class AnalyseLogo extends Equatable {
  final int? largeur;
  final int? hauteur;

  /// 'rond' | 'carre' | 'bandeau' | 'libre'.
  final String forme;

  /// Phrase à montrer au vendeur : « votre logo est rond, il s'affiche en
  /// pastille ». Sans elle, la forme détectée reste une décision opaque.
  final String? conseilForme;

  final List<CouleurLogo> couleurs;
  final String accentPropose;
  final List<CouleurProposee> palette;

  /// 'faible' | 'correct' | 'bonne' | 'inconnue', avec le message associé.
  final String niveauQualite;
  final String? messageQualite;

  const AnalyseLogo({
    this.largeur,
    this.hauteur,
    required this.forme,
    this.conseilForme,
    this.couleurs = const [],
    required this.accentPropose,
    this.palette = const [],
    this.niveauQualite = 'inconnue',
    this.messageQualite,
  });

  @override
  List<Object?> get props => [
        largeur, hauteur, forme, conseilForme, couleurs, accentPropose,
        palette, niveauQualite, messageQualite,
      ];
}

/// Le site tel que l'assistant le propose, avant enregistrement.
///
/// Le vendeur relit cette proposition et la corrige : la dernière étape de
/// l'assistant est un aperçu, pas une validation à l'aveugle.
class PropositionVitrine extends Equatable {
  final String modele;
  final String accent;
  final String slogan;
  final String apropos;
  final String horaires;
  final List<CouleurProposee> palette;

  /// Les explications à afficher sous chaque choix : pourquoi cette mise en
  /// page, pourquoi cette couleur, pourquoi ce cadrage du logo.
  final String? pourquoiModele;
  final String? pourquoiCouleur;
  final String? pourquoiLogo;

  const PropositionVitrine({
    required this.modele,
    required this.accent,
    required this.slogan,
    required this.apropos,
    required this.horaires,
    this.palette = const [],
    this.pourquoiModele,
    this.pourquoiCouleur,
    this.pourquoiLogo,
  });

  @override
  List<Object?> get props => [
        modele, accent, slogan, apropos, horaires, palette,
        pourquoiModele, pourquoiCouleur, pourquoiLogo,
      ];
}

/// Un secteur d'activité proposé à la première question de l'assistant.
class SecteurVitrine extends Equatable {
  final String cle;
  final String libelle;
  final String exemples;
  final String modeleRecommande;

  const SecteurVitrine({
    required this.cle,
    required this.libelle,
    required this.exemples,
    required this.modeleRecommande,
  });

  @override
  List<Object?> get props => [cle, libelle, exemples, modeleRecommande];
}
