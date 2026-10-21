import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:saambiz/core/routes/app_router.dart';

import '../../../../../core/constants/infos_app.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/utils/url_externe.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart' show kEspaceBarreBas;
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
import '../../../../favoris/presentation/pages/favoris_page.dart';
import '../../../../messagerie/presentation/pages/conversations_page.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../promotions/presentation/pages/promotions_actives_page.dart';
import '../../../../signalements/presentation/pages/mes_signalements_page.dart';
import '../../../../commande/data/datasources/commande_remote_datasource.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../../../favoris/data/datasources/favoris_remote_datasource.dart';

/// Onglet « Compte » de l'acheteur : carte bleue d'en-tête, puis des groupes
/// d'entrées (construction de l'application Yobante Boutique).
class ProfilPage extends StatefulWidget {
  final User? user;
  const ProfilPage({super.key, this.user});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> with SingleTickerProviderStateMixin {
  late final CompteBloc _compteBloc = sl<CompteBloc>();
  User? _liveUser;

  // Compteurs de la carte bleue (comme Yobante Boutique).
  int _nbCommandes = 0;
  int _nbFavoris = 0;

  // Apparition en fondu de l'onglet.
  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
  late final Animation<double> _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _compteBloc.add(LoadCompte());
    _chargerCompteurs();
  }

  Future<void> _chargerCompteurs() async {
    try {
      final commandes = await sl<CommandeRemoteDataSource>().mesCommandes();
      if (mounted) setState(() => _nbCommandes = commandes.length);
    } catch (_) {/* compteur laissé à 0 */}
    try {
      final favoris = await sl<FavorisRemoteDataSource>().mesFavoris();
      if (mounted) setState(() => _nbFavoris = favoris.length);
    } catch (_) {/* compteur laissé à 0 */}
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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

  String _ouVide(String? v, String defaut) =>
      (v == null || v.trim().isEmpty) ? defaut : v;

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
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        appBar: AppAppBar(
          title: 'Compte',
          implyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Modifier mon profil',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _onEditProfil,
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
          physics: const BouncingScrollPhysics(),
          // Marge basse : la barre de navigation flotte au-dessus.
          padding: const EdgeInsets.fromLTRB(20, 8, 20, kEspaceBarreBas),
          children: [
            ListenableBuilder(
              listenable: sl<PanierService>(),
              builder: (_, __) => CarteEnteteProfil(
                nom: _nomComplet,
                initiales: _initiales,
                email: _user?.email ?? '',
                role: _user?.role ?? 'ACHETEUR',
                photo: _user?.photoProfil,
                onTap: _onEditProfil,
                compteurs: [
                  ('Commandes', '$_nbCommandes'),
                  ('Favoris', '$_nbFavoris'),
                  ('Panier', '${sl<PanierService>().nombreArticles}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionProfil(
              titre: 'Informations personnelles',
              entrees: [
                LigneProfil(
                  icone: Icons.person_outline_rounded,
                  libelle: _nomComplet,
                  sousTitre: 'Prénom & nom',
                  onTap: _onEditProfil,
                ),
                LigneProfil(
                  icone: Icons.email_outlined,
                  libelle: _ouVide(_user?.email, 'Non renseigné'),
                  sousTitre: 'Adresse e-mail',
                  onTap: _onEditProfil,
                ),
                LigneProfil(
                  icone: Icons.phone_outlined,
                  libelle: _ouVide(_user?.telephone, 'Non renseigné'),
                  sousTitre: 'Téléphone',
                  onTap: _onEditProfil,
                ),
                LigneProfil(
                  icone: Icons.location_on_outlined,
                  libelle: _ouVide(_user?.adresse, 'Non renseignée'),
                  sousTitre: 'Adresse du domicile',
                  onTap: _onEditProfil,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionProfil(
              titre: 'Mon activité',
              entrees: [
                LigneProfil(
                  icone: Icons.favorite_border_rounded,
                  libelle: 'Mes favoris',
                  sousTitre: 'Boutiques que vous suivez',
                  onTap: () => _ouvrir(const FavorisPage()),
                ),
                LigneProfil(
                  icone: Icons.local_offer_outlined,
                  libelle: 'Promotions actives',
                  sousTitre: 'Bons plans du moment',
                  onTap: () => _ouvrir(const PromotionsActivesPage()),
                ),
                LigneProfil(
                  icone: Icons.notifications_none_rounded,
                  libelle: 'Notifications',
                  sousTitre: 'Vos alertes récentes',
                  onTap: () => _ouvrir(const NotificationsPage()),
                ),
                LigneProfil(
                  icone: Icons.chat_bubble_outline_rounded,
                  libelle: 'Messages',
                  sousTitre: 'Vos conversations avec les vendeurs',
                  onTap: () => _ouvrir(const ConversationsPage()),
                ),
                LigneProfil(
                  icone: Icons.flag_outlined,
                  libelle: 'Mes signalements',
                  sousTitre: 'Contenus que vous avez signalés',
                  onTap: () => _ouvrir(const MesSignalementsPage()),
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
              titre: 'Application',
              entrees: [
                const LigneProfil(
                  icone: Icons.language_outlined,
                  libelle: 'Langue',
                  sousTitre: 'Français',
                ),
                LigneProfil(
                  icone: Icons.info_outline_rounded,
                  libelle: 'À propos',
                  sousTitre: 'Version ${InfosApp.version}, conditions, confidentialité',
                  onTap: () => _ouvrir(const AProposPage()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionProfil(
              titre: 'Aide & Support',
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
                  sousTitre: 'Service client',
                  onTap: () => _ouvrir(const AidePage(contactSeulement: true)),
                ),
                LigneProfil(
                  icone: Icons.star_border_rounded,
                  libelle: 'Noter l\'application',
                  sousTitre: 'Votre avis compte',
                  onTap: () => UrlExterne.lancer(InfosApp.lienPlayStore),
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
      ),
    );
  }
}
