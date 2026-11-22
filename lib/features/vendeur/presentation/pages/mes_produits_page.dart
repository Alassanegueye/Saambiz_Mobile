import 'package:saambiz/core/widgets/barre_pagination.dart';
import 'package:saambiz/core/widgets/confirmation.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:saambiz/core/widgets/image_produit.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/page_vendeur.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/widgets/ui_kit.dart';
import '../../../catalogue/presentation/widgets/produit_card.dart'
    show formaterPrix;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';
import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../bloc/vendeur_produit_bloc.dart';
import 'produit_form_page.dart';
import 'package:saambiz/core/utils/texte.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE6EAF0);
  static const danger = Color(0xFFD64533);
}

/// Le statut en mots et en couleur. La modération d'abord : un produit
/// refusé ou en attente reste caché aux clients, même en ligne. Puis hors
/// ligne en gris, la rupture en rouge, le stock qui s'épuise en or (3 ou
/// moins, le seuil de la vitrine), le reste en vert.
(String, Color) statutProduitVendeur(ProduitModel p) {
  if (p.statut == 'rejete') {
    return ('Refusé par la modération', AppColor.kErreur);
  }
  if (p.statut == 'en_attente') {
    return ('En attente de validation', AppColor.kSecondaryDark);
  }
  if (!p.disponible) {
    return ('Hors ligne · invisible pour vos clients', AppColor.kGrayscale40);
  }
  if (p.quantite <= 0) return ('Rupture de stock', AppColor.kErreur);
  if (p.quantite <= 3) {
    return ('Plus que ${p.quantite} en stock', AppColor.kSecondaryDark);
  }
  return ('En ligne · ${p.quantite} en stock', AppColor.kSucces);
}

class MesProduitsPage extends StatelessWidget {
  const MesProduitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VendeurProduitBloc>()..add(LoadMesProduits()),
      child: ActualiserAuRetour(
        onRetour: (context) =>
            context.read<VendeurProduitBloc>().add(LoadMesProduits()),
        child: const _MesProduitsView(),
      ),
    );
  }
}

class _MesProduitsView extends StatefulWidget {
  const _MesProduitsView();

  @override
  State<_MesProduitsView> createState() => _MesProduitsViewState();
}

class _MesProduitsViewState extends State<_MesProduitsView> {
  int _tab = 0; // 0 = Tous, 1 = En ligne, 2 = Hors ligne
  bool _rechercheOuverte = false;
  String _recherche = '';

  // « En ligne » = mis en ligne par le vendeur (interrupteur), et non déduit
  // du stock : déduit du stock, l'écran resterait figé tant qu'il y en a,
  // quoi que fasse l'interrupteur.
  bool _enLigne(ProduitModel p) => p.disponible;

