import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';
import '../../../abonnes/abonnes_page.dart';

/// Ce que le vendeur envoie à ses abonnés.
enum TypeCampagne { promotion, information }

/// Modèles de message proposés pour une information.
const _modelesInformation = <(String, IconData, String, String)>[
  (
    'ouverte',
    Icons.storefront_outlined,
    'Boutique ouverte',
    'Nous sommes ouverts ! Passez nous voir ou commandez directement dans l\'application.',
  ),
  (
    'nouveautes',
    Icons.new_releases_outlined,
    'Nouveaux produits',
    'De nouveaux produits viennent d\'arriver dans la boutique. Venez les découvrir !',
  ),
  ('perso', Icons.edit_note_rounded, 'Message libre', ''),
];

const _durees = [1, 3, 7, 14, 30];

class _ProduitChoix {
  final String id;
  final String nom;
  final double prix;
  final String image;
  const _ProduitChoix(this.id, this.nom, this.prix, this.image);
}

/// Créer une promotion (remise sur des produits, pour une durée) ou envoyer
/// une simple information (boutique ouverte, nouveaux produits, message
/// libre) aux abonnés : tous, ou ceux que le vendeur choisit. Seuls les
/// abonnés qui ont activé la cloche de la boutique la reçoivent.
class NouvelleCampagnePage extends StatefulWidget {
  final TypeCampagne type;

  /// Produit déjà coché à l'ouverture (« Mettre en promo » depuis la boutique).
  final String? produitId;
  const NouvelleCampagnePage({
    super.key,
    this.type = TypeCampagne.promotion,
    this.produitId,
  });

  @override
  State<NouvelleCampagnePage> createState() => _NouvelleCampagnePageState();
}

class _NouvelleCampagnePageState extends State<NouvelleCampagnePage> {
  final _dio = sl<Dio>();
  final _titre = TextEditingController();
  final _message = TextEditingController();
  final _francs = NumberFormat.decimalPattern('fr_FR');

  late TypeCampagne _type = widget.type;
  String _modele = 'ouverte';

  // Promotion
  List<_ProduitChoix>? _produits;
  late final Set<String> _produitsChoisis = {
    if (widget.produitId != null) widget.produitId!,
  };
  double _pourcentage = 10;
  int _duree = 7;

  // Destinataires
  List<Abonne>? _abonnes;
  bool _tous = true;
  final Set<String> _clientsChoisis = {};

  bool _envoi = false;

  /// Promotion : prévenir les clients (cloche active) avec un message écrit
  /// par le vendeur. Une information, elle, est toujours envoyée.
  bool _notifier = true;

  /// Image jointe à la notification (facultative), envoyée sur Cloudinary.
  File? _image;

  bool get _avecMessage => _type == TypeCampagne.information || _notifier;

  @override
  void initState() {
    super.initState();
    _appliquerModele();
    _chargerProduits();
    AbonnesService.charger()
        .then((l) {
          if (mounted) setState(() => _abonnes = l);
        })
        .catchError((_) {
          if (mounted) setState(() => _abonnes = const []);
        });
  }

  @override
  void dispose() {
    _titre.dispose();
    _message.dispose();
    super.dispose();
  }

  void _appliquerModele() {
    if (_type == TypeCampagne.promotion) {
      // Le titre est proposé ; le message, le vendeur l'écrit lui-même
      // (une suggestion reste à un geste, sous le champ).
      _titre.text = 'Promotion -${_pourcentage.round()} %';
      return;
    }
    final m = _modelesInformation.firstWhere((x) => x.$1 == _modele);
    if (m.$1 == 'perso') {
      _titre.clear();
      _message.clear();
    } else {
      _titre.text = m.$3;
      _message.text = m.$4;
    }
  }

