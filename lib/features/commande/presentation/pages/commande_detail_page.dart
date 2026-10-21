import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/utils/image_url.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';
import '../../data/models/commande_model.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../widgets/commande_card.dart' show couleurStatutCommande, iconeStatutCommande;

/// Argument de navigation pour la page détail.
class CommandeDetailArgs {
  final CommandeModel commande;
  final bool isVendeur;
  const CommandeDetailArgs(this.commande, {this.isVendeur = false});
}

// Charte SaamBiz (bleu marine / or), alignée sur le reste de l'espace client.
class _C {
  static const green = AppColor.kPrimary;
  static const black = AppColor.kGrayscaleDark100;
  static const white = AppColor.kWhite;
  static const bg = AppColor.kBackground;
  static const sub = AppColor.kGrayscale40;
  static const border = AppColor.kLine;
}

// Ordre du suivi (hors annulation)
const _ordreStatuts = [
  'en_attente',
  'confirmee',
  'en_preparation',
  'prete',
  'en_livraison',
  'livree',
];

// Statut suivant possible pour le vendeur (simplifié)
const Map<String, String> _statutSuivant = {
  'confirmee': 'en_preparation',
  'en_preparation': 'prete',
  'prete': 'en_livraison',
  'en_livraison': 'livree',
};

class CommandeDetailPage extends StatelessWidget {
  const CommandeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as CommandeDetailArgs;
    return BlocProvider(
      create: (_) => sl<CommandeBloc>(),
      child: _DetailView(args: args),
    );
  }
}

class _DetailView extends StatefulWidget {
  final CommandeDetailArgs args;
  const _DetailView({required this.args});
  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  late CommandeModel commande = widget.args.commande;
  bool get isVendeur => widget.args.isVendeur;

  Future<void> _payer() async {
    context
        .read<CommandeBloc>()
        .add(PayerCommande(commande.id, methode: 'orange_money'));
  }

  void _annuler() {
    context.read<CommandeBloc>().add(AnnulerCommande(commande.id));
  }

  void _avancerStatut() {
    final suivant = _statutSuivant[commande.statut];
    if (suivant != null) {
      context.read<CommandeBloc>().add(ChangerStatutCommande(commande.id, suivant));
    }
  }