  Future<void> _ouvrirForm(BuildContext context, {dynamic produit}) async {
    final bloc = context.read<VendeurProduitBloc>();
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProduitFormPage(produit: produit)),
    );
    if (res == true) bloc.add(LoadMesProduits());
  }

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Mes produits',
      titreWidget: _rechercheOuverte ? _champRecherche() : null,
      actions: [
        BoutonEnteteVendeur(
          icone: _rechercheOuverte ? Icons.close_rounded : Icons.search_rounded,
          infobulle: _rechercheOuverte ? 'Fermer la recherche' : 'Rechercher',
          onTap: () => setState(() {
            _rechercheOuverte = !_rechercheOuverte;
            if (!_rechercheOuverte) _recherche = '';
          }),
        ),
      ],
      boutonFlottant: FloatingActionButton.extended(
        onPressed: () => _ouvrirForm(context),
        backgroundColor: AppColor.kSecondary,
        foregroundColor: AppColor.kPrimary,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Ajouter',
          style: TextStyle(fontFamily: kPolice, fontWeight: FontWeight.w700),
        ),
      ),
      corps: BlocConsumer<VendeurProduitBloc, VendeurProduitState>(
        buildWhen: (avant, apres) =>
            !(apres is VendeurProduitLoading && avant is VendeurProduitLoaded),
        listener: (context, state) {
          if (state is VendeurProduitError) {
            afficherErreur(context, state.message);
          } else if (state is VendeurProduitLoaded && state.succes != null) {
            afficherSucces(context, state.succes!);
          }
        },
        builder: (context, state) {
          if (state is VendeurProduitLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _C.green),
            );
          }
          if (state is VendeurProduitError) {
            return _buildError(context, state.message);
          }
          if (state is VendeurProduitLoaded) {
            final all = state.produits;
            final enLigne = all.where(_enLigne).toList();
            final horsLigne = all.where((p) => !_enLigne(p)).toList();
            final shown =
                (_tab == 1
                        ? enLigne
                        : _tab == 2
                        ? horsLigne
                        : all)
                    .where((p) => contientRecherche(p.nom, _recherche))
                    .toList();

            return Column(
              children: [
                // Le total du serveur pour « Tous » : compter la liste
                // chargee donnerait « 10 » a qui a cent produits. « En
                // ligne » et « Hors ligne » restent comptes sur la page
                // affichee — le serveur ne les distingue pas encore.
                _buildTabs(
                  state.pagination.total > 0
                      ? state.pagination.total
                      : all.length,
                  enLigne.length,
                  horsLigne.length,
                ),
                Expanded(
                  child: shown.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: _C.green,
                          onRefresh: () async => context
                              .read<VendeurProduitBloc>()
                              .add(LoadMesProduits()),
                          child: ListView.separated(
                            // Le bas laisse la place au bouton
                            // Ajouter et a la barre d'onglets.
                            padding: EdgeInsets.fromLTRB(
                              16,
                              4,
                              16,
                              espaceBasVendeur(context) + 72,
                            ),
                            // +1 : la barre « Precedent / Suivant » en pied
                            // de liste, repliee s'il n'y a qu'une page.
                            itemCount: shown.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              if (i == shown.length) {
                                return BarrePagination(
                                  pagination: state.pagination,
                                  onPage: (page) => context
                                      .read<VendeurProduitBloc>()
                                      .add(LoadMesProduits(page: page)),
                                );
                              }
                              return _buildCard(context, shown[i]);
                            },
                          ),
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Champ de recherche blanc sur l'en-tête marine, à la place du titre.
  Widget _champRecherche() {
    return TextField(
      autofocus: true,
      onChanged: (v) => setState(() => _recherche = v),
      cursorColor: AppColor.kSecondary,
      style: const TextStyle(
        fontFamily: kPolice,
        fontSize: 16,
        color: AppColor.kWhite,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher un produit',
        hintStyle: TextStyle(
          fontFamily: kPolice,
          color: AppColor.kWhite.withValues(alpha: 0.6),
        ),
        isDense: true,
        filled: true,
        fillColor: AppColor.kWhite.withValues(alpha: 0.12),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColor.kWhite.withValues(alpha: 0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Filtres Tous / En ligne / Hors ligne
  Widget _buildTabs(int total, int enLigne, int horsLigne) {
    final filtres = [
      'Tous ($total)',
      'En ligne ($enLigne)',
      'Hors ligne ($horsLigne)',
    ];
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        children: [
          for (var i = 0; i < filtres.length; i++) ...[
            PuceFiltre(
              libelle: filtres[i],
              active: _tab == i,
              onTap: () => setState(() => _tab = i),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  // Carte produit : le toucher ouvre le produit à modifier, l'interrupteur
  // le met en ligne ou le retire, le menu garde Modifier et Supprimer.
  Widget _buildCard(BuildContext context, ProduitModel p) {
    final enLigne = _enLigne(p);
    final (statut, couleurStatut) = statutProduitVendeur(p);
    // Caché aux clients : hors ligne, ou pas (encore) approuvé.
    final visible = enLigne && p.statut == 'approuve';
    return Material(
      color: _C.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _ouvrirForm(context, produit: p),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              // Caché aux clients, la photo pâlit.
              Opacity(
                opacity: visible ? 1 : 0.45,
                child: ImageProduit(p.image, cote: 68, largeurServeur: 200),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: _C.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formaterPrix(double.tryParse(p.prix) ?? 0),
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _C.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.5),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: couleurStatut,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statut,
                            style: TextStyle(
                              fontFamily: kPolice,
                              fontSize: 12,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              color: couleurStatut,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Comme l'interrupteur « Boutique en ligne » : piste verte.
              // Une couleur marine effacerait la pastille sur la piste
              // marine du thème.
              Switch.adaptive(
                value: enLigne,
                activeTrackColor: AppColor.kSucces,
                onChanged: (_) => context.read<VendeurProduitBloc>().add(
                  ToggleDispoProduit(p.id),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Plus d’actions',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: _C.sub,
                  size: 20,
                ),
                onSelected: (v) {
                  final bloc = context.read<VendeurProduitBloc>();
                  if (v == 'edit') {
                    _ouvrirForm(context, produit: p);
                  } else if (v == 'delete') {
                    _confirmerSuppression(context, bloc, p);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Supprimer',
                      style: TextStyle(color: AppColor.kErreur),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: EdgeInsets.only(bottom: espaceBasVendeur(context)),
      child: EtatVide(
        icone: Icons.inventory_2_outlined,
        titre: _recherche.isNotEmpty ? 'Aucun résultat' : 'Aucun produit ici',
        message: _recherche.isNotEmpty
            ? 'Essayez un autre nom de produit.'
            : 'Ajoutez votre premier produit pour le vendre en ligne.',
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _C.danger, size: 44),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kPolice, color: _C.sub),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                context.read<VendeurProduitBloc>().add(LoadMesProduits()),
            child: const Text(
              'Réessayer',
              style: TextStyle(
                fontFamily: kPolice,
                color: _C.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // La feuille de confirmation commune, comme pour toute suppression.
  Future<void> _confirmerSuppression(
    BuildContext context,
    VendeurProduitBloc bloc,
    ProduitModel p,
  ) async {
    final ok = await confirmerAction(
      context,
      icone: Icons.delete_outline_rounded,
      titre: 'Supprimer ce produit ?',
      message:
          '${p.nom} disparaîtra de votre boutique. Cette action est irréversible.',
      action: 'Supprimer',
    );
    if (ok) bloc.add(SupprimerProduit(p.id));
  }
}
