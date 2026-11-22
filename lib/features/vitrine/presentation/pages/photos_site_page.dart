import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/police.dart';
import '../../../../core/widgets/image_reseau.dart';
import '../../../../core/widgets/messages.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/vitrine.dart';
import '../../domain/repositories/vitrine_repository.dart';

/// Palette locale, même convention que les autres écrans vendeur.
class _C {
  static const navy = Color(0xFF01154B);
  static const navyLight = Color(0xFFE8EDF7);
  static const bg = Color(0xFFF7F9FC);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E7F0);
  static const muted = Color(0xFF5B6C8A);
  static const danger = Color(0xFFC62828);
}

/// Les photos du haut du site.
///
/// Elles défilent toutes seules, en boucle, dans le grand bandeau de
/// l'accueil, dans l'ordre choisi ici ; sans photo, le bandeau prend les
/// couleurs de la boutique. Comme le reste de « Ma boutique », chaque geste
/// est enregistré tout de suite : pas de bouton « Enregistrer » à oublier.
///
/// [onModifie] prévient l'écran d'origine après chaque changement
/// enregistré, pour qu'il recharge son aperçu.
class PhotosSitePage extends StatefulWidget {
  final List<PhotoVitrine> photos;

  /// Le nombre de photos que le serveur accepte.
  final int max;

  final VoidCallback? onModifie;

  const PhotosSitePage({
    super.key,
    required this.photos,
    this.max = 10,
    this.onModifie,
  });

  @override
  State<PhotosSitePage> createState() => _PhotosSitePageState();
}

class _PhotosSitePageState extends State<PhotosSitePage> {
  late List<PhotoVitrine> _photos = widget.photos;
  late int _max = widget.max;

  /// Le geste en cours : 'ajout', 'ordre', ou l'identifiant de la photo
  /// qu'on retire. Un seul à la fois : deux envois croisés laisseraient
  /// l'écran sur la réponse du plus lent.
  String? _enCours;

  VitrineRepository get _depot => sl<VitrineRepository>();

  int get _reste => _max - _photos.length;

  void _appliquer(Vitrine v) {
    setState(() {
      _photos = v.photos;
      _max = v.photosMax;
    });
  }

  // ── Ajout ───────────────────────────────────────────────────────────

  Future<void> _ajouter() async {
    final reste = _reste;
    if (reste <= 0 || _enCours != null) return;
    final picker = ImagePicker();
    // Assez grandes pour un écran d'ordinateur, assez légères pour partir
    // vite sur un réseau mobile.
    List<XFile> choisies;
    try {
      if (reste == 1) {
        // Une seule place : une seule photo (les versions d'image_picker
        // antérieures à 1.2 refusent `limit: 1`).
        final x = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 82,
          maxWidth: 1920,
        );
        choisies = [if (x != null) x];
      } else {
        choisies = await picker.pickMultiImage(
          imageQuality: 82,
          maxWidth: 1920,
          limit: reste,
        );
      }
    } catch (_) {
      if (mounted) {
        afficherErreur(
          context,
          'Vos photos n\'ont pas pu être ouvertes. Vérifiez que SaamBiz a '
          'accès à votre galerie, puis réessayez.',
        );
      }
      return;
    }
    if (choisies.isEmpty || !mounted) return;

    // Certains téléphones ignorent la limite : on garde les premières.
    final enTrop = choisies.length - reste;
    if (enTrop > 0) choisies = choisies.take(reste).toList();

