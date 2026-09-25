import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:saambiz/core/routes/app_router.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../../injection_container.dart';
import '../../../../compte/presentation/bloc/compte_bloc.dart';
import '../../../../compte/presentation/bloc/compte_event.dart';
import '../../../../compte/presentation/bloc/compte_state.dart';
import '../../../../compte/presentation/pages/edit_profil_page.dart';
import '../../../../compte/presentation/pages/change_password_page.dart';
import '../../../../boutique/presentation/pages/ma_boutique_page.dart';
import '../../../../vitrine/presentation/pages/ma_vitrine_page.dart';
import '../../../../abonnement/presentation/pages/mon_abonnement_page.dart';
import '../../../../promotions/presentation/pages/mes_promotions_page.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../messagerie/presentation/pages/conversations_page.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const green      = Color(0xFF1B3A6B);
  static const greenLight = Color(0xFFE8EEF7);
  static const greenText  = Color(0xFF12294D);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7F2);
  static const surface    = Color(0xFFF7F9F5);
  static const border     = Color(0xFFF0F4EC);
  static const label      = Color(0xFF9EAA94);
  static const sub        = Color(0xFF7A8473);
  static const placeholder= Color(0xFFC2CCBA);
  static const red        = Color(0xFFE53935);
  static const redLight   = Color(0xFFFEF3F2);
  static const blue       = Color(0xFF1976D2);
  static const blueLight  = Color(0xFFE3F2FD);
  static const orange     = Color(0xFFFF8F00);
  static const orangeLight= Color(0xFFFFF3E0);
}

