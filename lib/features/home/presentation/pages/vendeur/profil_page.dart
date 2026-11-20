import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/features/certification/certification_page.dart';
import 'package:saambiz/features/certification/certification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:saambiz/core/routes/app_router.dart';

import '../../../../../core/constants/infos_app.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/url_externe.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart'
    show kEspaceBarreBas;
import '../../../../../core/widgets/entete_compte.dart';
import '../../../../../core/widgets/page_vendeur.dart';
import '../../../../../core/widgets/profil_kit.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../../../../compte/presentation/bloc/compte_bloc.dart';
import '../../../../compte/presentation/bloc/compte_event.dart';
import '../../../../compte/presentation/bloc/compte_state.dart';
import '../../../../compte/presentation/pages/a_propos_page.dart';
import '../../../../compte/presentation/pages/aide_page.dart';
import '../../../../compte/presentation/pages/change_password_page.dart';
import '../../../../compte/presentation/pages/edit_profil_page.dart';
import '../../../../abonnement/presentation/pages/mon_abonnement_page.dart';
import '../../../../boutique/presentation/pages/ma_boutique_page.dart';
import '../../../../messagerie/presentation/pages/conversations_page.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../catalogue/presentation/widgets/produit_card.dart'
    show formaterPrix;

/// Onglet « Compte » du vendeur : le profil dans l'en-tête bleu, le solde,
/// puis des groupes d’entrées dans des cartes blanches.
class ProfilPage extends StatefulWidget {
  final User? user;
  const ProfilPage({super.key, this.user});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> with RetourSurOnglet {
  @override
  void surRetourOnglet() => _compteBloc.add(LoadCompte());

  late final CompteBloc _compteBloc = sl<CompteBloc>();
  User? _liveUser;

  /// Nul tant que le statut n'est pas connu : rien ne s'affiche alors.
  StatutCertification? _certification;

  @override
  void initState() {
    super.initState();
    _compteBloc.add(LoadCompte());
    _chargerCertification();
  }

  Future<void> _chargerCertification() async {
    try {
      final s = await CertificationService(sl<Dio>()).statut();
      if (mounted) setState(() => _certification = s);
    } catch (e) {
      logDebug('Statut de certification non chargé : $e');
    }
  }

  Future<void> _ouvrirCertification() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CertificationPage()));
    _chargerCertification();
  }

  @override
  void dispose() {
    _compteBloc.close();
    super.dispose();
  }

  User? get _user => _liveUser ?? widget.user;

  String get _nomComplet =>
      _user == null ? 'Invité' : '${_user!.prenom} ${_user!.nom}'.trim();

  String get _initiales {
    if (_user == null) return '?';
    final p = _user!.prenom.isNotEmpty ? _user!.prenom[0] : '';
    final n = _user!.nom.isNotEmpty ? _user!.nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  Future<void> _onEditProfil() async {
    final updated = await Navigator.of(context).push<User>(
      MaterialPageRoute(builder: (_) => EditProfilePage(user: _user)),
    );
    if (updated != null && mounted) setState(() => _liveUser = updated);
  }

  void _ouvrir(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  /// Retour à l'écran de connexion. La session du compte y reste proposée
  /// (sans mot de passe), sauf s'il vient d'être supprimé.
  Future<void> _deconnecter({bool compteSupprime = false}) async {
    final bloc = context.read<AuthBloc>();
    final navigateur = Navigator.of(context);
    final fin = bloc.stream.firstWhere(
      (s) => s is AuthInitial || s is AuthFailure,
    );
    bloc.add(
      LogoutRequested(compteQuitte: _user, compteSupprime: compteSupprime),
    );
    await fin;
    navigateur.pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
    final ctx = navigateur.context;
    if (ctx.mounted) {
      compteSupprime
          ? afficherSucces(
              ctx,
              'Votre compte a été supprimé.',
              titre: 'Compte supprimé',
            )
          : afficherSucces(
              ctx,
              'Vous êtes déconnecté. À bientôt !',
              titre: 'Déconnexion',
            );
    }
  }

  /// Quitte ce compte sans fermer sa session, puis l'écran de connexion
  /// propose les comptes du téléphone.
  Future<void> _changerDeCompte() async {
    final bloc = context.read<AuthBloc>();
    final navigateur = Navigator.of(context);
    final fin = bloc.stream.firstWhere(
      (s) => s is AuthInitial || s is AuthFailure,
    );
    bloc.add(ChangementDeCompteDemande(compteQuitte: _user));
    await fin;
    navigateur.pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
    final ctx = navigateur.context;
    if (ctx.mounted) {
      afficherInfo(
        ctx,
        'Choisissez le compte à utiliser.',
        titre: 'Changer de compte',
      );
    }
  }

  Future<void> _onLogout() async {
    final ok = await confirmerAction(
      context,
      icone: Icons.logout_rounded,
      titre: 'Se déconnecter ?',
      message:
          'Votre compte restera proposé sur l\'écran de connexion : vous y reviendrez d\'un toucher, sans mot de passe.',
      action: 'Se déconnecter',
    );
    if (ok && mounted) _deconnecter();
  }

  Future<void> _onSupprimerCompte() async {
    final ok = await confirmerAction(
      context,
      icone: Icons.delete_outline_rounded,
      titre: 'Supprimer votre compte ?',
      message:
          'Cette action est irréversible : votre profil et vos données personnelles seront supprimés.',
      action: 'Supprimer définitivement',
    );
    if (ok && mounted) _compteBloc.add(DeleteAccountRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompteBloc, CompteState>(
      bloc: _compteBloc,
      listener: (context, state) {
        if (state is CompteLoaded) {
          setState(() => _liveUser = state.user);
        } else if (state is CompteAccountDeleted) {
          _deconnecter(compteSupprime: true);
        } else if (state is CompteError) {
          afficherErreur(context, state.message);
        }
      },
      // Un glissé de la gauche vers la droite, n'importe où sur l'écran,
      // ramène à l'accueil.
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) {
            Navigator.of(context).maybePop();
          }
        },
        // L'en-tête bleu des autres pages, avec le profil dedans, comme le
        // compte acheteur. Il s'ouvrait sur deux cartes marine empilées
        // (solde puis profil), sous une barre blanche.
        child: PageVendeur(
          titre: 'Mon compte',
          titreWidget: EnteteCompte(
            nom: _nomComplet,
            initiales: _initiales,
            email: _user?.email ?? '',
            role: _user?.role ?? 'VENDEUR',
            photo: _user?.photoProfil,
          ),
          actions: [
            BoutonEnteteVendeur(
              icone: Icons.edit_rounded,
              infobulle: 'Modifier mon profil',
              onTap: _onEditProfil,
            ),
          ],
          corps: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, kEspaceBarreBas),
            children: [
              _CarteSolde(montant: _user?.soldeDisponible ?? 0),
              // Tant que la boutique n'est pas certifiée, l'invitation reste en
              // haut du compte : c'est ce qu'annonce le point rouge de l'accueil.
              if (_certification != null && _certification!.actionRequise) ...[
                const SizedBox(height: 12),
                _CarteCertification(
                  rejetee: _certification!.rejete,
                  onTap: _ouvrirCertification,
                ),
              ],
              const SizedBox(height: 24),
              SectionProfil(
                titre: 'Ma boutique',
                entrees: [
                  // Tant qu'une action est requise, le bandeau du haut fait
                  // déjà office d'entrée : pas de ligne en double.
                  if (!(_certification?.actionRequise ?? false))
                    LigneProfil(
                      icone: Icons.verified_outlined,
                      libelle: 'Certification',
                      sousTitre: switch (_certification?.statut) {
                        'approuve' => 'Votre boutique est certifiée',
                        'en_attente' => 'Demande en cours d\'examen',
                        _ => 'Faites certifier votre boutique',
                      },
                      fin: _certification?.certifie == true
                          ? const Icon(
                              Icons.verified_rounded,
                              color: AppColor.kSucces,
                            )
                          : null,
                      onTap: _ouvrirCertification,
                    ),
                  LigneProfil(
                    icone: Icons.storefront_outlined,
                    libelle: 'Ma boutique',
                    sousTitre: 'Nom, logo, catégories, pause',
                    onTap: () => _ouvrir(const MaBoutiquePage()),
                  ),
                  LigneProfil(
                    icone: Icons.workspace_premium_outlined,
                    libelle: 'Mon abonnement',
                    sousTitre: 'Formule et historique des paiements',
                    onTap: () => _ouvrir(const MonAbonnementPage()),
                  ),
                  LigneProfil(
                    icone: Icons.notifications_none_rounded,
                    libelle: 'Notifications',
                    sousTitre: 'Nouvelles commandes et alertes',
                    onTap: () =>
                        _ouvrir(const NotificationsPage(pourVendeur: true)),
                  ),
                  LigneProfil(
                    icone: Icons.chat_bubble_outline_rounded,
                    libelle: 'Messages',
                    sousTitre: 'Vos conversations avec vos clients',
                    onTap: () =>
                        _ouvrir(const ConversationsPage(pourVendeur: true)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionProfil(
                titre: 'Sécurité',
                entrees: [
                  LigneProfil(
                    icone: Icons.lock_outline_rounded,
                    libelle: 'Mot de passe',
                    sousTitre: 'Modifier votre mot de passe',
                    onTap: () => _ouvrir(const ChangePasswordPage()),
                  ),
                  LigneProfil(
                    icone: Icons.delete_outline_rounded,
                    libelle: 'Supprimer mon compte',
                    sousTitre: 'Suppression définitive de vos données',
                    danger: true,
                    onTap: _onSupprimerCompte,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionProfil(
                titre: 'Aide et informations',
                entrees: [
                  LigneProfil(
                    icone: Icons.help_outline_rounded,
                    libelle: 'Centre d\'aide',
                    sousTitre: 'Questions fréquentes',
                    onTap: () => _ouvrir(const AidePage()),
                  ),
                  LigneProfil(
                    icone: Icons.support_agent_outlined,
                    libelle: 'Nous contacter',
                    sousTitre: 'WhatsApp, e-mail ou téléphone',
                    onTap: () =>
                        _ouvrir(const AidePage(contactSeulement: true)),
                  ),
                  LigneProfil(
                    icone: Icons.star_border_rounded,
                    libelle: 'Noter l\'application',
                    sousTitre: 'Votre avis compte',
                    onTap: () => UrlExterne.lancer(InfosApp.lienPlayStore),
                  ),
                  LigneProfil(
                    icone: Icons.info_outline_rounded,
                    libelle: 'À propos',
                    sousTitre:
                        'Version ${InfosApp.version}, conditions, confidentialité',
                    onTap: () => _ouvrir(const AProposPage()),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              BoutonChangerCompte(onPressed: _changerDeCompte),
              const SizedBox(height: 10),
              BoutonDeconnexion(onPressed: _onLogout),
              const SizedBox(height: 12),
              const VersionApp(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Montant disponible sur le compte du vendeur, en tête de l'onglet Compte.
///
/// Rien ne l'alimente encore : le serveur expose la colonne, les reversements
/// seront traités plus tard. D'où l'absence de bouton de retrait — afficher
/// une action qui ne fait rien serait pire que de n'en afficher aucune — et,
/// à zéro, la ligne qui explique pourquoi.
///
/// Carte blanche sous l'en-tête : en marine, elle se confondrait avec lui.
class _CarteSolde extends StatelessWidget {
  final double montant;
  const _CarteSolde({required this.montant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColor.kSecondaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColor.kSecondaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Montant disponible',
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscale40,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formaterPrix(montant),
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                if (montant <= 0) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Vos encaissements apparaîtront ici.',
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 12,
                      color: AppColor.kGrayscale40,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Invitation à faire certifier la boutique, en haut du compte.
class _CarteCertification extends StatelessWidget {
  final bool rejetee;
  final VoidCallback onTap;
  const _CarteCertification({required this.rejetee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.kErreurLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColor.kErreur,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: AppColor.kWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rejetee
                          ? 'Certification refusée'
                          : 'Faites certifier votre boutique',
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rejetee
                          ? 'Renvoyez les photos de votre pièce d\'identité.'
                          : 'Envoyez votre pièce d\'identité (recto et verso) pour '
                                'gagner la confiance de vos clients.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF5B6C8A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColor.kErreur),
            ],
          ),
        ),
      ),
    );
  }
}
