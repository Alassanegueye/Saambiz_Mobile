import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/widgets/image_produit.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/presentation/widgets/produit_card.dart'
    show formaterPrix;
import '../../../home/data/models/produit_model.dart';
import '../../../vendeur/data/datasources/vendeur_produit_datasource.dart';
import '../../data/models/promotion_model.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';
import '../../../../core/utils/dates.dart';

/// Le prix tel qu'on le saisit : « 14900 », pas « 14900.0 ».
String prixSaisi(double prix) =>
    prix == prix.roundToDouble() ? prix.toStringAsFixed(0) : prix.toString();

/// Le nombre de jours entre deux dates du calendrier, bornes comprises
/// (du 18 au 25 : 8 jours).
int joursDePromo(DateTime debut, DateTime fin) =>
    DateTime(
      fin.year,
      fin.month,
      fin.day,
    ).difference(DateTime(debut.year, debut.month, debut.day)).inDays +
    1;

/// Création (POST /promotions) ou modification (PUT /promotions/:id) d'une
/// promotion vendeur.
class PromotionFormPage extends StatelessWidget {
  final PromotionModel? promotion; // null = création
  const PromotionFormPage({super.key, this.promotion});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PromotionsBloc>(),
      child: _PromotionFormView(promotion: promotion),
    );
  }
}

class _PromotionFormView extends StatefulWidget {
  final PromotionModel? promotion;
  const _PromotionFormView({this.promotion});
  @override
  State<_PromotionFormView> createState() => _PromotionFormViewState();
}

