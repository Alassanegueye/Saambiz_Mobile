import 'dart:async';

import '../../../../core/widgets/confirmation.dart';

import '../../../../core/services/socket_service.dart';

import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/paiement/feuille_paiement_mobile.dart'
    show LogoOperateur, Operateur;
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/texte.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../injection_container.dart';
import '../../data/models/commande_model.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../widgets/commande_card.dart'
    show
        FriseSuiviCommande,
        couleurStatutCommande,
        etapesEtPosition,
        iconeStatutCommande,
        montantFcfa;
import '../widgets/sections_detail_commande.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../core/services/config_publique_service.dart';

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

/// Le statut vers lequel le vendeur peut faire avancer cette commande, ou
/// `null` si elle n'avance pas d'ici.
///
/// Le cas `acceptee` ne tient pas dans la table ci-dessus : une commande
/// réglée à la réception peut être préparée tout de suite, alors qu'un
/// règlement en ligne attend le paiement du client (le serveur refuse la
/// transition dans ce second cas, voir commande.service.js).
///
/// CE CALCUL DOIT RESTER UNIQUE. Il vivait en double : le bouton le faisait
/// avec le cas `acceptee`, et le gestionnaire du clic lisait la table nue.
/// Pour une commande acceptée à régler à la réception — le cas le plus
/// courant en boutique — le bouton « Passer à : En préparation » s'affichait
/// donc, et ne faisait STRICTEMENT RIEN au clic : la table ne connaît pas
/// `acceptee`, le statut suivant valait `null`, et l'appel au serveur était
/// passé sous silence. Aucune erreur, aucun message : un bouton mort.
String? statutSuivantPourVendeur(
  String statut, {
  required String modePaiement,
}) => statut == 'acceptee' && modePaiement != 'en_ligne'
    ? 'en_preparation'
    : _statutSuivant[statut];

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
  StreamSubscription<Map<String, dynamic>>? _surCommande;
  bool get isVendeur => widget.args.isVendeur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // La commande passée en argument vient de la liste, qui peut dater : le
    // serveur a le dernier mot. Sans cette relecture, une commande acceptée
    // ou mise en préparation réapparaissait « en attente » en revenant.
    WidgetsBinding.instance.addPostFrameCallback((_) => _actualiser());
    // Le changement peut venir d'ailleurs : le client paie ou annule, le
    // vendeur agit depuis un autre appareil, le site de la boutique encaisse.
    // La fiche affichee doit suivre, pas attendre qu'on la quitte.
    if (sl.isRegistered<SocketService>()) {
      _surCommande = sl<SocketService>().onCommandeChangee.listen((donnees) {
        if (mounted && donnees['id']?.toString() == commande.id) _actualiser();
      });
    }
  }

  @override
  void dispose() {
    _surCommande?.cancel();
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
    final confirme = await confirmerAction(
      context,
      icone: Icons.cancel_outlined,
      titre: 'Annuler cette commande ?',
      message: 'Le stock réservé sera rendu et le client sera prévenu.',
      action: 'Annuler la commande',
      annuler: 'Retour',
    );
    if (!confirme) return;
    // Le paiement a pu arriver depuis le dernier affichage : le serveur a le
    // dernier mot, et on relit avant de décider.
    await _actualiser();
    if (!mounted) return;
    if (commande.statutPaiement != 'non_paye' ||
        commande.statut != 'acceptee') {
      afficherInfo(
        context,
        'Cette commande vient de changer : vérifiez son état.',
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
    // PAIEMENT EN LIGNE FERMÉ : on explique au lieu de proposer un choix qui
    // n'aboutirait pas. Ce bouton subsiste sur les commandes créées AVANT la
    // fermeture — les nouvelles partent toutes en « à la réception » et n'ont
    // pas de bouton de paiement du tout.
    if (!ConfigPubliqueService.paiementEnLigneOuvert) {
      await informerAction(
        context,
        icone: Icons.phonelink_off_rounded,
        titre: 'Paiement en ligne indisponible',
        message:
            'Le règlement par Wave et Orange Money n\'est pas encore ouvert '
            'dans l\'application. Réglez votre commande directement avec la '
            'boutique : en espèces à la réception, ou par transfert au numéro '
            'qu\'elle vous indiquera. Le vendeur confirmera le paiement de '
            'son côté.',
      );
      return;
    }

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
              leading: const LogoOperateur(Operateur.wave, taille: 36),
              title: const Text('Wave'),
              onTap: () => Navigator.pop(feuille, 'wave'),
            ),
            ListTile(
              leading: const LogoOperateur(Operateur.orangeMoney, taille: 36),
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
    final confirme = await confirmerAction(
      context,
      icone: Icons.block_outlined,
      titre: 'Rejeter cette commande ?',
      message: 'Le client sera prévenu par e-mail.',
      action: 'Rejeter la commande',
      annuler: 'Retour',
    );
    if (confirme) bloc.add(ChangerStatutCommande(commande.id, 'rejetee'));
  }

  /// Le vendeur confirme avoir été payé (commande réglée à la réception).
  Future<void> _confirmerPaiement() async {
    final bloc = context.read<CommandeBloc>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le paiement ?'),
        content: Text(
          'Vous confirmez avoir reçu ${montantFcfa(commande.montantTotal)} '
          'pour cette commande. Elle sera comptée dans vos ventes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, payée'),
          ),
        ],
      ),
    );
    if (confirme == true) bloc.add(ConfirmerPaiementCommande(commande.id));
  }

  /// Annuler est irréversible et rend le stock : on demande confirmation,
  /// comme pour toutes les autres actions destructives de l'application.
  /// Celle-ci partait au premier appui, sans rien demander.
  Future<void> _annuler() async {
    final bloc = context.read<CommandeBloc>();
    // Le motif reste facultatif : l'imposer pousserait à écrire n'importe
    // quoi pour passer. Quand il est donné, il part avec l'annulation et
    // reste lisible par le vendeur.
    final motif = await _saisirMotif(
      titre: 'Annuler cette commande ?',
      explication: 'Cette action est définitive.',
      libelleChamp: 'Raison (facultatif)',
      valider: 'Annuler la commande',
      obligatoire: false,
    );
    if (motif != null) {
      bloc.add(
        AnnulerCommande(commande.id, motif: motif.isEmpty ? null : motif),
      );
    }
  }

  /// Commande déjà en préparation : on demande, on ne décide pas. Le motif
  /// est obligatoire — le vendeur doit savoir pourquoi tout s'arrête.
  Future<void> _demanderAnnulation() async {
    final bloc = context.read<CommandeBloc>();
    final motif = await _saisirMotif(
      titre: 'Demander l’annulation',
      explication:
          'Le vendeur a commencé à préparer votre commande : il doit accepter '
          'votre demande.',
      libelleChamp: 'Pourquoi souhaitez-vous annuler ?',
      valider: 'Envoyer la demande',
    );
    if (motif != null && motif.isNotEmpty) {
      bloc.add(DemanderAnnulationCommande(commande.id, motif));
    }
  }

  /// Vendeur : accepter la demande (la commande est annulée, le stock rendu)
  /// ou la refuser, avec un motif que l'acheteur pourra lire.
  Future<void> _repondreAnnulation(bool accepte) async {
    final bloc = context.read<CommandeBloc>();
    if (accepte) {
      final confirme = await confirmerAction(
        context,
        icone: Icons.cancel_outlined,
        titre: 'Accepter l’annulation ?',
        message: 'La commande sera annulée et le stock réservé sera rendu.',
        action: 'Accepter l’annulation',
        annuler: 'Revenir',
      );
      if (confirme) {
        bloc.add(RepondreAnnulationCommande(commande.id, accepte: true));
      }
      return;
    }
    final motif = await _saisirMotif(
      titre: 'Refuser l’annulation',
      explication:
          'La commande suivra son cours. Dites pourquoi, si vous le souhaitez.',
      libelleChamp: 'Motif du refus (facultatif)',
      valider: 'Refuser',
      obligatoire: false,
    );
    if (motif != null) {
      bloc.add(
        RepondreAnnulationCommande(commande.id, accepte: false, motif: motif),
      );
    }
  }

  /// Boîte de saisie d'un motif. Rend `null` si on renonce.
  Future<String?> _saisirMotif({
    required String titre,
    required String explication,
    required String libelleChamp,
    required String valider,
    bool obligatoire = true,
  }) async {
    final controleur = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(titre),
          // DÉFILANT. Une `AlertDialog` ne fait pas défiler son contenu
          // d'elle-même : titre, explication, champ à trois lignes et deux
          // boutons ne tiennent pas toujours dans ce que le clavier laisse
          // sur un petit téléphone, et le contenu débordait au lieu de
          // glisser. Rien ne change quand la place suffit.
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(explication, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: controleur,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    label: obligatoire
                        ? LibelleObligatoire(libelleChamp)
                        : Text(libelleChamp),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Revenir'),
            ),
            TextButton(
              onPressed: () {
                final saisi = controleur.text.trim();
                if (obligatoire && saisi.isEmpty) return;
                Navigator.pop(ctx, saisi);
              },
              child: Text(valider),
            ),
          ],
        ),
      );
    } finally {
      // Sans ça, le contrôleur reste accroché à la boîte refermée.
      controleur.dispose();
    }
  }

  void _avancerStatut() {
    final suivant = statutSuivantPourVendeur(
      commande.statut,
      modePaiement: commande.modePaiement,
    );
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
    // Une commande PAYÉE ne s'annule plus : elle passait en « remboursé »
    // sans qu'aucun argent ne bouge. Elle se traite par un retour.
    // Une commande EN PRÉPARATION ne s'annule plus non plus d'un geste : le
    // vendeur a engagé du travail, l'acheteur la DEMANDE (voir plus bas).
    final annulable =
        !isVendeur &&
        commande.statutPaiement != 'paye' &&
        [
          'en_attente',
          'acceptee',
          'payee',
          'confirmee',
        ].contains(commande.statut);
    final annulationDemandable =
        !isVendeur &&
        commande.statut == 'en_preparation' &&
        commande.statutPaiement != 'paye' &&
        !commande.annulationEnAttente;
    // Le vendeur voit la demande et tranche.
    final aRepondreAnnulation = isVendeur && commande.annulationEnAttente;
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
    // Même calcul que celui du clic : voir statutSuivantPourVendeur.
    final statutSuivant = statutSuivantPourVendeur(
      commande.statut,
      modePaiement: commande.modePaiement,
    );
    final retournable = !isVendeur && commande.statut == 'livree';

    return ScaffoldMarine(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commande',
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              // « Code », comme sur les cartes de la liste.
              'Code\u00A0: ${commande.referenceCommande}',
              style: TextStyle(
                fontFamily: kPolice,
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
            afficherErreur(context, state.message);
            // Souvent, la commande a changé ailleurs (déjà acceptée…) : on
            // relit l'état réel pour proposer les bons boutons.
            _actualiser();
          } else if (state is CommandeMiseAJour) {
            setState(() => commande = state.commande);
            afficherSucces(context, 'Commande mise à jour avec succès');
            // La réponse du changement de statut ne contient ni les articles
            // ni le client : on relit la commande complète.
            _actualiser();
          } else if (state is RetourDemande) {
            afficherSucces(context, 'Demande de retour envoyée');
          } else if (state is PaiementInitie) {
            final uri = Uri.tryParse(state.paymentUrl ?? '');
            final ouvert =
                uri != null &&
                uri.hasScheme &&
                await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!ouvert && context.mounted) {
              afficherErreur(
                context,
                'Le paiement n\'a pas pu s\'ouvrir. Réessayez dans un instant.',
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
                          CarteArticlesCommande(commande: commande),
                          const SizedBox(height: 12),
                          // Le client voit la boutique et son vendeur ; le
                          // vendeur, lui, voit son client.
                          if (isVendeur)
                            _contact()
                          else
                            CarteBoutiqueCommande(
                              boutiqueId: commande.boutiqueId,
                              boutiqueNom: commande.boutiqueNom,
                              boutiqueLogo: commande.boutiqueLogo,
                              vendeurId: commande.vendeurId,
                              vendeurNom: commande.vendeurNom,
                              vendeurTelephone: commande.vendeurTelephone,
                            ),
                          const SizedBox(height: 12),
                          CarteDetailsCommande(commande: commande),
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
      // Les boutons vivent dans la barre du bas, donc HORS du corps : le voile
      // de chargement, lui, ne couvre que le corps. Ils restaient donc
      // cliquables pendant la requête, et un deuxième appui partait avant le
      // retour du premier. Le serveur traitait alors le premier (en_attente →
      // acceptee), puis refusait le second : « Transition impossible :
      // acceptee → acceptee », sur un écran qui montrait encore « en attente »
      // puisque aucune réponse n'était arrivée. D'où ce BlocBuilder : pendant
      // qu'une demande est en vol, plus rien n'est cliquable.
      bottomNavigationBar: BlocBuilder<CommandeBloc, CommandeState>(
        builder: (context, state) =>
            // `_actions` rend `null` quand la commande n'offre aucune action ;
            // une barre de hauteur nulle revient au même à l'écran.
            _actions(
              enVol: state is CommandeLoading,
              payable: payable,
              annulable: annulable,
              annulationDemandable: annulationDemandable,
              aRepondreAnnulation: aRepondreAnnulation,
              statutSuivant: statutSuivant,
              aDecider: aDecider,
              annulableVendeur: annulableVendeur,
              retournable: retournable,
            ) ??
            const SizedBox.shrink(),
      ),
    );
  }

  Widget? _actions({
    required bool enVol,
    required bool payable,
    required bool annulable,
    required bool annulationDemandable,
    required bool aRepondreAnnulation,
    required String? statutSuivant,
    required bool retournable,
    required bool aDecider,
    required bool annulableVendeur,
  }) {
    final boutons = <Widget>[];

    /// `null` neutralise un bouton : Flutter le grise et ignore les appuis.
    VoidCallback? actif(VoidCallback action) => enVol ? null : action;

    if (annulableVendeur) {
      boutons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: actif(_annulerParVendeur),
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
            onPressed: actif(_rejeter),
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
            onPressed: actif(_accepter),
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
            onPressed: actif(_payer),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.green,
              foregroundColor: _C.white,
            ),
            child: const Text('Payer maintenant'),
          ),
        ),
      );
    }
    // Le vendeur tranche la demande avant toute autre action : c'est la
    // question qui attend, et elle attend depuis le côté de l'acheteur.
    if (aRepondreAnnulation) {
      boutons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: actif(() => _repondreAnnulation(false)),
            child: const Text('Refuser'),
          ),
        ),
      );
      boutons.add(
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: actif(() => _repondreAnnulation(true)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.kErreur,
              foregroundColor: _C.white,
            ),
            child: const Text('Accepter l’annulation'),
          ),
        ),
      );
    }
    if (annulationDemandable) {
      boutons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: actif(_demanderAnnulation),
            style: OutlinedButton.styleFrom(foregroundColor: AppColor.kErreur),
            child: const Text('Demander l’annulation'),
          ),
        ),
      );
    }
    if (annulable) {
      boutons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: actif(_annuler),
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
            onPressed: actif(_avancerStatut),
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
            onPressed: actif(_demanderRetour),
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
                  style: TextStyle(
                    fontFamily: kPolice,
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
              style: const TextStyle(
                fontFamily: kPolice,
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
              style: TextStyle(
                fontFamily: kPolice,
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
            style: const TextStyle(
              fontFamily: kPolice,
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

  /// Le suivi : toutes les étapes numérotées, comme sur la carte de la
  /// liste, l'étape en cours mise en avant, et ce qui vient ensuite.
  Widget _suivi() {
    final parcours = etapesEtPosition(commande);
    final etapes = parcours.etapes;
    final idx = parcours.index;
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
              if (idx >= 0)
                Text(
                  'Étape ${idx + 1} sur ${etapes.length}',
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12.5,
                    color: _C.sub,
                  ),
                ),
            ],
          ),
          if (idx >= 0) ...[
            const SizedBox(height: 16),
            FriseSuiviCommande(
              etapes: etapes,
              indexCourant: idx,
              terminee: commande.statut == 'livree',
              couleur: couleurStatutCommande(commande.statut),
            ),
          ],
          if (suivante != null) ...[
            const SizedBox(height: 12),
            Text(
              'Prochaine étape : $suivante',
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 13,
                color: _C.sub,
              ),
            ),
          ],
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
              style: const TextStyle(
                fontFamily: kPolice,
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
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12.5,
                    color: _C.sub,
                  ),
                ),
                Text(
                  nom.isEmpty ? 'Non renseigné' : nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _C.black,
                  ),
                ),
                if (telephone != null && telephone.isNotEmpty)
                  Text(
                    telephone,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 13,
                      color: _C.sub,
                    ),
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
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12.5,
                    color: _C.sub,
                  ),
                ),
                Text(
                  valeur,
                  style: const TextStyle(
                    fontFamily: kPolice,
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
          if ((commande.numeroTelephone ?? '').trim().isNotEmpty)
            info(
              Icons.phone_outlined,
              'Téléphone de contact',
              commande.numeroTelephone!.trim(),
            ),
          info(
            Icons.payments_outlined,
            'Paiement',
            '${commande.modePaiement == 'en_ligne' ? 'Wave ou Orange Money' : 'À la réception'}'
                ' · ${commande.statutPaiement == 'paye' ? 'Payée' : 'Non payée'}',
          ),
          // Réglée à la réception : c'est le vendeur qui confirme avoir été
          // payé, pour que la vente entre dans sa comptabilité.
          // Tant que le paiement en ligne est fermé, TOUTE commande se règle
          // avec la boutique : le vendeur doit pouvoir l'acter, y compris sur
          // une commande créée en « en ligne » avant la bascule. Sans cela
          // elle restait « Non payée » pour toujours.
          if (isVendeur &&
              (commande.modePaiement != 'en_ligne' ||
                  !ConfigPubliqueService.paiementEnLigneOuvert) &&
              commande.statutPaiement == 'non_paye' &&
              const {
                'acceptee',
                'confirmee',
                'en_preparation',
                'prete',
                'en_livraison',
                'livree',
              }.contains(commande.statut)) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmerPaiement,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('Marquer comme payée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.green,
                  foregroundColor: _C.white,
                ),
              ),
            ),
          ],
          if (note != null && note.isNotEmpty)
            info(Icons.sticky_note_2_outlined, 'Note du client', note),
        ],
      ),
    );
  }

  Widget _titre(String texte) => Text(
    texte,
    style: const TextStyle(
      fontFamily: kPolice,
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
