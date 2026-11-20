import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/utils/telephone.dart';
import 'package:saambiz/core/widgets/bouton_indicatif.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/features/commande/presentation/widgets/commande_card.dart'
    show montantFcfa;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/models/panier_item.dart';
import '../../data/services/panier_service.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../core/services/config_publique_service.dart';
import '../../../../core/widgets/formulaire_defilant.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
}

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommandeBloc>(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();
  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _adresseCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _paysTel = ValueNotifier<PaysTelephone>(senegal);
  final _noteCtrl = TextEditingController();

  String _modeLivraison = 'livraison';

  /// Wave et Orange Money ne sont pas branchés : le choix par défaut est
  /// celui qui aboutit. Le serveur dit quand les rouvrir — voir
  /// `ConfigPubliqueService.paiementEnLigneOuvert`.
  late final bool _paiementEnLigneOuvert =
      ConfigPubliqueService.paiementEnLigneOuvert;

  late String _modePaiement = _paiementEnLigneOuvert
      ? 'en_ligne'
      : 'a_la_livraison';

  final _panier = sl<PanierService>();

  @override
  void dispose() {
    _adresseCtrl.dispose();
    _telCtrl.dispose();
    _paysTel.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _soumettre(BuildContext context) {
    // Au moins un produit coché, d'une seule boutique (voir PanierService).
    if (_panier.selectionVide) {
      afficherErreur(
        context,
        'Choisissez au moins un produit dans votre panier.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    context.read<CommandeBloc>().add(
      CreerCommande(
        items: _panier.toApiItems(),
        modeLivraison: _modeLivraison,
        modePaiement: _modePaiement,
        adresseLivraison: _modeLivraison == 'livraison'
            ? _adresseCtrl.text.trim()
            : null,
        numeroTelephone: telephoneInternational(_telCtrl.text, _paysTel.value),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMarine(
      backgroundColor: _C.bg,
      // La barre du total, blanche, reste collée au clavier.
      fondClavier: _C.white,
      appBar: AppBar(title: const Text('Validation de la commande')),
      body: BlocConsumer<CommandeBloc, CommandeState>(
        listener: (context, state) async {
          if (state is CommandeError) {
            afficherErreur(context, state.message);
          } else if (state is CommandeCreee) {
            // Le client paie plus tard, une fois la commande acceptée.
            // Seuls les produits commandés quittent le panier.
            await _panier.retirerSelection();
            if (!context.mounted) return;
            afficherSucces(
              context,
              state.commande.modePaiement == 'en_ligne'
                  ? 'Commande envoyée. Vous pourrez la payer dès que le vendeur l\'aura acceptée.'
                  : 'Commande envoyée au vendeur.',
            );
            _allerMesCommandes(context);
          }
        },
        builder: (context, state) {
          final loading = state is CommandeLoading;
          return AbsorbPointer(
            absorbing: loading,
            child: Form(
              key: _formKey,
              // La barre n'est pas collée en bas : collée, elle remonterait
              // au-dessus du clavier, et la note au vendeur, à trois lignes,
              // serait coupée pendant qu'on l'écrit. Clavier fermé, elle
              // reste en bas de l'écran.
              child: FormulaireDefilant(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                paddingBouton: EdgeInsets.zero,
                enfants: [
                  _section('Récapitulatif'),
                  _Recapitulatif(lignes: _panier.selection),
                  const SizedBox(height: 20),
                  _section('Mode de réception'),
                  _choix(
                    ['livraison', 'retrait'],
                    _modeLivraison,
                    {
                      'livraison': (Icons.local_shipping_outlined, 'Livraison'),
                      'retrait': (Icons.storefront_outlined, 'Retrait'),
                    },
                    (v) => setState(() => _modeLivraison = v),
                  ),
                  if (_modeLivraison == 'livraison') ...[
                    const SizedBox(height: 12),
                    _input(
                      _adresseCtrl,
                      'Adresse de livraison',
                      obligatoire: true,
                      validator: (v) =>
                          (_modeLivraison == 'livraison' &&
                              (v == null || v.trim().isEmpty))
                          ? 'Adresse requise'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _input(
                    _telCtrl,
                    'Téléphone',
                    obligatoire: true,
                    keyboard: TextInputType.phone,
                    formats: [FormatTelephone(_paysTel)],
                    prefixe: BoutonIndicatif(
                      pays: _paysTel,
                      onChange: () => setState(_telCtrl.clear),
                    ),
                    validator: (v) => verifierTelephone(v, _paysTel.value),
                  ),
                  const SizedBox(height: 20),
                  _section('Paiement'),
                  _choix(
                    ['en_ligne', 'a_la_livraison'],
                    _modePaiement,
                    {
                      'en_ligne': (
                        Icons.phone_iphone_rounded,
                        'Wave ou Orange Money',
                      ),
                      'a_la_livraison': (
                        Icons.payments_outlined,
                        'À la réception',
                      ),
                    },
                    (v) => setState(() => _modePaiement = v),
                    indisponibles: _paiementEnLigneOuvert
                        ? const {}
                        : const {'en_ligne'},
                    // Les logos des opérateurs remplacent l'icône : on
                    // reconnaît Wave et Orange Money d'un coup d'œil, bien
                    // avant d'avoir lu « Wave ou Orange Money ».
                    logos: const {
                      'en_ligne': [
                        'assets/images/wave.jpg',
                        'assets/images/OM.png',
                      ],
                    },
                  ),
                  if (!_paiementEnLigneOuvert)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColor.kErreur,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Le paiement en ligne n’est pas encore '
                              'disponible. Vous réglerez votre commande '
                              'directement avec la boutique.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColor.kErreur,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_modePaiement == 'en_ligne')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Vous paierez une fois la commande acceptée par le vendeur.',
                        style: TextStyle(fontSize: 12.5, color: _C.sub),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _section('Note (optionnel)'),
                  _input(
                    _noteCtrl,
                    'Une précision pour le vendeur ?',
                    maxLines: 3,
                  ),
                ],
                bouton: _BarreConfirmation(
                  total: _panier.totalSelection,
                  livraison: _modeLivraison == 'livraison',
                  loading: loading,
                  onConfirmer: () => _soumettre(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _allerMesCommandes(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.mesCommandesRoute,
      (route) => route.isFirst,
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: _C.black,
        fontSize: 15,
      ),
    ),
  );

  Widget _input(
    TextEditingController c,
    String hint, {
    bool obligatoire = false,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formats,
    Widget? prefixe,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: formats,
      decoration: InputDecoration(
        prefixIcon: prefixe,
        hintText: obligatoire ? null : hint,
        label: obligatoire ? LibelleObligatoire(hint) : null,
        filled: true,
        fillColor: _C.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.green),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
      ),
    );
  }

  /// Deux cartes côte à côte. `logos` est facultatif : une option qui n'y
  /// figure pas garde son icône (c'est le cas du mode de livraison).
  Widget _choix(
    List<String> valeurs,
    String selected,
    Map<String, (IconData, String)> options,
    ValueChanged<String> onSelect, {
    Map<String, List<String>> logos = const {},
    Set<String> indisponibles = const {},
  }) {
    // IntrinsicHeight borne la rangée : sans lui, `stretch` dans une
    // ListView demande une hauteur infinie, la mise en page échoue et tout
    // le formulaire disparaît sous « Mode de réception ».
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < valeurs.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _option(
                valeurs[i],
                selected,
                options,
                indisponible: indisponibles.contains(valeurs[i]),
                onSelect,
                logos: logos[valeurs[i]] ?? const [],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _option(
    String v,
    String selected,
    Map<String, (IconData, String)> options,
    ValueChanged<String> onSelect, {
    List<String> logos = const [],
    bool indisponible = false,
  }) {
    // Grisée, mais TOUJOURS VISIBLE. La retirer laisserait croire que
    // l'application ne prendra jamais Wave ni Orange Money ; la montrer
    // éteinte dit la vérité — c'est prévu, ce n'est pas encore ouvert.
    final sel = v == selected && !indisponible;
    final (icone, libelle) = options[v]!;
    final teinte = indisponible
        ? AppColor.kGrayscale30
        : (sel ? _C.green : _C.sub);
    return Opacity(
      opacity: indisponible ? 0.55 : 1,
      child: Material(
        color: indisponible
            ? AppColor.kBackground
            : (sel ? AppColor.kPrimaryLight : _C.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: indisponible ? _C.border : (sel ? _C.green : _C.border),
            width: sel ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // `null` : l'option ne réagit pas au doigt, et aucun halo ne
          // laisse espérer qu'elle va s'ouvrir.
          onTap: indisponible ? null : () => onSelect(v),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                if (logos.isEmpty)
                  Icon(icone, size: 22, color: teinte)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < logos.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _LogoOperateur(logos[i], estime: sel),
                      ],
                    ],
                  ),
                const SizedBox(height: 6),
                Text(
                  libelle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: teinte,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (indisponible) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Bientôt',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColor.kGrayscale30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le logo carré d'un opérateur de paiement.
///
/// Même gabarit que l'icône qu'il remplace (22 px) pour que les deux
/// cartes gardent la même hauteur. Les sources sont carrées (400×400 et
/// 447×447) : `cacheWidth` évite de décoder 200 ko d'image pour en
/// afficher 22 px.
///
/// Atténué quand la carte n'est pas choisie, pour que la sélection reste
/// lisible — un logo en couleurs attire l'œil autant qu'une bordure.
class _LogoOperateur extends StatelessWidget {
  final String chemin;
  final bool estime;
  const _LogoOperateur(this.chemin, {required this.estime});

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset(
        chemin,
        width: 22,
        height: 22,
        fit: BoxFit.cover,
        cacheWidth: 66, // 22 px à 3× : net sur les écrans denses.
        // Un asset manquant ne doit pas afficher la croix rouge de Flutter
        // par-dessus le formulaire de commande.
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.phone_iphone_rounded, size: 22, color: _C.sub),
      ),
    );
    return Semantics(
      excludeSemantics: true, // Le libellé de la carte dit déjà lesquels.
      child: estime ? image : Opacity(opacity: 0.55, child: image),
    );
  }
}

/// Les produits cochés dans le panier : la boutique, chaque ligne avec sa
/// quantité et son sous-total, puis le total des produits.
class _Recapitulatif extends StatelessWidget {
  final List<PanierItem> lignes;
  const _Recapitulatif({required this.lignes});

  @override
  Widget build(BuildContext context) {
    final total = lignes.fold<double>(0, (s, it) => s + it.sousTotal);
    final boutique = lignes.isEmpty ? '' : lignes.first.vendeurNom;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (boutique.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 18,
                    color: _C.green,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      boutique,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _C.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (final it in lignes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: it.image.isNotEmpty
                        ? ImageReseau(
                            it.image,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            repli: const _Vignette(),
                          )
                        : const _Vignette(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.nom,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _C.black,
                          ),
                        ),
                        if (it.options.isNotEmpty)
                          Text(
                            it.libelleOptions,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: _C.sub),
                          ),
                        Text(
                          '${it.quantite} × ${montantFcfa(it.prix)}',
                          style: const TextStyle(fontSize: 12, color: _C.sub),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    montantFcfa(it.sousTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _C.black,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 20, color: _C.border),
          Row(
            children: [
              const Expanded(
                child: Text('Total produits', style: TextStyle(color: _C.sub)),
              ),
              Text(
                montantFcfa(total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _C.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette();
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    color: _C.bg,
    child: const Icon(Icons.shopping_bag_outlined, size: 20, color: _C.sub),
  );
}

/// Total et bouton de confirmation, toujours visibles en bas de l'écran.
class _BarreConfirmation extends StatelessWidget {
  final double total;
  final bool livraison;
  final bool loading;
  final VoidCallback onConfirmer;
  const _BarreConfirmation({
    required this.total,
    required this.livraison,
    required this.loading,
    required this.onConfirmer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _C.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 14)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    montantFcfa(total),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _C.black,
                    ),
                  ),
                  Text(
                    livraison ? '+ frais de livraison' : 'Retrait en boutique',
                    style: const TextStyle(fontSize: 12, color: _C.sub),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: loading ? null : onConfirmer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: _C.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 15,
                ),
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
                  : const Text(
                      'Confirmer la commande',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
