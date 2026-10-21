import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/vitrine.dart';
import '../bloc/vitrine_bloc.dart';
import '../bloc/vitrine_event.dart';
import '../bloc/vitrine_state.dart';
import 'vitrine_prete_page.dart';
import '../widgets/etapes_contenus_vitrine.dart';

class _C {
  static const navy      = Color(0xFF0D1B3D);
  static const navyLight = Color(0xFFE8EDF7);
  static const bg        = Color(0xFFF7F9FC);
  static const white     = Color(0xFFFFFFFF);
  static const border    = Color(0xFFE2E7F0);
  static const text      = Color(0xFF0D1B3D);
  static const muted     = Color(0xFF5B6C8A);
}

/// Les mises en page, avec ce à quoi chacune convient. La liste doit rester
/// alignée sur MODELES_VITRINE côté serveur.
const _modeles = [
  ('classique', 'Classique', 'Des cartes produits équilibrées.'),
  ('galerie', 'Galerie', 'Des cartes avec de grandes photos.'),
  ('catalogue', 'Catalogue', 'Une liste compacte, rapide à parcourir.'),
];

/// L'assistant de création du site.
///
/// Cinq étapes, une question par écran : activité, logo, style, avantages,
/// textes. Un vendeur remplit ça debout dans sa
/// boutique, entre deux clients : un formulaire de vingt champs sur un seul
/// écran serait abandonné à la moitié.
///
/// Le fil conducteur est que rien n'est imposé. L'analyse du logo PROPOSE des
/// couleurs, le secteur PROPOSE une mise en page, les textes sont pré-remplis
/// — et chaque proposition est accompagnée de la raison qui l'a fait choisir,
/// pour que le vendeur puisse la refuser en connaissance de cause.
class AssistantVitrinePage extends StatefulWidget {
  final List<SecteurVitrine> secteurs;

  /// Non nul quand le vendeur revient modifier un site existant : les champs
  /// repartent alors de ce qu'il a déjà, et non de zéro.
  final Vitrine? vitrine;

  const AssistantVitrinePage({super.key, required this.secteurs, this.vitrine});

  @override
  State<AssistantVitrinePage> createState() => _AssistantVitrinePageState();
}

class _AssistantVitrinePageState extends State<AssistantVitrinePage> {
  static const _nombreEtapes = 5;
  int _etape = 0;

  // ── Réponses ────────────────────────────────────────────────────────
  String? _secteur;
  final _activite = TextEditingController();
  File? _logo;

  String _modele = 'classique';
  String _accent = '#0D1B3D';
  List<CouleurProposee> _palette = const [];

  final _slogan = TextEditingController();
  final _apropos = TextEditingController();
  final _horaires = TextEditingController();
  final _annonce = TextEditingController();

  bool _commande = true;
  bool _paiementLivraison = true;

  // Les avantages affichés sur le site. Les icônes des catégories déjà
  // choisies sont conservées telles quelles.
  final List<AvantageBrouillon> _avantages = [];
  Map<String, dynamic> _icones = const {};

  // Ce que l'analyse a trouvé — affiché tel quel au vendeur.
  AnalyseLogo? _analyse;
  String? _pourquoiModele;
  String? _pourquoiCouleur;

  bool get _modification => widget.vitrine != null;

  @override
  void initState() {
    super.initState();

    final v = widget.vitrine;
    if (v != null) {
      _secteur = v.secteur;
      _activite.text = v.activite ?? '';
      _modele = v.modele;
      _accent = v.accent;
      _apropos.text = v.apropos ?? '';
      _horaires.text = v.horaires ?? '';
      _annonce.text = v.annonce ?? '';
      _commande = v.commande;
      _paiementLivraison = v.paiementLivraison;

      final blocs = v.blocs;
      for (final a in (blocs['avantages'] as List? ?? const []).whereType<Map>()) {
        _avantages.add(AvantageBrouillon(
          icone: '${a['icone'] ?? 'etoile'}',
          titre: '${a['titre'] ?? ''}',
          texte: '${a['texte'] ?? ''}',
        ));
      }
      if (blocs['icones'] is Map) _icones = Map<String, dynamic>.from(blocs['icones'] as Map);
    }
  }