    // Pris avant l'envoi : le vendeur peut quitter l'écran pendant qu'il
    // part, l'aperçu doit tout de même se mettre à jour.
    final prevenir = widget.onModifie;
    setState(() => _enCours = 'ajout');
    final r = await _depot.ajouterPhotos(choisies.map((x) => x.path).toList());
    if (r.isRight()) prevenir?.call();
    if (!mounted) return;
    setState(() => _enCours = null);
    r.fold((f) => afficherErreur(context, f.errorMessage), (ok) {
      _appliquer(ok.vitrine);
      var message = ok.message.isNotEmpty
          ? ok.message
          : (choisies.length > 1
                ? 'Photos ajoutées à votre site.'
                : 'Photo ajoutée à votre site.');
      if (enTrop > 0) {
        message += enTrop > 1
            ? ' $enTrop photos n\'ont pas été ajoutées : $_max au plus.'
            : ' 1 photo n\'a pas été ajoutée : $_max au plus.';
      }
      afficherSucces(context, message);
    });
  }

  // ── Retrait ─────────────────────────────────────────────────────────

  Future<void> _retirer(PhotoVitrine p) async {
    if (_enCours != null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.white,
        title: const Text(
          'Retirer cette photo ?',
          style: TextStyle(
            fontFamily: kPolice,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _C.navy,
          ),
        ),
        content: Text(
          _photos.length > 1
              ? 'Elle disparaît du haut de votre site ; les autres '
                    'continuent de défiler.'
              : 'Elle disparaît du haut de votre site, qui reprend alors '
                    'vos couleurs.',
          style: const TextStyle(color: _C.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final prevenir = widget.onModifie;
    setState(() => _enCours = p.id);
    final r = await _depot.retirerPhoto(p.id);
    if (r.isRight()) prevenir?.call();
    if (!mounted) return;
    setState(() => _enCours = null);
    r.fold((f) => afficherErreur(context, f.errorMessage), (v) {
      _appliquer(v);
      afficherSucces(context, 'Photo retirée de votre site.');
    });
  }

  // ── Ordre ───────────────────────────────────────────────────────────

  /// [arrivee] est la place finale de la photo, une fois retirée de
  /// l'ancienne (`onReorderItem` fait déjà le calcul).
  Future<void> _ranger(int ancien, int arrivee) async {
    if (_enCours != null || arrivee == ancien) return;
    final avant = _photos;
    final apres = [...avant];
    apres.insert(arrivee, apres.removeAt(ancien));
    // Le nouvel ordre s'affiche tout de suite ; il est défait si le serveur
    // ne l'enregistre pas.
    final prevenir = widget.onModifie;
    setState(() {
      _photos = apres;
      _enCours = 'ordre';
    });
    final r = await _depot.ordonnerPhotos(apres.map((p) => p.id).toList());
    if (r.isRight()) prevenir?.call();
    if (!mounted) return;
    setState(() => _enCours = null);
    r.fold(
      (f) {
        setState(() => _photos = avant);
        afficherErreur(context, f.errorMessage);
      },
      (v) {
        _appliquer(v);
        afficherSucces(context, 'Ordre des photos enregistré.');
      },
    );
  }

  // ── Affichage ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final occupe = _enCours != null;
    return ScaffoldMarine(
      backgroundColor: _C.bg,
      appBar: AppBar(title: const Text('Photos du haut du site')),
      bottomNavigationBar: _BarreAjout(
        reste: _reste,
        max: _max,
        envoi: _enCours == 'ajout',
        onAjouter: occupe ? null : _ajouter,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 3,
            child: occupe
                ? const LinearProgressIndicator(
                    color: _C.navy,
                    backgroundColor: _C.navyLight,
                  )
                : null,
          ),
          Expanded(child: _photos.isEmpty ? const _AucunePhoto() : _liste()),
        ],
      ),
    );
  }

  Widget _liste() {
    final occupe = _enCours != null;
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      buildDefaultDragHandles: false,
      header: const _Explication(),
      itemCount: _photos.length,
      onReorderItem: _ranger,
      // La photo soulevée garde ses coins arrondis, avec une ombre sous la
      // carte seulement (pas sous l'espace qui la sépare de la suivante).
      proxyDecorator: (enfant, index, animation) => Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, enfant) {
            final t = Curves.easeOut.transform(animation.value);
            return Stack(
              children: [
                Positioned.fill(
                  bottom: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _C.navy.withValues(alpha: 0.2 * t),
                          blurRadius: 18 * t,
                          offset: Offset(0, 6 * t),
                        ),
                      ],
                    ),
                  ),
                ),
                if (enfant != null) enfant,
              ],
            );
          },
          child: enfant,
        ),
      ),
      itemBuilder: (context, i) {
        final p = _photos[i];
        return Padding(
          key: ValueKey(p.id),
          padding: const EdgeInsets.only(bottom: 10),
          // Un appui long n'importe où sur la carte la soulève aussi.
          child: ReorderableDelayedDragStartListener(
            index: i,
            enabled: !occupe,
            child: _LignePhoto(
              photo: p,
              index: i,
              occupe: occupe,
              retrait: _enCours == p.id,
              onRetirer: () => _retirer(p),
            ),
          ),
        );
      },
    );
  }
}