// ══════════════════════════════════════════════════════════════════════════════
class ProfilPage extends StatefulWidget {
  final User? user;
  const ProfilPage({super.key, this.user});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage>
    with SingleTickerProviderStateMixin {
  // Préférences
  bool _notifsProduits   = true;
  bool _notifsCommandes  = true;
  bool _twoFactor        = false;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  late final CompteBloc _compteBloc = sl<CompteBloc>();
  User? _liveUser;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _compteBloc.add(LoadCompte());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _compteBloc.close();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  User? get _user => _liveUser ?? widget.user;

  Future<void> _onEditProfil() async {
    final updated = await Navigator.of(context).push<User>(
      MaterialPageRoute(builder: (_) => EditProfilePage(user: _user)),
    );
    if (updated != null) setState(() => _liveUser = updated);
  }

  void _onChangerMotDePasse() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
    );
  }

  // `User.nom` et `User.prenom` sont non-nullables : les `?? ''` et `?.` qui
  // traînaient ici étaient du code mort, signalé comme tel par l'analyseur. Le
  // seul cas à couvrir est l'absence de compte — un visiteur non connecté.
  String get _nomComplet {
    if (_user == null) return 'Invité';
    return '${_user!.prenom} ${_user!.nom}'.trim();
  }

  String get _initiales {
    if (_user == null) return '?';
    final p = _user!.prenom.isNotEmpty ? _user!.prenom[0] : '';
    final n = _user!.nom.isNotEmpty    ? _user!.nom[0]    : '';
    return '$p$n'.toUpperCase();
  }

  String get _email    => _user?.email     ?? 'Non renseigné';
  String get _telephone=> _user?.telephone ?? 'Non renseigné';
  String get _adresse  => _user?.adresse   ?? 'Non renseignée';

  void _onLogout() {
    showDialog(
      context: context,
      builder: (_) => _LogoutDialog(
        onConfirm: () {
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.loginRoute, (_) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompteBloc, CompteState>(
      bloc: _compteBloc,
      listener: (context, state) {
        if (state is CompteLoaded) {
          setState(() => _liveUser = state.user);
        } else if (state is CompteAccountDeleted) {
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.loginRoute, (_) => false,
          );
        } else if (state is CompteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                child: Column(
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 10),
                    _buildBoutiqueCard(),
                    const SizedBox(height: 10),
                    _buildSecuriteCard(),
                    const SizedBox(height: 10),
                    _buildPreferencesCard(),
                    const SizedBox(height: 10),
                    _buildAideCard(),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                    const SizedBox(height: 12),
                    _buildVersion(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      color: _C.black,
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -50, right: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.green.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: -10,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.green.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + bouton éditer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'Mon ',
                            style: GoogleFonts.sora(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: _C.white, letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Profil',
                            style: GoogleFonts.sora(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: _C.green, letterSpacing: -0.5,
                            ),
                          ),
                        ]),
                      ),
                      GestureDetector(
                        onTap: _onEditProfil,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              color: _C.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Avatar + infos
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: _C.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _C.green.withOpacity(0.35),
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _initiales,
                                style: GoogleFonts.sora(
                                  fontSize: 22, fontWeight: FontWeight.w800,
                                  color: _C.green,
                                ),
                              ),
                            ),
                          ),
                          // Badge vérifié
                          Positioned(
                            bottom: -2, right: -2,
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: _C.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _C.black, width: 2),
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: _C.white, size: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nomComplet,
                              style: GoogleFonts.sora(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: _C.white, letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _email,
                              style: GoogleFonts.dmSans(
                                fontSize: 12, color: _C.label,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Badge rôle
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _C.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _C.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined,
                                      color: _C.green, size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Acheteur',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: _C.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    children: [
                      Expanded(child: _buildStatBox('12', 'Commandes')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatBox('7', 'Favoris')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatBox('4.9', 'Note moy.')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: GoogleFonts.sora(
              fontSize: 18, fontWeight: FontWeight.w800, color: _C.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10, color: _C.label, fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Informations personnelles ──────────────────────────────────────────────
  Widget _buildInfoCard() {
    return _SectionCard(
      iconBg: _C.greenLight,
      icon: Icons.person_outline_rounded,
      iconColor: _C.green,
      title: 'Informations personnelles',
      children: [
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.person_outline_rounded,
          label: _nomComplet,
          sub: 'Prénom & Nom',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.email_outlined,
          label: _email,
          sub: 'Adresse e-mail',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.phone_outlined,
          label: _telephone,
          sub: 'Téléphone',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.location_on_outlined,
          label: _adresse,
          sub: 'Adresse',
          onTap: () {},
          isLast: true,
        ),
      ],
    );
  }

  // ── Ma boutique (boutique, abonnement, avis, promotions, notifs, messages) ─
  Widget _buildBoutiqueCard() {
    return _SectionCard(
      iconBg: _C.greenLight,
      icon: Icons.storefront_outlined,
      iconColor: _C.green,
      title: 'Ma boutique',
      children: [
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.storefront_outlined,
          label: 'Ma boutique',
          sub: 'Infos, horaires, pause/réactivation',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MaBoutiquePage()),
          ),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.language_rounded,
          label: 'Mon site web',
          sub: 'Votre boutique sur internet — gratuit',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MaVitrinePage()),
          ),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.workspace_premium_outlined,
          label: 'Mon abonnement',
          sub: 'Statut et renouvellement',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MonAbonnementPage()),
          ),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.local_offer_outlined,
          label: 'Mes promotions',
          sub: 'Créer et gérer vos promotions',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MesPromotionsPage()),
          ),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.notifications_none_rounded,
          label: 'Notifications',
          sub: 'Vos alertes récentes',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Messages',
          sub: 'Vos conversations avec les acheteurs',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConversationsPage()),
          ),
          isLast: true,
        ),
      ],
    );
  }

  // ── Sécurité ───────────────────────────────────────────────────────────────
  Widget _buildSecuriteCard() {
    return _SectionCard(
      iconBg: _C.blueLight,
      icon: Icons.shield_outlined,
      iconColor: _C.blue,
      title: 'Sécurité',
      children: [
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.lock_outline_rounded,
          label: 'Mot de passe',
          sub: 'Modifier votre mot de passe',
          onTap: _onChangerMotDePasse,
        ),
        _RowToggle(
          iconBg: _C.surface,
          icon: Icons.security_outlined,
          label: 'Authentification 2FA',
          sub: _twoFactor ? 'Activé' : 'Non activé',
          value: _twoFactor,
          onChanged: (v) => setState(() => _twoFactor = v),
        ),
        _RowItem(
          iconBg: _C.redLight,
          icon: Icons.delete_outline_rounded,
          label: 'Supprimer mon compte',
          sub: 'Suppression définitive de vos données',
          onTap: _onSupprimerCompte,
          isLast: true,
        ),
      ],
    );
  }

  // ── Suppression de compte (irréversible) ───────────────────────────────────
  Future<void> _onSupprimerCompte() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer votre compte ?'),
        content: const Text(
          'Cette action est irréversible : votre profil, votre boutique et '
          'vos données personnelles seront supprimés. Si vous avez des '
          'commandes en cours, vous devrez d\'abord les finaliser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _C.red),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirme == true && mounted) {
      _compteBloc.add(DeleteAccountRequested());
    }
  }

  // ── Préférences ────────────────────────────────────────────────────────────
  Widget _buildPreferencesCard() {
    return _SectionCard(
      iconBg: _C.orangeLight,
      icon: Icons.notifications_outlined,
      iconColor: _C.orange,
      title: 'Préférences',
      children: [
        _RowToggle(
          iconBg: _C.surface,
          icon: Icons.storefront_outlined,
          label: 'Alertes nouveaux produits',
          sub: _notifsProduits ? 'Activées' : 'Désactivées',
          value: _notifsProduits,
          onChanged: (v) => setState(() => _notifsProduits = v),
        ),
        _RowToggle(
          iconBg: _C.surface,
          icon: Icons.shopping_bag_outlined,
          label: 'Suivi de commandes',
          sub: _notifsCommandes ? 'Activé' : 'Désactivé',
          value: _notifsCommandes,
          onChanged: (v) => setState(() => _notifsCommandes = v),
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.language_outlined,
          label: 'Langue',
          sub: 'Français',
          onTap: () {},
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFE3EAD0)),
            ),
            child: Text(
              'FR',
              style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: _C.sub,
              ),
            ),
          ),
          isLast: true,
        ),
      ],
    );
  }

  // ── Aide & Support ─────────────────────────────────────────────────────────
  Widget _buildAideCard() {
    return _SectionCard(
      iconBg: const Color(0xFFF3E5F5),
      icon: Icons.help_outline_rounded,
      iconColor: const Color(0xFF7B1FA2),
      title: 'Aide & Support',
      children: [
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.help_outline_rounded,
          label: 'Centre d\'aide',
          sub: 'FAQ et guides',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Nous contacter',
          sub: 'Support client',
          onTap: () {},
        ),
        _RowItem(
          iconBg: _C.surface,
          icon: Icons.star_border_rounded,
          label: 'Noter l\'application',
          sub: 'Votre avis compte',
          onTap: () {},
          isLast: true,
        ),
      ],
    );
  }

  // ── Bouton déconnexion ─────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _onLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.redLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.red.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _C.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: _C.red, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Se déconnecter',
                style: GoogleFonts.sora(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _C.red,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _C.red, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Version ────────────────────────────────────────────────────────────────
  Widget _buildVersion() {
    return Center(
      child: Text(
        'SaamBiz v1.0.0',
        style: GoogleFonts.dmSans(
          fontSize: 11, color: _C.placeholder,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOG DÉCONNEXION
// ══════════════════════════════════════════════════════════════════════════════
class _LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _LogoutDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: _C.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: _C.redLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: _C.red, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Se déconnecter ?',
              style: GoogleFonts.sora(
                fontSize: 17, fontWeight: FontWeight.w800, color: _C.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous devrez vous reconnecter\npour accéder à votre compte.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13, color: _C.sub, height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE3EAD0)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: _C.sub,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _C.red,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Confirmer',
                        style: GoogleFonts.sora(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: _C.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPOSANTS RÉUTILISABLES
// ══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final Color    iconBg;
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final List<Widget> children;

  const _SectionCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F4EC)),
      ),
      child: Column(
        children: [
          // En-tête section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: _C.black,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF5F7F2)),
          ...children,
        ],
      ),
    );
  }
}

// ── Ligne standard avec chevron ────────────────────────────────────────────────
class _RowItem extends StatelessWidget {
  final Color    iconBg;
  final IconData icon;
  final String   label;
  final String   sub;
  final VoidCallback onTap;
  final bool     isLast;
  final Widget?  trailing;

  const _RowItem({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
    this.isLast   = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: Color(0xFFF5F7F2)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: _C.label),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: _C.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.dmSans(
                      fontSize: 11, color: _C.label,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else
              const Icon(Icons.chevron_right_rounded,
                  color: _C.placeholder, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Ligne avec toggle switch ───────────────────────────────────────────────────
class _RowToggle extends StatelessWidget {
  final Color    iconBg;
  final IconData icon;
  final String   label;
  final String   sub;
  final bool     value;
  final ValueChanged<bool> onChanged;
  final bool     isLast;

  const _RowToggle({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(color: Color(0xFFF5F7F2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _C.label),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _C.black,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: value ? _C.green : _C.label,
                    fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Switch custom
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44, height: 24,
              decoration: BoxDecoration(
                color: value ? _C.green : const Color(0xFFE3EAD0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _C.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}