  /// Les contenus à envoyer avec le site.
  Map<String, dynamic> _blocsAEnvoyer() => {
        'icones': _icones,
        'avantages': _avantages
            .where((a) => a.titre.text.trim().isNotEmpty)
            .map((a) => {'icone': a.icone, 'titre': a.titre.text.trim(), 'texte': a.texte.text.trim()})
            .toList(),
      };

  @override
  void dispose() {
    _activite.dispose();
    _slogan.dispose();
    _apropos.dispose();
    _horaires.dispose();
    _annonce.dispose();
    for (final a in _avantages) {
      a.dispose();
    }
    super.dispose();
  }

  // ── Navigation entre les étapes ─────────────────────────────────────

  bool get _etapeValide {
    switch (_etape) {
      case 0:
        return _secteur != null;
      // Le logo reste facultatif : un vendeur qui n'en a pas ne doit pas être
      // bloqué là. Le site prend alors l'initiale de la boutique.
      default:
        return true;
    }
  }

  void _suivant() {
    if (_etape < _nombreEtapes - 1) {
      setState(() => _etape++);
      return;
    }
    _lancerGeneration();
  }

  void _precedent() {
    if (_etape == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _etape--);
    }
  }

  void _lancerGeneration() {
    context.read<VitrineBloc>().add(GenererVitrineDemande(
          logoPath: _logo?.path,
          secteur: _secteur ?? 'autre',
          activite: _activite.text.trim(),
          modele: _modele,
          accent: _accent,
          slogan: _slogan.text.trim().isEmpty ? null : _slogan.text.trim(),
          apropos: _apropos.text.trim(),
          horaires: _horaires.text.trim(),
          annonce: _annonce.text.trim(),
          commande: _commande,
          paiementLivraison: _paiementLivraison,
          blocs: _blocsAEnvoyer(),
        ));
  }

  // ── Choix du logo ───────────────────────────────────────────────────

  Future<void> _choisirLogo() async {
    final fichier = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Réduit avant l'envoi : un logo dépasse rarement 1000 px à l'usage, et
      // téléverser 8 Mo depuis un forfait mobile coûte cher pour rien.
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 92,
    );
    if (fichier == null) return;

    setState(() => _logo = File(fichier.path));

    if (!mounted) return;
    context.read<VitrineBloc>().add(AnalyserLogoDemande(
          logoPath: fichier.path,
          secteur: _secteur,
          activite: _activite.text.trim(),
        ));
  }

  /// Applique ce que le serveur a proposé — sans écraser ce que le vendeur
  /// aurait déjà saisi à la main.
  void _appliquerAnalyse(dynamic resultat) {
    final analyse = resultat.analyse as AnalyseLogo;
    final proposition = resultat.proposition as PropositionVitrine;

    setState(() {
      _analyse = analyse;
      _palette = proposition.palette.isNotEmpty ? proposition.palette : analyse.palette;
      _accent = proposition.accent;
      _pourquoiCouleur = proposition.pourquoiCouleur;
      _pourquoiModele = proposition.pourquoiModele;

      if (!_modification) {
        _modele = proposition.modele;
        if (_slogan.text.isEmpty) _slogan.text = proposition.slogan;
        if (_apropos.text.isEmpty) _apropos.text = proposition.apropos;
        if (_horaires.text.isEmpty) _horaires.text = proposition.horaires;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VitrineBloc, VitrineState>(
      listener: (context, state) {
        if (state is VitrineAnalysee) _appliquerAnalyse(state.resultat);

        if (state is VitrineCreee) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => VitrinePretePage(
              vitrine: state.vitrine,
              premiereCreation: !_modification,
            ),
          ));
        }

        if (state is VitrineErreur) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final genere = state is VitrineGenerationEnCours;

        return PopScope(
          canPop: !genere,
          child: Scaffold(
            backgroundColor: _C.bg,
            appBar: AppBar(
              backgroundColor: _C.white,
              surfaceTintColor: _C.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _C.text),
                onPressed: genere ? null : _precedent,
              ),
              title: Text(
                _modification ? 'Modifier mon site' : 'Créer mon site',
                style: const TextStyle(
                    color: _C.text, fontWeight: FontWeight.w700, fontSize: 17),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: (_etape + 1) / _nombreEtapes,
                  minHeight: 3,
                  backgroundColor: _C.navyLight,
                  valueColor: const AlwaysStoppedAnimation(_C.navy),
                ),
              ),
            ),

            body: genere
                ? const _EcranGeneration()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: _contenuEtape(state),
                  ),

            bottomNavigationBar: genere
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _C.navy,
                          disabledBackgroundColor: _C.border,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _etapeValide ? _suivant : null,
                        child: Text(
                          _etape == _nombreEtapes - 1
                              ? (_modification ? 'Enregistrer' : 'Créer mon site')
                              : 'Continuer',
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _contenuEtape(VitrineState state) {
    switch (_etape) {
      case 0:
        return _etapeActivite();
      case 1:
        return _etapeLogo(state);
      case 2:
        return _etapeStyle();
      case 3:
        return EtapeAvantages(avantages: _avantages, onChange: () => setState(() {}));
      default:
        return _etapeTextes();
    }
  }

  // ══ ÉTAPE 1 — L'ACTIVITÉ ═════════════════════════════════════════════

  Widget _etapeActivite() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TitreEtape(
          titre: 'Que vendez-vous ?',
          texte: 'Votre réponse choisit la mise en page et le ton des textes. '
              'La mode se montre en grand, l\'électronique se compare en liste.',
        ),
        const SizedBox(height: 18),

        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: widget.secteurs.map((s) {
            final actif = _secteur == s.cle;
            return InkWell(
              onTap: () => setState(() => _secteur = s.cle),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: actif ? _C.navyLight : _C.white,
                  border: Border.all(
                    color: actif ? _C.navy : _C.border,
                    width: actif ? 1.6 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.libelle,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: _C.text)),
                          const SizedBox(height: 2),
                          Text(s.exemples,
                              style: const TextStyle(fontSize: 12.4, color: _C.muted)),
                        ],
                      ),
                    ),
                    if (actif)
                      const Icon(Icons.check_circle_rounded, color: _C.navy, size: 20),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 22),
        const _Etiquette('En une phrase, que proposez-vous ?'),
        const SizedBox(height: 7),
        _Champ(
          controleur: _activite,
          indication: 'Ex. : boubous et tissus wax cousus sur mesure',
          lignes: 2,
          maxCaracteres: 300,
        ),
        const SizedBox(height: 6),
        const Text(
          'Cette phrase ouvrira la présentation de votre boutique. Vos mots '
          'valent mieux que les nôtres — mais vous pouvez laisser vide.',
          style: TextStyle(fontSize: 12.2, color: _C.muted, height: 1.45),
        ),
      ],
    );
  }

  // ══ ÉTAPE 2 — LE LOGO ════════════════════════════════════════════════

  Widget _etapeLogo(VitrineState state) {
    final analyseEnCours = state is VitrineAnalyseEnCours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TitreEtape(
          titre: 'Votre logo',
          texte: 'Nous y relevons vos couleurs et sa forme, pour habiller le '
              'site avec. Vous gardez la main sur tout.',
        ),
        const SizedBox(height: 18),

        InkWell(
          onTap: analyseEnCours ? null : _choisirLogo,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26),
            decoration: BoxDecoration(
              color: _C.white,
              border: Border.all(
                color: _logo != null ? _C.navy : _C.border,
                width: _logo != null ? 1.6 : 1.4,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (_logo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_logo!, height: 96, fit: BoxFit.contain),
                  )
                else
                  Container(
                    width: 58, height: 58,
                    decoration: const BoxDecoration(
                        color: _C.navyLight, shape: BoxShape.circle),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        color: _C.navy, size: 26),
                  ),
                const SizedBox(height: 12),
                Text(
                  _logo == null ? 'Choisir mon logo' : 'Changer de logo',
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700, color: _C.navy),
                ),
                const SizedBox(height: 3),
                const Text('PNG ou JPEG',
                    style: TextStyle(fontSize: 12.2, color: _C.muted)),
              ],
            ),
          ),
        ),

        if (analyseEnCours) ...[
          const SizedBox(height: 18),
          const Row(
            children: [
              SizedBox(
                width: 17, height: 17,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: _C.navy),
              ),
              SizedBox(width: 11),
              Text('Analyse de votre logo…',
                  style: TextStyle(fontSize: 13.5, color: _C.muted)),
            ],
          ),
        ],

        if (_analyse != null && !analyseEnCours) ...[
          const SizedBox(height: 20),
          _Encadre(
            children: [
              const Text('Ce que nous avons trouvé',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _C.text)),
              const SizedBox(height: 12),

              if (_analyse!.couleurs.isNotEmpty) ...[
                const Text('Vos couleurs',
                    style: TextStyle(fontSize: 12.5, color: _C.muted)),
                const SizedBox(height: 7),
                Row(
                  children: _analyse!.couleurs.take(5).map((c) {
                    return Container(
                      width: 34, height: 34,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _versCouleur(c.hex),
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.border),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 13),
              ],

              if (_analyse!.conseilForme != null)
                _Puce(texte: _analyse!.conseilForme!),

              // Un logo trop petit remonte flou une fois agrandi dans
              // l'en-tête : mieux vaut le dire ici qu'après publication.
              if (_analyse!.niveauQualite == 'faible' &&
                  _analyse!.messageQualite != null)
                _Puce(texte: _analyse!.messageQualite!, alerte: true),
            ],
          ),
        ],

        if (_logo == null && !analyseEnCours) ...[
          const SizedBox(height: 16),
          const Text(
            'Pas de logo ? Passez cette étape : votre site affichera '
            'l\'initiale de votre boutique, et vous pourrez ajouter votre '
            'logo plus tard.',
            style: TextStyle(fontSize: 12.5, color: _C.muted, height: 1.5),
          ),
        ],
      ],
    );
  }

  // ══ ÉTAPE 3 — LE STYLE ═══════════════════════════════════════════════

  Widget _etapeStyle() {
    // Les couleurs relevées dans le logo d'abord ; à défaut, une palette de
    // repli pour que l'écran ne soit jamais vide.
    final couleurs = _palette.isNotEmpty
        ? _palette
        : const [
            CouleurProposee(hex: '#0D1B3D', nom: 'Bleu SaamBiz'),
            CouleurProposee(hex: '#F2B705', nom: 'Or'),
            CouleurProposee(hex: '#1B7F4F', nom: 'Vert'),
            CouleurProposee(hex: '#B3261E', nom: 'Rouge'),
            CouleurProposee(hex: '#6B4EFF', nom: 'Violet'),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TitreEtape(
          titre: 'L\'allure de votre site',
          texte: 'Voici ce que nous proposons. Changez ce qui ne vous va pas.',
        ),
        const SizedBox(height: 20),

        const _Etiquette('Mise en page'),
        if (_pourquoiModele != null) ...[
          const SizedBox(height: 5),
          Text(_pourquoiModele!,
              style: const TextStyle(fontSize: 12.3, color: _C.muted, height: 1.45)),
        ],
        const SizedBox(height: 10),

        ..._modeles.map((m) {
          final actif = _modele == m.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              onTap: () => setState(() => _modele = m.$1),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: actif ? _C.navyLight : _C.white,
                  border: Border.all(
                      color: actif ? _C.navy : _C.border, width: actif ? 1.6 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _CroquisModele(modele: m.$1, actif: actif),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.$2,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: _C.text)),
                          const SizedBox(height: 2),
                          Text(m.$3,
                              style: const TextStyle(fontSize: 12.4, color: _C.muted)),
                        ],
                      ),
                    ),
                    if (actif)
                      const Icon(Icons.check_circle_rounded, color: _C.navy, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),
        const _Etiquette('Couleur'),
        if (_pourquoiCouleur != null) ...[
          const SizedBox(height: 5),
          Text(_pourquoiCouleur!,
              style: const TextStyle(fontSize: 12.3, color: _C.muted, height: 1.45)),
        ],
        const SizedBox(height: 12),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: couleurs.map((c) {
            final actif = _accent.toUpperCase() == c.hex.toUpperCase();
            return Tooltip(
              message: c.nom,
              child: InkWell(
                onTap: () => setState(() => _accent = c.hex),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _versCouleur(c.hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: actif ? _C.text : _C.border,
                      width: actif ? 3 : 1.5,
                    ),
                  ),
                  child: actif
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ══ ÉTAPE 4 — LES TEXTES ═════════════════════════════════════════════

  Widget _etapeTextes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TitreEtape(
          titre: 'Vos textes',
          texte: 'Nous les avons écrits pour vous. Relisez, corrigez ce qui '
              'ne vous ressemble pas.',
        ),
        const SizedBox(height: 20),

        const _Etiquette('Votre accroche'),
        const SizedBox(height: 7),
        _Champ(
          controleur: _slogan,
          indication: 'Une phrase qui résume votre boutique',
          maxCaracteres: 160,
        ),

        const SizedBox(height: 18),
        const _Etiquette('Présentation'),
        const SizedBox(height: 7),
        _Champ(
          controleur: _apropos,
          indication: 'Qui vous êtes, depuis quand, ce qui vous distingue',
          lignes: 6,
          maxCaracteres: 2000,
        ),

        const SizedBox(height: 18),
        const _Etiquette('Horaires'),
        const SizedBox(height: 7),
        _Champ(controleur: _horaires, indication: 'Lundi à samedi, 9h — 19h'),

        const SizedBox(height: 18),
        const _Etiquette('Bandeau d\'annonce (facultatif)'),
        const SizedBox(height: 7),
        _Champ(
          controleur: _annonce,
          indication: 'Ex. : livraison offerte à Dakar cette semaine',
          maxCaracteres: 180,
        ),
        const SizedBox(height: 5),
        const Text(
          'Affiché tout en haut de chaque page. Laissez vide pour ne rien afficher.',
          style: TextStyle(fontSize: 12.2, color: _C.muted),
        ),

        const SizedBox(height: 24),
        _Encadre(
          children: [
            _Bascule(
              valeur: _commande,
              titre: 'Accepter les commandes en ligne',
              texte: 'Vos clients commandent depuis le site, sans créer de compte.',
              onChange: (v) => setState(() => _commande = v),
            ),
            const Divider(height: 22, color: _C.border),
            _Bascule(
              valeur: _paiementLivraison,
              titre: 'Paiement à la livraison',
              texte: 'Le client règle en espèces à la réception.',
              onChange: _commande ? (v) => setState(() => _paiementLivraison = v) : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  PETITS COMPOSANTS
// ═══════════════════════════════════════════════════════════════════════

/// '#RRGGBB' → Color. Retombe sur le bleu SaamBiz si la chaîne est illisible :
/// un écran de choix de couleur ne doit pas planter sur une valeur douteuse.
Color _versCouleur(String hex) {
  final propre = hex.replaceAll('#', '').trim();
  final valeur = int.tryParse(propre, radix: 16);
  if (valeur == null || propre.length != 6) return _C.navy;
  return Color(0xFF000000 | valeur);
}

class _TitreEtape extends StatelessWidget {
  final String titre;
  final String texte;
  const _TitreEtape({required this.titre, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre,
            style: const TextStyle(
                fontSize: 21, fontWeight: FontWeight.w800, color: _C.text, height: 1.25)),
        const SizedBox(height: 8),
        Text(texte,
            style: const TextStyle(fontSize: 13.5, color: _C.muted, height: 1.55)),
      ],
    );
  }
}

class _Etiquette extends StatelessWidget {
  final String texte;
  const _Etiquette(this.texte);

  @override
  Widget build(BuildContext context) => Text(
        texte,
        style: const TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.text),
      );
}

class _Champ extends StatelessWidget {
  final TextEditingController controleur;
  final String indication;
  final int lignes;
  final int? maxCaracteres;

  const _Champ({
    required this.controleur,
    required this.indication,
    this.lignes = 1,
    this.maxCaracteres,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controleur,
      maxLines: lignes,
      maxLength: maxCaracteres,
      style: const TextStyle(fontSize: 14.5, color: _C.text),
      decoration: InputDecoration(
        hintText: indication,
        hintStyle: const TextStyle(color: Color(0xFF93A1B8), fontSize: 14),
        // Le compteur n'apporte rien tant qu'on est loin de la limite, et il
        // pousse chaque champ de vingt pixels.
        counterText: '',
        filled: true,
        fillColor: _C.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _C.navy, width: 1.6),
        ),
      ),
    );
  }
}

class _Encadre extends StatelessWidget {
  final List<Widget> children;
  const _Encadre({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Puce extends StatelessWidget {
  final String texte;
  final bool alerte;
  const _Puce({required this.texte, this.alerte = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alerte ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
            size: 16,
            color: alerte ? const Color(0xFFB0850B) : _C.navy,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(texte,
                style: TextStyle(
                  fontSize: 12.6,
                  height: 1.5,
                  color: alerte ? const Color(0xFFB0850B) : _C.muted,
                )),
          ),
        ],
      ),
    );
  }
}

class _Bascule extends StatelessWidget {
  final bool valeur;
  final String titre;
  final String texte;
  final ValueChanged<bool>? onChange;

  const _Bascule({
    required this.valeur,
    required this.titre,
    required this.texte,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final actif = onChange != null;
    return Opacity(
      opacity: actif ? 1 : 0.45,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: _C.text)),
                const SizedBox(height: 2),
                Text(texte,
                    style: const TextStyle(fontSize: 12.4, color: _C.muted, height: 1.45)),
              ],
            ),
          ),
          Switch(
            value: valeur,
            activeThumbColor: _C.navy,
            onChanged: onChange,
          ),
        ],
      ),
    );
  }
}