  Future<void> _demanderRetour() async {
    final raisonCtrl = TextEditingController();
    final raison = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demander un retour'),
        content: TextField(
          controller: raisonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Expliquez la raison du retour',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, raisonCtrl.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (raison != null && raison.isNotEmpty && mounted) {
      context.read<CommandeBloc>().add(DemanderRetourCommande(commande.id, raison));
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatutCommande(commande.statut);
    final annulable = !isVendeur &&
        ['en_attente', 'confirmee', 'en_preparation'].contains(commande.statut);
    final payable = !isVendeur &&
        commande.statutPaiement == 'non_paye' &&
        commande.modePaiement == 'en_ligne' &&
        commande.statut != 'annulee';
    final statutSuivant = _statutSuivant[commande.statut];
    final retournable = !isVendeur && commande.statut == 'livree';

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        surfaceTintColor: _C.white,
        elevation: 0,
        foregroundColor: _C.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commande', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('#${commande.referenceCommande}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: _C.sub)),
          ],
        ),
      ),
      body: BlocConsumer<CommandeBloc, CommandeState>(
        listener: (context, state) async {
          if (state is CommandeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColor.kErreur),
            );
          } else if (state is CommandeMiseAJour) {
            setState(() => commande = state.commande);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Commande mise à jour')),
            );
          } else if (state is RetourDemande) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demande de retour envoyée')),
            );
          } else if (state is PaiementInitie) {
            final url = state.paymentUrl;
            if (url != null && url.isNotEmpty) {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          }
        },
        builder: (context, state) {
          final loading = state is CommandeLoading;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Bandeau statut
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: couleur.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(iconeStatutCommande(commande.statut), color: couleur),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            kStatutCommandeLabels[commande.statut] ??
                                commande.statut,
                            style: GoogleFonts.plusJakartaSans(
                                color: couleur, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Suivi (timeline) si non annulée
                  if (commande.statut != 'annulee') _timeline(),

                  const SizedBox(height: 16),
                  _carte('Articles', _articles()),
                  const SizedBox(height: 12),
                  _carte('Récapitulatif', _recap()),
                  const SizedBox(height: 12),
                  _carte('Livraison', _livraison()),
                  const SizedBox(height: 90),
                ],
              ),
              if (loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: _actions(
        payable: payable,
        annulable: annulable,
        statutSuivant: statutSuivant,
        retournable: retournable,
      ),
    );
  }

  Widget? _actions(
      {required bool payable,
      required bool annulable,
      required String? statutSuivant,
      required bool retournable}) {
    final boutons = <Widget>[];

    if (payable) {
      boutons.add(Expanded(
        child: ElevatedButton(
          onPressed: _payer,
          style: ElevatedButton.styleFrom(
              backgroundColor: _C.green, foregroundColor: _C.white),
          child: const Text('Payer maintenant'),
        ),
      ));
    }
    if (annulable) {
      boutons.add(Expanded(
        child: OutlinedButton(
          onPressed: _annuler,
          style: OutlinedButton.styleFrom(foregroundColor: AppColor.kErreur),
          child: const Text('Annuler'),
        ),
      ));
    }
    if (isVendeur && statutSuivant != null) {
      boutons.add(Expanded(
        child: ElevatedButton(
          onPressed: _avancerStatut,
          style: ElevatedButton.styleFrom(
              backgroundColor: _C.green, foregroundColor: _C.white),
          child: Text('→ ${kStatutCommandeLabels[statutSuivant]}'),
        ),
      ));
    }
    if (retournable) {
      boutons.add(Expanded(
        child: OutlinedButton(
          onPressed: _demanderRetour,
          style: OutlinedButton.styleFrom(foregroundColor: _C.green),
          child: const Text('Demander un retour'),
        ),
      ));
    }

    if (boutons.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      color: _C.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (int i = 0; i < boutons.length; i++) ...[
              boutons[i],
              if (i < boutons.length - 1) const SizedBox(width: 12),
            ]
          ],
        ),
      ),
    );
  }

  Widget _timeline() {
    final idx = _ordreStatuts.indexOf(commande.statut);
    return _carte(
      'Suivi',
      Column(
        children: List.generate(_ordreStatuts.length, (i) {
          final fait = i <= idx;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: fait ? _C.green : _C.bg,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: fait ? _C.green : _C.border, width: 2),
                    ),
                    child: fait
                        ? const Icon(Icons.check, size: 11, color: Colors.white)
                        : null,
                  ),
                  if (i < _ordreStatuts.length - 1)
                    Container(
                        width: 2,
                        height: 22,
                        color: fait ? _C.green : _C.border),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  kStatutCommandeLabels[_ordreStatuts[i]] ?? _ordreStatuts[i],
                  style: TextStyle(
                      color: fait ? _C.black : _C.sub,
                      fontWeight: fait ? FontWeight.w700 : FontWeight.w400),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _articles() {
    return Column(
      children: commande.lignes.map((l) {
        final defaut = Container(
          color: AppColor.kSurface,
          child: const Icon(Icons.shopping_bag_outlined, size: 20, color: AppColor.kGrayscale30),
        );
        final image = l.imageProduit;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: image != null && image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageOptimisee(image, largeur: 160),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => defaut,
                        )
                      : defaut,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.nomProduit,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            color: _C.black, fontWeight: FontWeight.w600, fontSize: 13.5)),
                    // Taille, couleur, parfum… choisis par le client.
                    if (l.libelleOptions.isNotEmpty)
                      Text(l.libelleOptions,
                          style: GoogleFonts.plusJakartaSans(color: _C.sub, fontSize: 12)),
                    Text('${l.prixUnitaire.toStringAsFixed(0)} FCFA × ${l.quantite}',
                        style: GoogleFonts.plusJakartaSans(color: _C.sub, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${l.sousTotal.toStringAsFixed(0)} FCFA',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: _C.black)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _recap() {
    Widget ligne(String l, String v, {bool fort = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l, style: const TextStyle(color: _C.sub)),
              Text(v,
                  style: TextStyle(
                      fontWeight: fort ? FontWeight.w800 : FontWeight.w600,
                      color: fort ? _C.green : _C.black)),
            ],
          ),
        );
    return Column(
      children: [
        ligne('Produits', '${commande.montantProduits.toStringAsFixed(0)} FCFA'),
        ligne('Livraison', '${commande.fraisLivraison.toStringAsFixed(0)} FCFA'),
        const Divider(),
        ligne('Total', '${commande.montantTotal.toStringAsFixed(0)} FCFA',
            fort: true),
      ],
    );
  }

  Widget _livraison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _info('Mode', commande.modeLivraison == 'retrait' ? 'Retrait' : 'Livraison'),
        if (commande.adresseLivraison != null &&
            commande.adresseLivraison!.isNotEmpty)
          _info('Adresse', commande.adresseLivraison!),
        if (commande.numeroTelephone != null)
          _info('Téléphone', commande.numeroTelephone!),
        _info(
            isVendeur ? 'Client' : 'Vendeur',
            (isVendeur ? commande.acheteurNom : commande.vendeurNom) ?? '—'),
        if (commande.note != null && commande.note!.isNotEmpty)
          _info('Note', commande.note!),
      ],
    );
  }

  Widget _info(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(l, style: const TextStyle(color: _C.sub))),
            Expanded(child: Text(v, style: const TextStyle(color: _C.black))),
          ],
        ),
      );

  Widget _carte(String titre, Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, color: _C.black, fontSize: 15)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