  Future<void> _chargerProduits() async {
    try {
      final res = await _dio.get(
        '/vendeur/liste-produits',
        queryParameters: {'limit': 200},
      );
      final brut = res.data;
      List liste = const [];
      if (brut is List) {
        liste = brut;
      } else if (brut is Map) {
        for (final k in ['produits', 'data', 'items']) {
          final v = brut[k];
          if (v is List) {
            liste = v;
            break;
          }
          if (v is Map && v['produits'] is List) {
            liste = v['produits'] as List;
            break;
          }
        }
      }
      final produits = liste
          .whereType<Map>()
          .map((p) {
            final prix = p['prix'];
            return _ProduitChoix(
              p['id']?.toString() ?? '',
              p['nom']?.toString() ?? 'Produit',
              prix is num
                  ? prix.toDouble()
                  : double.tryParse('${prix ?? ''}') ?? 0,
              (p['image'] ?? '').toString(),
            );
          })
          .where((p) => p.id.isNotEmpty)
          .toList();
      if (mounted) setState(() => _produits = produits);
    } catch (_) {
      if (mounted) setState(() => _produits = const []);
    }
  }

  String _prix(double v) => '${_francs.format(v.round())} FCFA';

  String get _suggestionPromo =>
      'Profitez de -${_pourcentage.round()} % sur une sélection de produits, '
      'pendant $_duree jour${_duree > 1 ? 's' : ''} seulement !';