/// Croquis de la mise en page : la forme dit ce qu'un mot ne dit pas.
class _CroquisModele extends StatelessWidget {
  final String modele;
  final bool actif;
  const _CroquisModele({required this.modele, required this.actif});

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? _C.navy : const Color(0xFFB9C4D8);

    Widget bloc({double? h, double? w}) => Container(
          height: h, width: w,
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(2.5),
          ),
        );

    Widget contenu;
    switch (modele) {
      case 'galerie':
        contenu = Column(
          children: [
            bloc(h: 18, w: double.infinity),
            const SizedBox(height: 3),
            Row(children: [
              Expanded(child: bloc(h: 11)),
              const SizedBox(width: 3),
              Expanded(child: bloc(h: 11)),
            ]),
          ],
        );
        break;
      case 'catalogue':
        contenu = Column(
          children: List.generate(
            4,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i == 3 ? 0 : 3),
              child: bloc(h: 6, w: double.infinity),
            ),
          ),
        );
        break;
      default:
        contenu = Row(children: [
          Expanded(child: bloc(h: 32)),
          const SizedBox(width: 3),
          Expanded(child: bloc(h: 32)),
          const SizedBox(width: 3),
          Expanded(child: bloc(h: 32)),
        ]);
    }

    return Container(
      width: 52, height: 44,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: actif ? Colors.white : _C.bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: contenu,
    );
  }
}

/// Écran d'attente pendant la création.
///
/// Le texte dit ce qui se passe plutôt que de faire tourner un rond muet :
/// composer un site prend quelques secondes, et un vendeur qui ne sait pas ce
/// qu'on fait de son logo referme l'application.
class _EcranGeneration extends StatelessWidget {
  const _EcranGeneration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 42, height: 42,
              child: CircularProgressIndicator(strokeWidth: 3, color: _C.navy),
            ),
            const SizedBox(height: 26),
            const Text(
              'Nous composons votre site',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _C.text),
            ),
            const SizedBox(height: 10),
            Text(
              'Vos couleurs, votre mise en page, vos textes et votre catalogue '
              'sont assemblés. Encore quelques secondes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  color: _C.muted,
                  height: 1.55,
                  letterSpacing: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}
