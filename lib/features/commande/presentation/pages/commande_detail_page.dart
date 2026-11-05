import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/utils/image_url.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/texte.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../injection_container.dart';
import '../../data/models/commande_model.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../widgets/commande_card.dart'
    show couleurStatutCommande, iconeStatutCommande, montantFcfa;

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
  'acceptee',
  'payee',
  'confirmee',
  'en_preparation',
  'prete',
  'en_livraison',
  'livree',
];

// Statut suivant possible pour le vendeur (simplifié)
const Map<String, String> _statutSuivant = {
  'payee': 'en_preparation',
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

class _DetailViewState extends State<_DetailView> with WidgetsBindingObserver {
  late CommandeModel commande = widget.args.commande;
  bool get isVendeur => widget.args.isVendeur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Retour de Wave ou d'Orange Money : le paiement a pu aboutir entre-temps.
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) _actualiser();
  }

  /// Le client paie de son côté : le vendeur peut relire la commande en tirant
  /// la page, et une commande sans réponse peut être annulée pour libérer le
  /// stock réservé.
  Future<void> _annulerParVendeur() async {
    final bloc = context.read<CommandeBloc>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler cette commande ?'),
        content: const Text(
          'Le stock réservé sera rendu et le client sera prévenu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColor.kErreur),
            child: const Text('Annuler la commande'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    // Le paiement a pu arriver depuis le dernier affichage : le serveur a le
    // dernier mot, et on relit avant de décider.
    await _actualiser();
    if (!mounted) return;
    if (commande.statutPaiement != 'non_paye' ||
        commande.statut != 'acceptee') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette commande vient de changer : vérifiez son état.'),
        ),
      );
      return;
    }
    bloc.add(ChangerStatutCommande(commande.id, 'annulee'));
  }

  Future<void> _actualiser() async {
    try {
      final aJour = await context.read<CommandeBloc>().repository.getCommande(
        commande.id,
      );
      if (mounted) setState(() => commande = aJour);
    } catch (_) {
      /* la commande affichée reste valable */
    }
  }

  Future<void> _payer() async {
    final bloc = context.read<CommandeBloc>();
    final methode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _C.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (feuille) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_iphone_rounded),
              title: const Text('Wave'),
              onTap: () => Navigator.pop(feuille, 'wave'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android_rounded),
              title: const Text('Orange Money'),
              onTap: () => Navigator.pop(feuille, 'orange_money'),
            ),
          ],
        ),
      ),
    );
    if (methode != null) bloc.add(PayerCommande(commande.id, methode: methode));
  }

  void _accepter() {
    context.read<CommandeBloc>().add(
      ChangerStatutCommande(commande.id, 'acceptee'),
    );
  }

  Future<void> _rejeter() async {
    final bloc = context.read<CommandeBloc>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter cette commande ?'),
        content: const Text('Le client sera prévenu par e-mail.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColor.kErreur),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      bloc.add(ChangerStatutCommande(commande.id, 'rejetee'));
    }
  }

  void _annuler() {
    context.read<CommandeBloc>().add(AnnulerCommande(commande.id));
  }

  void _avancerStatut() {
    final suivant = _statutSuivant[commande.statut];
    if (suivant != null) {
      context.read<CommandeBloc>().add(
        ChangerStatutCommande(commande.id, suivant),
      );
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
            label: LibelleObligatoire('Raison du retour'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, raisonCtrl.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (raison != null && raison.isNotEmpty && mounted) {
      context.read<CommandeBloc>().add(
        DemanderRetourCommande(commande.id, raison),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final annulable =
        !isVendeur &&
        [
          'en_attente',
          'acceptee',
          'payee',
          'confirmee',
          'en_preparation',
        ].contains(commande.statut);
    final payable =
        !isVendeur &&
        commande.statut == 'acceptee' &&
        commande.statutPaiement == 'non_paye' &&
        commande.modePaiement == 'en_ligne';
    final aDecider = isVendeur && commande.statut == 'en_attente';
    final annulableVendeur =
        isVendeur &&
        commande.statut == 'acceptee' &&
        commande.statutPaiement == 'non_paye';
    // Acceptée et réglée à la réception : le vendeur peut la préparer. Réglée en
    // ligne, elle attend le paiement du client.
    final statutSuivant =
        commande.statut == 'acceptee' && commande.modePaiement != 'en_ligne'
        ? 'en_preparation'
        : _statutSuivant[commande.statut];
    final retournable = !isVendeur && commande.statut == 'livree';

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '#${commande.referenceCommande}',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: _C.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<CommandeBloc, CommandeState>(
        listener: (context, state) async {
          if (state is CommandeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.kErreur,
              ),
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
            final uri = Uri.tryParse(state.paymentUrl ?? '');
            final ouvert =
                uri != null &&
                uri.hasScheme &&
                await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!ouvert && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Le paiement n\'a pas pu s\'ouvrir. Réessayez dans un instant.',
                  ),
                  backgroundColor: AppColor.kErreur,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          final loading = state is CommandeLoading;
          return Stack(
            children: [
              // Sans rebond : il ferait apparaître un trou clair sous l'en-tête.
              RefreshIndicator(
                color: AppColor.kPrimary,
                onRefresh: _actualiser,
                child: ListView(
                  physics: const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _blocStatut(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
                          if (![
                            'annulee',
                            'rejetee',
                          ].contains(commande.statut)) ...[
                            _suivi(),
                            const SizedBox(height: 12),
                          ],
                          _articles(),
                          const SizedBox(height: 12),
                          _contact(),
                          const SizedBox(height: 12),
                          _livraison(),
                        ],
                      ),
                    ),
                  ],
                ),
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
        aDecider: aDecider,
        annulableVendeur: annulableVendeur,
        retournable: retournable,
      ),
    );
  }

  Widget? _actions({
    required bool payable,
    required bool annulable,
    required String? statutSuivant,
    required bool retournable,
    required bool aDecider,
    required bool annulableVendeur,
  }) {
    final boutons = <Widget>[];

    if (annulableVendeur) {
      boutons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: _annulerParVendeur,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.kErreur,
              side: const BorderSide(color: AppColor.kErreur),
            ),
            child: const Text('Annuler la commande'),
          ),
        ),
      );
    }

    if (aDecider) {
      boutons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: _rejeter,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.kErreur,
              side: const BorderSide(color: AppColor.kErreur),
            ),
            child: const Text('Rejeter'),
          ),
        ),
      );
      boutons.add(
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _accepter,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.green,
              foregroundColor: _C.white,
            ),
            child: const Text('Accepter'),
          ),
        ),
      );
    }

    if (payable) {
      boutons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: _payer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.green,
              foregroundColor: _C.white,
            ),
            child: const Text('Payer maintenant'),
          ),
        ),
      );
    }
    if (annulable) {
      boutons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: _annuler,
            style: OutlinedButton.styleFrom(foregroundColor: AppColor.kErreur),
            child: const Text('Annuler'),
          ),
        ),
      );
    }
    if (isVendeur && statutSuivant != null) {
      boutons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: _avancerStatut,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.green,
              foregroundColor: _C.white,
            ),
            child: Text('Passer à : ${kStatutCommandeLabels[statutSuivant]}'),
          ),
        ),
      );
    }
    if (retournable) {
      boutons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: _demanderRetour,
            style: OutlinedButton.styleFrom(foregroundColor: _C.green),
            child: const Text('Demander un retour'),
          ),
        ),
      );
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
            ],
          ],
        ),
      ),
    );
  }

  /// Le statut, le total et ce qu'il faut retenir, sur le bleu de l'en-tête.
  Widget _blocStatut() {
    final date = commande.createdAt?.toLocal();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
      decoration: const BoxDecoration(
        color: AppColor.kPrimary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  iconeStatutCommande(commande.statut),
                  size: 16,
                  color: couleurStatutCommande(commande.statut),
                ),
                const SizedBox(width: 6),
                Text(
                  kStatutCommandeLabels[commande.statut] ?? commande.statut,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: couleurStatutCommande(commande.statut),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              montantFcfa(commande.montantTotal),
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: _C.white,
              ),
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: 2),
            Text(
              'Passée le ${dateLongue(date)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _C.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            messageStatutCommande(
              commande.statut,
              modePaiement: commande.modePaiement,
              isVendeur: isVendeur,
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: _C.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Le suivi tient sur une barre : où en est la commande, et ce qui vient.
  Widget _suivi() {
    final etapes = etapesSuiviCommande(
      commande.statut,
      modePaiement: commande.modePaiement,
    );
    final idx = etapes.indexOf(commande.statut);
    final suivante = idx >= 0 && idx < etapes.length - 1
        ? kStatutCommandeLabels[etapes[idx + 1]]
        : null;
    return _carte(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _titre('Suivi')),
              Text(
                'Étape ${idx + 1} sur ${etapes.length}',
                style: GoogleFonts.inter(fontSize: 12.5, color: _C.sub),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < etapes.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= idx ? _C.green : _C.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (suivante != null) ...[
            const SizedBox(height: 10),
            Text(
              'Prochaine étape : $suivante',
              style: GoogleFonts.inter(fontSize: 13, color: _C.sub),
            ),
          ],
        ],
      ),
    );
  }

  /// Les articles et le détail du prix, réunis : on lit l'un puis l'autre.
  Widget _articles() {
    Widget ligne(String libelle, String valeur, {bool fort = false}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            libelle,
            style: GoogleFonts.inter(
              fontSize: fort ? 15 : 13.5,
              fontWeight: fort ? FontWeight.w700 : FontWeight.w400,
              color: fort ? _C.black : _C.sub,
            ),
          ),
          Text(
            valeur,
            style: GoogleFonts.inter(
              fontSize: fort ? 16 : 13.5,
              fontWeight: fort ? FontWeight.w800 : FontWeight.w500,
              color: _C.black,
            ),
          ),
        ],
      ),
    );

    final nbArticles = commande.lignes.fold<int>(0, (n, l) => n + l.quantite);
    return _carte(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titre('$nbArticles article${nbArticles > 1 ? 's' : ''}'),
          const SizedBox(height: 8),
          for (final l in commande.lignes) _ligneArticle(l),
          const Divider(height: 20),
          ligne('Produits', montantFcfa(commande.montantProduits)),
          // Un retrait en boutique n'a pas de livraison à « offrir ».
          if (commande.modeLivraison != 'retrait')
            ligne(
              'Livraison',
              commande.fraisLivraison > 0
                  ? montantFcfa(commande.fraisLivraison)
                  : 'Offerte',
            ),
          const SizedBox(height: 4),
          ligne('Total', montantFcfa(commande.montantTotal), fort: true),
        ],
      ),
    );
  }

  Widget _ligneArticle(LigneCommandeModel l) {
    final defaut = Container(
      color: AppColor.kSurface,
      child: const Icon(
        Icons.shopping_bag_outlined,
        size: 22,
        color: AppColor.kGrayscale30,
      ),
    );
    final image = l.imageProduit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
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
                Text(
                  l.nomProduit,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _C.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                // Taille, couleur, parfum… choisis par le client.
                if (l.libelleOptions.isNotEmpty)
                  Text(
                    l.libelleOptions,
                    style: GoogleFonts.inter(color: _C.sub, fontSize: 12.5),
                  ),
                const SizedBox(height: 2),
                Text(
                  'Quantité : ${l.quantite}',
                  style: GoogleFonts.inter(color: _C.sub, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            montantFcfa(l.sousTotal),
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _C.black,
            ),
          ),
        ],
      ),
    );
  }

  /// La personne en face, et comment la joindre.
  Widget _contact() {
    final nom = ((isVendeur ? commande.acheteurNom : commande.vendeurNom) ?? '')
        .trim();
    final telephone = isVendeur
        ? (commande.acheteurTelephone ?? commande.numeroTelephone)
        : commande.vendeurTelephone;
    final initiales = initialesDe(nom);
    return _carte(
      Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColor.kPrimaryLight,
            child: Text(
              initiales.isEmpty ? '?' : initiales,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.green,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVendeur ? 'Client' : 'Vendeur',
                  style: GoogleFonts.inter(fontSize: 12.5, color: _C.sub),
                ),
                Text(
                  nom.isEmpty ? 'Non renseigné' : nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _C.black,
                  ),
                ),
                if (telephone != null && telephone.isNotEmpty)
                  Text(
                    telephone,
                    style: GoogleFonts.inter(fontSize: 13, color: _C.sub),
                  ),
              ],
            ),
          ),
          if (telephone != null && telephone.isNotEmpty)
            IconButton.filledTonal(
              tooltip: 'Appeler',
              onPressed: () => UrlExterne.lancer('tel:$telephone'),
              style: IconButton.styleFrom(
                backgroundColor: AppColor.kPrimaryLight,
                foregroundColor: _C.green,
              ),
              icon: const Icon(Icons.call_outlined, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _livraison() {
    final retrait = commande.modeLivraison == 'retrait';
    final adresse = commande.adresseLivraison;
    final note = commande.note;
    Widget info(IconData icone, String libelle, String valeur) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: AppColor.kPrimaryMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libelle,
                  style: GoogleFonts.inter(fontSize: 12.5, color: _C.sub),
                ),
                Text(
                  valeur,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _C.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return _carte(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titre('Réception et paiement'),
          const SizedBox(height: 6),
          info(
            retrait ? Icons.storefront_outlined : Icons.local_shipping_outlined,
            'Réception',
            retrait ? 'Retrait en boutique' : 'Livraison',
          ),
          if (adresse != null && adresse.isNotEmpty)
            info(Icons.location_on_outlined, 'Adresse', adresse),
          info(
            Icons.payments_outlined,
            'Paiement',
            commande.modePaiement == 'en_ligne'
                ? 'Wave ou Orange Money'
                : 'À la réception',
          ),
          if (note != null && note.isNotEmpty)
            info(Icons.sticky_note_2_outlined, 'Note du client', note),
        ],
      ),
    );
  }

  Widget _titre(String texte) => Text(
    texte,
    style: GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      color: _C.black,
      fontSize: 15,
    ),
  );

  Widget _carte(Widget child) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: _C.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );
}

