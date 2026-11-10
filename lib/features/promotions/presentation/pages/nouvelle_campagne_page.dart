import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:dio/dio.dart';
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
      _titre.text = 'Promotion -${_pourcentage.round()} %';
      _message.text =
          'Profitez de -${_pourcentage.round()} % sur une sélection de produits, pendant $_duree jour${_duree > 1 ? 's' : ''} seulement !';
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

  Future<void> _envoyer() async {
    FocusScope.of(context).unfocus();
    String? probleme;
    if (_type == TypeCampagne.promotion && _produitsChoisis.isEmpty)
      probleme = 'Choisissez au moins un produit.';
    if (_titre.text.trim().isEmpty)
      probleme ??= 'Donnez un titre à votre message.';
    if (_message.text.trim().isEmpty)
      probleme ??= 'Écrivez le message à envoyer.';
    if (!_tous && _clientsChoisis.isEmpty)
      probleme ??= 'Choisissez au moins un client.';
    if (probleme != null) {
      _snack(probleme);
      return;
    }
    setState(() => _envoi = true);
    try {
      final res = await _dio.post(
        '/promotions/campagne',
        data: {
          'type': _type == TypeCampagne.promotion ? 'promotion' : 'information',
          'titre': _titre.text.trim(),
          'message': _message.text.trim(),
          if (_type == TypeCampagne.promotion) ...{
            'produitIds': _produitsChoisis.toList(),
            'pourcentage': _pourcentage.round(),
            'dureeJours': _duree,
          },
          'destinataires': _tous ? 'tous' : _clientsChoisis.toList(),
        },
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
          style: TextStyle(fontFamily: kPolice, fontSize: 17, fontWeight: FontWeight.w700),
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
                _carte(
                  titre: 'Votre message',
                  enfant: Column(
                    children: [
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
                        maxLength: 500,
                        minLines: 3,
                        maxLines: 6,
                        decoration: _deco(
                          'Message',
                          'Ce que vos clients liront dans la notification',
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionDestinataires(),
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
                    _type == TypeCampagne.promotion
                        ? 'Créer et notifier'
                        : 'Envoyer',
                    style: TextStyle(fontFamily: kPolice, 
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
                              ? ImageReseau(p.image, largeurServeur: 120, fit: BoxFit.cover)
                              : Container(
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
                        style: TextStyle(fontFamily: kPolice, 
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
                        style: TextStyle(fontFamily: kPolice, fontSize: 12),
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
            title: Text(
              'Tous mes abonnés',
              style: TextStyle(fontFamily: kPolice, fontWeight: FontWeight.w600),
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
            title: Text(
              'Choisir les clients',
              style: TextStyle(fontFamily: kPolice, fontWeight: FontWeight.w600),
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
                  style: TextStyle(fontFamily: kPolice, fontSize: 14),
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
  TextStyle _discret() =>
      TextStyle(fontFamily: kPolice, fontSize: 12, color: AppColor.kGrayscale40);

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

  Widget _carte({required String titre, required Widget enfant}) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: AppColor.kWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColor.kLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: TextStyle(fontFamily: kPolice, 
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
        const SizedBox(height: 8),
        enfant,
      ],
    ),
  );
}
