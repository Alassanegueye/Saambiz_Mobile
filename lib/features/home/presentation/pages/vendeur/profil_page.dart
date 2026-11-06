import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:saambiz/core/routes/app_router.dart';

import '../../../../../core/constants/infos_app.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/utils/url_externe.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart'
    show kEspaceBarreBas;
import '../../../../../core/widgets/profil_kit.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
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

/// Onglet « Compte » du vendeur : carte bleue d'en-tête, puis des groupes
/// d’entrées dans des cartes blanches.
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

  @override
  void initState() {
    super.initState();
    _compteBloc.add(LoadCompte());
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

  void _deconnecter() {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
  }

  Future<void> _onLogout() async {
    final ok = await confirmerAction(
      context,
      icone: Icons.logout_rounded,
      titre: 'Se déconnecter ?',
      message: 'Vous devrez vous reconnecter pour accéder à votre compte.',
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
          _deconnecter();
        } else if (state is CompteError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        appBar: AppAppBar(title: 'Compte', implyLeading: false),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, kEspaceBarreBas),
          children: [
            _CarteSolde(montant: _user?.soldeDisponible ?? 0),
            const SizedBox(height: 14),
            CarteEnteteProfil(
              nom: _nomComplet,
              initiales: _initiales,
              email: _user?.email ?? '',
              role: _user?.role ?? 'VENDEUR',
              photo: _user?.photoProfil,
              onTap: _onEditProfil,
            ),
            const SizedBox(height: 24),
            SectionProfil(
              titre: 'Ma boutique',
              entrees: [
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
                  onTap: () => _ouvrir(const NotificationsPage()),
                ),
                LigneProfil(
                  icone: Icons.chat_bubble_outline_rounded,
                  libelle: 'Messages',
                  sousTitre: 'Vos conversations avec vos clients',
                  onTap: () => _ouvrir(const ConversationsPage()),
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
                  onTap: () => _ouvrir(const AidePage(contactSeulement: true)),
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
            BoutonDeconnexion(onPressed: _onLogout),
            const SizedBox(height: 12),
            const VersionApp(),
          ],
        ),
      ),
    );
  }
}

/// Montant disponible sur le compte du vendeur, en tete de l'onglet Compte.
///
/// Rien ne l'alimente encore : le serveur expose la colonne, les reversements
/// seront traites plus tard. D'ou l'absence de bouton de retrait — afficher
/// une action qui ne fait rien serait pire que de n'en afficher aucune — et la
/// ligne qui explique pourquoi le montant est a zero.
class _CarteSolde extends StatelessWidget {
  final double montant;
  const _CarteSolde({required this.montant});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      decoration: BoxDecoration(
        color: AppColor.kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColor.kSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Montant disponible',
                style: TextStyle(fontFamily: kPolice, 
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kWhite.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            formaterPrix(montant),
            style: TextStyle(fontFamily: kPolice, 
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColor.kWhite,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vos encaissements apparaîtront ici.',
            style: TextStyle(fontFamily: kPolice, 
              fontSize: 11.8,
              color: AppColor.kWhite.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