class _PromotionFormViewState extends State<_PromotionFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _titreCtrl = TextEditingController(
    text: widget.promotion?.titre ?? '',
  );
  late final _descCtrl = TextEditingController(
    text: widget.promotion?.description ?? '',
  );
  // « 14900 » et non « 14900.0 », que le champ affichait en modification.
  late final _prixCtrl = TextEditingController(
    text: widget.promotion != null
        ? prixSaisi(widget.promotion!.prixPromo)
        : '',
  );
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 7));
  String? _produitId;
  List<ProduitModel> _produits = [];
  bool _loadingProduits = true;

  bool get _isEdit => widget.promotion != null;

  /// Le produit visé : celui de la promotion en modification, sinon celui
  /// choisi dans la liste. Nul tant qu'il n'est pas connu.
  ({String nom, String? image, double? prix})? get _produit {
    final promo = widget.promotion;
    if (promo != null) {
      return (
        nom: promo.produitNom ?? '',
        image: promo.produitImage,
        prix: promo.produitPrix,
      );
    }
    for (final p in _produits) {
      if (p.id == _produitId) {
        return (nom: p.nom, image: p.image, prix: double.tryParse(p.prix));
      }
    }
    return null;
  }

  double? get _prixPromo =>
      double.tryParse(_prixCtrl.text.trim().replaceAll(RegExp(r'\s'), ''));

  @override
  void initState() {
    super.initState();
    if (widget.promotion?.dateDebut != null) {
      _dateDebut = widget.promotion!.dateDebut!;
    }
    if (widget.promotion?.dateFin != null) {
      _dateFin = widget.promotion!.dateFin!;
    }
    _produitId = widget.promotion?.produitId;
    _chargerProduits();
  }

  Future<void> _chargerProduits() async {
    try {
      final produits = await sl<VendeurProduitDataSource>().tousMesProduits();
      setState(() {
        _produits = produits;
        _loadingProduits = false;
      });
    } catch (_) {
      setState(() => _loadingProduits = false);
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate({required bool debut}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: debut ? _dateDebut : _dateFin,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (debut) {
          _dateDebut = date;
        } else {
          _dateFin = date;
        }
      });
    }
  }

  void _soumettre() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && (_produitId == null || _produitId!.isEmpty)) {
      afficherErreur(context, 'Choisissez un produit');
      return;
    }
    // La règle du serveur, dite avant l'envoi plutôt qu'après.
    if (!_dateFin.isAfter(_dateDebut)) {
      afficherErreur(context, 'La date de fin doit suivre la date de début');
      return;
    }
    final bloc = context.read<PromotionsBloc>();
    final isoDebut = dateIso.format(_dateDebut);
    final isoFin = dateIso.format(_dateFin);
    final num prix = _prixPromo ?? 0;
    if (_isEdit) {
      bloc.add(
        ModifierPromotion(
          widget.promotion!.id,
          titre: _titreCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          prixPromo: prix,
          dateDebut: isoDebut,
          dateFin: isoFin,
        ),
      );
    } else {
      bloc.add(
        CreerPromotion(
          titre: _titreCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          prixPromo: prix,
          dateDebut: isoDebut,
          dateFin: isoFin,
          produitId: _produitId!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final produit = _produit;
    final remise = remiseEnPourcent(produit?.prix, _prixPromo);
    final jours = joursDePromo(_dateDebut, _dateFin);
    return ScaffoldMarine(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la promotion' : 'Nouvelle promotion'),
      ),
      body: BlocConsumer<PromotionsBloc, PromotionsState>(
        listener: (context, state) {
          if (state is PromotionsError) {
            afficherErreur(context, state.message);
          } else if (state is PromotionsLoaded) {
            afficherSucces(
              context,
              _isEdit
                  ? 'Promotion mise à jour avec succès'
                  : 'Promotion créée avec succès',
            );
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final loading = state is PromotionsLoading;
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                if (!_isEdit) ...[
                  _loadingProduits
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<String>(
                          initialValue: _produitId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            label: LibelleObligatoire('Produit'),
                          ),
                          items: _produits
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.nom),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _produitId = v),
                        ),
                  const SizedBox(height: 12),
                ],
                // Le produit en promotion : la modification ne disait pas
                // lequel, ni son prix normal.
                if (produit != null) ...[
                  _CarteProduit(
                    nom: produit.nom,
                    image: produit.image,
                    prix: produit.prix,
                    remise: remise,
                  ),
                  const SizedBox(height: 16),
                ],
                _input(_titreCtrl, 'Titre de la promotion'),
                const SizedBox(height: 12),
                _input(_descCtrl, 'Description', maxLines: 3),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prixCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (_) {
                    final prix = _prixPromo;
                    if (prix == null || prix <= 0) {
                      return 'Indiquez le prix promo';
                    }
                    final normal = produit?.prix;
                    if (normal != null && prix >= normal) {
                      return 'Le prix promo doit être inférieur à '
                          '${formaterPrix(normal)}';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    label: const LibelleObligatoire('Prix promo'),
                    suffixText: 'FCFA',
                    helperText: remise != null && produit?.prix != null
                        ? 'Soit -$remise % sur ${formaterPrix(produit!.prix!)}'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ChampDate(
                        libelle: 'Début',
                        date: _dateDebut,
                        onTap: () => _choisirDate(debut: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ChampDate(
                        libelle: 'Fin',
                        date: _dateFin,
                        onTap: () => _choisirDate(debut: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _dateFin.isAfter(_dateDebut)
                        ? 'Durée : $jours jours'
                        : 'La date de fin doit suivre la date de début',
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 12.5,
                      color: _dateFin.isAfter(_dateDebut)
                          ? AppColor.kGrayscale40
                          : AppColor.kErreur,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: loading ? null : _soumettre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kPrimary,
                    foregroundColor: AppColor.kWhite,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit
                              ? 'Enregistrer les modifications'
                              : 'Créer la promotion',
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? '$label requis' : null,
      decoration: InputDecoration(label: LibelleObligatoire(label)),
    );
  }
}

/// Le produit en promotion : photo, nom, prix normal, et la remise que
/// donne le prix promo saisi.
class _CarteProduit extends StatelessWidget {
  final String nom;
  final String? image;
  final double? prix;
  final int? remise;
  const _CarteProduit({
    required this.nom,
    required this.image,
    required this.prix,
    required this.remise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.kLine),
      ),
      child: Row(
        children: [
          ImageProduit(image, cote: 60, largeurServeur: 180),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom.isEmpty ? 'Produit' : nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                if (prix != null)
                  Text(
                    'Prix normal : ${formaterPrix(prix!)}',
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 12.5,
                      color: AppColor.kGrayscale40,
                    ),
                  ),
              ],
            ),
          ),
          if (remise != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.kSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '-$remise %',
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Une date à toucher, présentée comme un champ du formulaire.
class _ChampDate extends StatelessWidget {
  final String libelle;
  final DateTime date;
  final VoidCallback onTap;
  const _ChampDate({
    required this.libelle,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: libelle,
          prefixIcon: const Icon(Icons.event_outlined, size: 20),
        ),
        child: Text(
          dateCourte.format(date),
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
      ),
    );
  }
}