  Future<void> _choisirImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (x != null && mounted) setState(() => _image = File(x.path));
  }

  Future<void> _envoyer() async {
    FocusScope.of(context).unfocus();
    String? probleme;
    if (_type == TypeCampagne.promotion && _produitsChoisis.isEmpty) {
      probleme = 'Choisissez au moins un produit.';
    }
    if (_avecMessage && _titre.text.trim().isEmpty) {
      probleme ??= 'Donnez un titre à votre message.';
    }
    if (_avecMessage && _message.text.trim().isEmpty) {
      probleme ??= 'Écrivez le message que vos clients recevront.';
    }
    if (_avecMessage && !_tous && _clientsChoisis.isEmpty) {
      probleme ??= 'Choisissez au moins un client.';
    }
    if (probleme != null) {
      _snack(probleme);
      return;
    }
    setState(() => _envoi = true);
    try {
      final promo = _type == TypeCampagne.promotion;
      final champs = <String, dynamic>{
        'type': promo ? 'promotion' : 'information',
        'notifier': _avecMessage,
        'titre': _titre.text.trim(),
        if (_avecMessage) 'message': _message.text.trim(),
        if (promo) ...{
          'produitIds': _produitsChoisis.toList(),
          'pourcentage': _pourcentage.round(),
          'dureeJours': _duree,
        },
        'destinataires': _tous ? 'tous' : _clientsChoisis.toList(),
      };
      final image = _avecMessage ? _image : null;
      // Avec une image : envoi en plusieurs parties (le serveur la dépose sur
      // Cloudinary) ; les listes voyagent alors en JSON.
      final res = await _dio.post(
        '/promotions/campagne',
        data: image == null
            ? champs
            : FormData.fromMap({
                for (final e in champs.entries)
                  e.key: e.value is List ? jsonEncode(e.value) : '${e.value}',
                'image': await MultipartFile.fromFile(
                  image.path,
                  filename: image.path.split(Platform.pathSeparator).last,
                ),
              }),
      );
      if (!mounted) return;
      final message = res.data is Map
          ? (res.data['message'] ?? 'Envoyé.').toString()
          : 'Envoyé.';
      _snack(message);
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      _snack(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Envoi impossible. Vérifiez votre connexion.',
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _snack(String texte) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(texte), behavior: SnackBarBehavior.floating),
      );
  }

  // Écran
  @override
  Widget build(BuildContext context) {
    return ScaffoldMarine(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: Text(
          _type == TypeCampagne.promotion
              ? 'Nouvelle promotion'
              : 'Informer mes clients',
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // Le bouton fait partie du corps : un `bottomNavigationBar` reste sous le
      // clavier, et il devenait impossible d'envoyer.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                SegmentedButton<TypeCampagne>(
                  segments: const [
                    ButtonSegment(
                      value: TypeCampagne.promotion,
                      icon: Icon(Icons.local_offer_outlined),
                      label: Text('Promotion'),
                    ),
                    ButtonSegment(
                      value: TypeCampagne.information,
                      icon: Icon(Icons.campaign_outlined),
                      label: Text('Information'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() {
                    _type = s.first;
                    _appliquerModele();
                  }),
                ),
                const SizedBox(height: 16),
                if (_type == TypeCampagne.promotion)
                  ..._sectionPromotion()
                else
                  _sectionInformation(),
                if (_type == TypeCampagne.promotion) _carteNotifier(),
                if (_avecMessage)
                _carte(
                  titre: 'Votre message',
                  enfant: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Personnalisez le message : c\'est exactement ce que '
                        'vos clients liront dans la notification.',
                        style: _discret(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titre,
                        maxLength: 80,
                        decoration: _deco(
                          'Titre',
                          'Ex. : Soldes de fin de mois',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _message,
                        onChanged: (_) => setState(() {}),
                        maxLength: 500,
                        minLines: 3,
                        maxLines: 6,
                        decoration: _deco(
                          'Message',
                          'Ex. : -20 % sur toute la collection jusqu\'à dimanche !',
                        ),
                      ),
                      if (_type == TypeCampagne.promotion &&
                          _message.text.trim().isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(
                              () => _message.text = _suggestionPromo,
                            ),
                            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                            label: const Text('Utiliser une suggestion'),
                          ),
                        ),
                      const SizedBox(height: 6),
                      _choixImage(),
                    ],
                  ),
                ),
                if (_avecMessage) _sectionDestinataires(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _envoi ? null : _envoyer,
                  icon: _envoi
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColor.kWhite,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _type == TypeCampagne.information
                        ? 'Envoyer'
                        : _notifier
                        ? 'Créer et notifier mes clients'
                        : 'Créer la promotion',
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kPrimary,
                    foregroundColor: AppColor.kWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sectionPromotion() {
    final produits = _produits;
    return [
      _carte(
        titre: 'Produits concernés (${_produitsChoisis.length})',
        enfant: produits == null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColor.kPrimary,
                  ),
                ),
              )
            : produits.isEmpty
            ? Text('Vous n\'avez pas encore de produit.', style: _discret())
            : Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() {
                        if (_produitsChoisis.length == produits.length) {
                          _produitsChoisis.clear();
                        } else {
                          _produitsChoisis.addAll(produits.map((p) => p.id));
                        }
                      }),
                      child: Text(
                        _produitsChoisis.length == produits.length
                            ? 'Tout décocher'
                            : 'Tout cocher',
                      ),
                    ),
                  ),
                  for (final p in produits)
                    CheckboxListTile(
                      value: _produitsChoisis.contains(p.id),
                      onChanged: (v) => setState(
                        () => v == true
                            ? _produitsChoisis.add(p.id)
                            : _produitsChoisis.remove(p.id),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      secondary: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: p.image.isNotEmpty
                              ? ImageReseau(
                                  p.image,
                                  largeurServeur: 120,
                                  fit: BoxFit.cover,
                                )
                              : ColoredBox(
                                  color: AppColor.kPrimaryLight,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 18,
                                  ),
                                ),
                        ),
                      ),
                      title: Text(
                        p.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _prix(p.prix),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '  ${_prix(p.prix * (1 - _pourcentage / 100))}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColor.kSucces,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
      ),
      _carte(
        titre: 'Remise : -${_pourcentage.round()} %',
        enfant: Slider(
          value: _pourcentage,
          min: 5,
          max: 90,
          divisions: 17,
          label: '-${_pourcentage.round()} %',
          activeColor: AppColor.kPrimary,
          onChanged: (v) => setState(() {
            final avant = _titre.text == 'Promotion -${_pourcentage.round()} %';
            _pourcentage = v;
            if (avant) _appliquerModele();
          }),
        ),
      ),
      _carte(
        titre: 'Durée',
        enfant: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _durees)
              ChoiceChip(
                label: Text('$d jour${d > 1 ? 's' : ''}'),
                selected: _duree == d,
                onSelected: (_) => setState(() => _duree = d),
              ),
          ],
        ),
      ),
    ];
  }

  /// Le bouton « Notifier mes clients » d'une promotion.
  Widget _carteNotifier() {
    return _carte(
      titre: 'Prévenir mes clients',
      enfant: SwitchListTile.adaptive(
        value: _notifier,
        onChanged: (v) => setState(() => _notifier = v),
        contentPadding: EdgeInsets.zero,
        activeTrackColor: AppColor.kPrimary,
        secondary: Icon(
          _notifier
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          color: AppColor.kPrimary,
        ),
        title: const Text(
          'Notifier mes clients',
          style: TextStyle(fontFamily: kPolice, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          _notifier
              ? 'Vos abonnés qui ont activé la cloche recevront votre message.'
              : 'La promotion est créée sans prévenir personne.',
          style: _discret(),
        ),
      ),
    );
  }

  /// Image facultative jointe à la notification.
  Widget _choixImage() {
    final image = _image;
    if (image == null) {
      return OutlinedButton.icon(
        onPressed: _choisirImage,
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
        label: const Text('Ajouter une image (facultatif)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.kPrimary,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            image,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Retirer l\'image',
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => setState(() => _image = null),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionInformation() {
    return _carte(
      titre: 'Que voulez-vous annoncer ?',
      enfant: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final m in _modelesInformation)
            ChoiceChip(
              avatar: Icon(m.$2, size: 18),
              label: Text(m.$3),
              selected: _modele == m.$1,
              onSelected: (_) => setState(() {
                _modele = m.$1;
                _appliquerModele();
              }),
            ),
        ],
      ),
    );
  }

  Widget _sectionDestinataires() {
    final abonnes = _abonnes;
    final avecCloche =
        abonnes?.where((a) => a.clocheActive).toList() ?? const <Abonne>[];
    return _carte(
      titre: 'Clients à notifier',
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<bool>(
            value: true,
            groupValue: _tous,
            onChanged: (v) => setState(() => _tous = true),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tous mes abonnés',
              style: TextStyle(
                fontFamily: kPolice,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              abonnes == null
                  ? 'Chargement…'
                  : '${avecCloche.length} reçoivent vos notifications',
              style: _discret(),
            ),
          ),
          RadioListTile<bool>(
            value: false,
            groupValue: _tous,
            onChanged: (v) => setState(() => _tous = false),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Choisir les clients',
              style: TextStyle(
                fontFamily: kPolice,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!_tous && abonnes != null)
            for (final a in abonnes)
              CheckboxListTile(
                value: _clientsChoisis.contains(a.id),
                onChanged: a.clocheActive
                    ? (v) => setState(
                        () => v == true
                            ? _clientsChoisis.add(a.id)
                            : _clientsChoisis.remove(a.id),
                      )
                    : null,
                contentPadding: const EdgeInsets.only(left: 12),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  a.nomComplet,
                  style: const TextStyle(fontFamily: kPolice, fontSize: 14),
                ),
                subtitle: a.clocheActive
                    ? null
                    : Text(
                        'Cloche désactivée : ne reçoit pas vos notifications',
                        style: _discret(),
                      ),
              ),
          const SizedBox(height: 4),
          Text(
            'Seuls les abonnés qui ont activé la cloche de votre boutique sont notifiés.',
            style: _discret(),
          ),
        ],
      ),
    );
  }

  // Petits outils
  TextStyle _discret() => const TextStyle(
    fontFamily: kPolice,
    fontSize: 12,
    color: AppColor.kGrayscale40,
  );

  InputDecoration _deco(String libelle, String indication) => InputDecoration(
    label: LibelleObligatoire(libelle),
    hintText: indication,
    filled: true,
    fillColor: AppColor.kWhite,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColor.kLine),
    ),
  );

  // Un Material (et non un Container coloré) : les cases et boutons radio
  // dessinent leur effet de toucher dessus.
  Widget _carte({required String titre, required Widget enfant}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
    color: AppColor.kWhite,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColor.kLine),
    ),
    child: Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
        const SizedBox(height: 8),
        enfant,
      ],
    ),
    ),
    ),
  );
}
