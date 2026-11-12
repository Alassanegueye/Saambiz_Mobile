import 'package:saambiz/core/widgets/messages.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/utils/telephone.dart';
import '../../../../core/widgets/bouton_indicatif.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../../../vendeur/data/datasources/vendeur_produit_datasource.dart';
import '../../data/datasources/commande_remote_datasource.dart';

/// Saisie d'une commande prise hors de l'application (téléphone, WhatsApp,
/// en boutique…). Le vendeur renseigne le client, choisit ses produits et
/// leurs quantités ; la commande est enregistrée confirmée, stock réservé.
class NouvelleCommandeVendeurPage extends StatefulWidget {
  const NouvelleCommandeVendeurPage({super.key});

  @override
  State<NouvelleCommandeVendeurPage> createState() =>
      _NouvelleCommandeVendeurPageState();
}

class _NouvelleCommandeVendeurPageState
    extends State<NouvelleCommandeVendeurPage> {
  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _paysTel = ValueNotifier<PaysTelephone>(senegal);
  final _adresseCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _rechercheCtrl = TextEditingController();

  List<ProduitModel> _produits = [];
  bool _chargement = true;
  String? _erreurProduits;
  final Map<String, int> _quantites = {};
  String _modeLivraison = 'retrait';
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _chargerProduits();
    _rechercheCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _prenomCtrl,
      _nomCtrl,
      _telCtrl,
      _adresseCtrl,
      _noteCtrl,
      _rechercheCtrl,
    ]) {
      c.dispose();
    }
    _paysTel.dispose();
    super.dispose();
  }

  Future<void> _chargerProduits() async {
    setState(() {
      _chargement = true;
      _erreurProduits = null;
    });
    try {
      final produits = await sl<VendeurProduitDataSource>().mesProduits();
      if (!mounted) return;
      setState(() {
        _produits = produits;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreurProduits = 'Impossible de charger vos produits.';
      });
    }
  }

  double _prix(ProduitModel p) =>
      double.tryParse(p.prix.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  double get _total => _quantites.entries.fold(0, (somme, e) {
    final p = _produits.where((x) => x.id == e.key).firstOrNull;
    return p == null ? somme : somme + _prix(p) * e.value;
  });

  int get _nbArticles => _quantites.values.fold(0, (a, b) => a + b);

  String _fcfa(num v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '$b FCFA';
  }

  void _changerQuantite(ProduitModel p, int delta) {
    final actuelle = _quantites[p.id] ?? 0;
    // Le vendeur peut commander au-delà du stock, rupture comprise : il sait
    // ce qu'il a réellement (réassort, stock non saisi…).
    final nouvelle = (actuelle + delta).clamp(0, 9999);
    setState(() {
      if (nouvelle == 0) {
        _quantites.remove(p.id);
      } else {
        _quantites[p.id] = nouvelle;
      }
    });
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quantites.isEmpty) {
      afficherErreur(
        context,
        'Ajoutez au moins un produit à la commande.',
        titre: 'Aucun produit',
      );
      return;
    }
    setState(() => _envoi = true);
    try {
      await sl<CommandeRemoteDataSource>().creerCommandeVendeur({
        'client': {
          'prenom': _prenomCtrl.text.trim(),
          'nom': _nomCtrl.text.trim(),
          'telephone': telephoneInternational(_telCtrl.text, _paysTel.value),
        },
        'items': [
          for (final e in _quantites.entries)
            {'produitId': e.key, 'quantite': e.value},
        ],
        'modeLivraison': _modeLivraison,
        if (_modeLivraison == 'livraison')
          'adresseLivraison': _adresseCtrl.text.trim(),
        if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
      });
      if (!mounted) return;
      afficherSucces(
        context,
        'Commande enregistrée : elle apparaît dans vos commandes en cours.',
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Vérifiez votre connexion et réessayez.';
      afficherErreur(context, message, titre: 'Échec');
    } catch (_) {
      if (!mounted) return;
      afficherErreur(
        context,
        'La commande n\'a pas pu être enregistrée.',
        titre: 'Échec',
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Nouvelle commande',
      corps: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                children: [
                  const _TitreSection('Client'),
                  _Carte(
                    child: Column(
                      children: [
                        _champ(
                          _prenomCtrl,
                          'Prénom',
                          icone: Icons.person_outline_rounded,
                          requis: true,
                          capitalisation: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        _champ(
                          _nomCtrl,
                          'Nom (facultatif)',
                          icone: Icons.badge_outlined,
                          capitalisation: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        _champ(
                          _telCtrl,
                          'Téléphone',
                          icone: Icons.phone_outlined,
                          requis: true,
                          clavier: TextInputType.phone,
                          formats: [FormatTelephone(_paysTel)],
                          prefixe: BoutonIndicatif(
                            pays: _paysTel,
                            onChange: () => setState(_telCtrl.clear),
                          ),
                          verifier: (v) => verifierTelephone(v, _paysTel.value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _TitreSection(
                    'Produits',
                    complement: _nbArticles > 0
                        ? '$_nbArticles article${_nbArticles > 1 ? 's' : ''}'
                        : null,
                  ),
                  _blocProduits(),
                  const SizedBox(height: 22),
                  const _TitreSection('Remise au client'),
                  _Carte(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'retrait',
                              label: Text('Retrait'),
                              icon: Icon(Icons.storefront_outlined),
                            ),
                            ButtonSegment(
                              value: 'livraison',
                              label: Text('Livraison'),
                              icon: Icon(Icons.local_shipping_outlined),
                            ),
                          ],
                          selected: {_modeLivraison},
                          showSelectedIcon: false,
                          onSelectionChanged: (v) =>
                              setState(() => _modeLivraison = v.first),
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppColor.kPrimary,
                            selectedForegroundColor: AppColor.kWhite,
                            textStyle: const TextStyle(
                              fontFamily: kPolice,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_modeLivraison == 'livraison') ...[
                          const SizedBox(height: 12),
                          _champ(
                            _adresseCtrl,
                            'Adresse de livraison',
                            icone: Icons.place_outlined,
                            requis: true,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _champ(
                          _noteCtrl,
                          'Note (facultatif)',
                          icone: Icons.notes_rounded,
                          lignes: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _barreValidation(context),
          ],
        ),
      ),
    );
  }

  Widget _blocProduits() {
    if (_chargement) {
      return const _Carte(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_erreurProduits != null) {
      return _Carte(
        child: Column(
          children: [
            Text(
              _erreurProduits!,
              style: const TextStyle(color: AppColor.kErreur),
            ),
            TextButton(
              onPressed: _chargerProduits,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_produits.isEmpty) {
      return const _Carte(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Ajoutez d\'abord des produits à votre catalogue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF5B6C8A)),
          ),
        ),
      );
    }
    final q = _rechercheCtrl.text.trim().toLowerCase();
    final visibles = q.isEmpty
        ? _produits
        : _produits.where((p) => p.nom.toLowerCase().contains(q)).toList();
    return _Carte(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          if (_produits.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _rechercheCtrl,
                decoration: _deco(
                  'Rechercher un produit',
                  Icons.search_rounded,
                ),
              ),
            ),
          for (final p in visibles) _ligneProduit(p),
          if (visibles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Aucun produit trouvé.'),
            ),
        ],
      ),
    );
  }

  Widget _ligneProduit(ProduitModel p) {
    final qte = _quantites[p.id] ?? 0;
    // En rupture, le produit reste sélectionnable : seule la mention change.
    final epuise = p.quantite <= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  epuise
                      ? '${_fcfa(_prix(p))} · rupture de stock'
                      : '${_fcfa(_prix(p))} · ${p.quantite} en stock',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5B6C8A),
                  ),
                ),
              ],
            ),
          ),
          ...[
            _BoutonQte(
              icone: Icons.remove_rounded,
              onTap: qte > 0 ? () => _changerQuantite(p, -1) : null,
            ),
            SizedBox(
              width: 34,
              child: Text(
                '$qte',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            _BoutonQte(
              icone: Icons.add_rounded,
              principal: true,
              onTap: () => _changerQuantite(p, 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _barreValidation(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColor.kWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total produits',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF5B6C8A)),
                ),
                Text(
                  _fcfa(_total),
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColor.kPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _envoi ? null : _enregistrer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kSecondary,
                foregroundColor: AppColor.kPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _envoi
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColor.kPrimary,
                      ),
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontFamily: kPolice,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String libelle, IconData icone) => InputDecoration(
    hintText: libelle,
    prefixIcon: Icon(icone, size: 20, color: const Color(0xFF8A96AD)),
    filled: true,
    fillColor: const Color(0xFFF4F5F8),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColor.kPrimary, width: 1.2),
    ),
  );

  Widget _champ(
    TextEditingController c,
    String libelle, {
    required IconData icone,
    bool requis = false,
    TextInputType? clavier,
    List<TextInputFormatter>? formats,
    TextCapitalization capitalisation = TextCapitalization.none,
    int lignes = 1,
    Widget? prefixe,
    String? Function(String?)? verifier,
  }) {
    final deco = _deco(libelle, icone);
    return TextFormField(
      controller: c,
      keyboardType: clavier,
      inputFormatters: formats,
      textCapitalization: capitalisation,
      maxLines: lignes,
      decoration: prefixe == null ? deco : deco.copyWith(prefixIcon: prefixe),
      validator:
          verifier ??
          (requis
              ? (v) =>
                    (v == null || v.trim().isEmpty) ? '$libelle requis' : null
              : null),
    );
  }
}

class _TitreSection extends StatelessWidget {
  final String texte;
  final String? complement;
  const _TitreSection(this.texte, {this.complement});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Text(
            texte,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColor.kPrimary,
            ),
          ),
          const Spacer(),
          if (complement != null)
            Text(
              complement!,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF5B6C8A)),
            ),
        ],
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Carte({required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: child,
    );
  }
}

class _BoutonQte extends StatelessWidget {
  final IconData icone;
  final VoidCallback? onTap;
  final bool principal;
  const _BoutonQte({required this.icone, this.onTap, this.principal = false});

  @override
  Widget build(BuildContext context) {
    final actif = onTap != null;
    return Material(
      color: !actif
          ? const Color(0xFFF0F2F6)
          : principal
          ? AppColor.kPrimary
          : AppColor.kPrimaryLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icone,
            size: 18,
            color: !actif
                ? const Color(0xFFB4BDCC)
                : principal
                ? AppColor.kWhite
                : AppColor.kPrimary,
          ),
        ),
      ),
    );
  }
}