/// Les étapes de CETTE commande : pas de « Payée » pour un règlement à la
/// réception, pas d'« Acceptée » pour une ancienne commande « Confirmée ».
List<String> etapesSuiviCommande(
  String statut, {
  required String modePaiement,
}) {
  final ancienne = statut == 'confirmee';
  return _ordreStatuts.where((s) {
    if (s == 'confirmee') return ancienne;
    if (s == 'acceptee') return !ancienne;
    if (s == 'payee') return modePaiement == 'en_ligne' && !ancienne;
    return true;
  }).toList();
}

/// Ce que le statut veut dire, pour la personne qui regarde.
String messageStatutCommande(
  String statut, {
  required String modePaiement,
  required bool isVendeur,
}) {
  final enLigne = modePaiement == 'en_ligne';
  switch (statut) {
    case 'en_attente':
      return isVendeur
          ? 'À vous de décider : acceptez ou rejetez cette commande.'
          : 'Le vendeur doit encore accepter votre commande.';
    case 'acceptee':
      if (isVendeur) {
        return enLigne
            ? 'Le client doit payer. Vous serez notifié dès que c\'est fait.'
            : 'Acceptée. Le client réglera à la réception.';
      }
      return enLigne
          ? 'Acceptée par le vendeur. Vous pouvez la payer.'
          : 'Acceptée par le vendeur. Vous réglerez à la réception.';
    case 'rejetee':
      return isVendeur
          ? 'Vous avez rejeté cette commande.'
          : 'Le vendeur a rejeté cette commande. Vous n\'êtes pas débité.';
    case 'payee':
      return isVendeur
          ? 'Le client a payé. Vous pouvez préparer la commande.'
          : 'Paiement reçu. Le vendeur va préparer votre commande.';
    case 'confirmee':
      return 'Commande confirmée.';
    case 'en_preparation':
      return isVendeur
          ? 'Commande en cours de préparation.'
          : 'Le vendeur prépare votre commande.';
    case 'prete':
      return 'La commande est prête.';
    case 'en_livraison':
      return 'La commande est en cours de livraison.';
    case 'livree':
      return 'La commande a été livrée.';
    case 'annulee':
      return 'Cette commande a été annulée.';
    default:
      return kStatutCommandeLabels[statut] ?? statut;
  }
}