/// Le mode d'emploi, en tête de la liste.
class _Explication extends StatelessWidget {
  const _Explication();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.navyLight,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.view_carousel_outlined, color: _C.navy, size: 20),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Elles défilent toutes seules, en boucle, en haut de votre '
              'site, dans cet ordre. Pour en déplacer une, faites-la glisser '
              'avec la poignée.',
              style: TextStyle(color: _C.navy, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une photo de la liste : la poignée pour la déplacer, la vignette, sa
/// place dans le défilement et le bouton pour la retirer.
class _LignePhoto extends StatelessWidget {
  final PhotoVitrine photo;
  final int index;

  /// Un geste est en cours : rien ne bouge en attendant.
  final bool occupe;

  /// C'est cette photo qu'on est en train de retirer.
  final bool retrait;
  final VoidCallback onRetirer;

  const _LignePhoto({
    required this.photo,
    required this.index,
    required this.occupe,
    required this.retrait,
    required this.onRetirer,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: retrait ? 0.5 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.fromLTRB(2, 6, 4, 6),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              enabled: !occupe,
              child: Tooltip(
                message: 'Déplacer la photo ${index + 1}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 18,
                  ),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: occupe ? _C.border : _C.muted,
                  ),
                ),
              ),
            ),
            ImageReseau(
              photo.url,
              largeurServeur: 360,
              width: 112,
              height: 63,
              rayon: BorderRadius.circular(9),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo ${index + 1}',
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _C.navy,
                    ),
                  ),
                  if (index == 0) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'La première que voient vos clients',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _C.muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (retrait)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _C.danger,
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Retirer la photo ${index + 1}',
                onPressed: occupe ? null : onRetirer,
                color: _C.danger,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

/// Aucune photo encore : ce que deviennent les photos, et lesquelles choisir.
class _AucunePhoto extends StatelessWidget {
  const _AucunePhoto();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.navyLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: _C.navy,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Aucune photo pour l\'instant',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kPolice,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _C.navy,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Le haut de votre site prend vos couleurs. Ajoutez des photos de '
          'votre boutique, de vos produits mis en scène ou de votre équipe : '
          'elles y défileront toutes seules, en boucle.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13.5, height: 1.5),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _C.border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.crop_landscape_rounded, color: _C.navy, size: 20),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Préférez des photos en largeur (paysage) : sur votre '
                  'site, le texte se pose sur leur partie gauche.',
                  style: TextStyle(color: _C.navy, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Le bouton d'ajout, toujours à portée de pouce, avec les places restantes.
class _BarreAjout extends StatelessWidget {
  final int reste;
  final int max;

  /// Des photos sont en train de partir.
  final bool envoi;
  final VoidCallback? onAjouter;

  const _BarreAjout({
    required this.reste,
    required this.max,
    required this.envoi,
    this.onAjouter,
  });

  @override
  Widget build(BuildContext context) {
    final plein = reste <= 0;
    return Material(
      color: _C.white,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _C.border)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _C.navy,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: plein ? null : onAjouter,
                icon: envoi
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _C.muted,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: Text(
                  envoi ? 'Envoi en cours…' : 'Ajouter des photos',
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plein
                    ? '$max photos, c\'est le maximum : retirez-en une pour '
                          'en ajouter une autre.'
                    : reste == max
                    ? 'Jusqu\'à $max photos, JPEG ou PNG.'
                    : 'Encore $reste photo${reste > 1 ? 's' : ''} '
                          'possible${reste > 1 ? 's' : ''}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _C.muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
