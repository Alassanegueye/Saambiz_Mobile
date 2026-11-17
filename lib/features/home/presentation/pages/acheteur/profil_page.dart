import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:saambiz/core/routes/app_router.dart';

import '../../../../../core/constants/infos_app.dart';
import '../../../../../core/utils/url_externe.dart';
import '../../../../../core/widgets/entete_compte.dart';
import '../../../../../core/widgets/page_vendeur.dart';
import '../../../../../core/theme/police.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart'
    show kEspaceBarreBas;
import '../../../../../core/widgets/profil_kit.dart';
import '../../../../../core/widgets/activer_localisation.dart';
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
import '../../../../messagerie/presentation/pages/conversations_page.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../promotions/presentation/pages/promotions_actives_page.dart';
import '../../../../signalements/presentation/pages/mes_signalements_page.dart';
import 'main_client_page.dart' show ongletAcheteurDemande;
import '../../../../commande/data/datasources/commande_remote_datasource.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../../../favoris/data/datasources/favoris_remote_datasource.dart';

/// Onglet « Compte » de l'acheteur : carte bleue d'en-tête, puis des groupes
/// d’entrées dans des cartes blanches.
class ProfilPage extends StatefulWidget {
  final User? user;
  const ProfilPage({super.key, this.user});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage>
    with SingleTickerProviderStateMixin, RetourSurOnglet {
  @override
  void surRetourOnglet() => _compteBloc.add(LoadCompte());

  late final CompteBloc _compteBloc = sl<CompteBloc>();
  User? _liveUser;

  // Compteurs de la carte d’en-tête.
  int _nbCommandes = 0;
  int _nbFavoris = 0;

  // Apparition en fondu de l'onglet.
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _compteBloc.add(LoadCompte());
    _chargerCompteurs();
  }

  Future<void> _chargerCompteurs() async {
    try {
      // Le TOTAL, pas la page : la liste est paginee par dix, et compter
      // les elements recus donnerait « 10 » a qui en a cent.
      final page = await sl<CommandeRemoteDataSource>().mesCommandes();
      if (mounted) setState(() => _nbCommandes = page.pagination.total);
    } catch (_) {
      /* compteur laissé à 0 */
    }
    try {
      // Le TOTAL, pas la page : la liste est paginee par dix.
      final page = await sl<FavorisRemoteDataSource>().mesFavoris();
      if (mounted) setState(() => _nbFavoris = page.pagination.total);
    } catch (_) {
      /* compteur laissé à 0 */
    }
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
      // L'en-tête bleu des autres onglets, avec le profil dedans : le seul
      // onglet sur fond clair, sous un titre centré, c'était celui-ci.
      child: PageVendeur(
        titre: 'Mon compte',
        titreWidget: EnteteCompte(
          nom: _nomComplet,
          initiales: _initiales,
          email: _user?.email ?? '',
          role: _user?.role ?? 'ACHETEUR',
          photo: _user?.photoProfil,
        ),
        actions: [
          BoutonEnteteVendeur(
            icone: Icons.edit_rounded,
            infobulle: 'Modifier mon profil',
            onTap: _onEditProfil,
          ),
        ],
        corps: FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, kEspaceBarreBas),
            children: [
              ListenableBuilder(
                listenable: sl<PanierService>(),
                builder: (_, __) => _Compteurs(
                  entrees: [
                    (
                      Icons.receipt_long_outlined,
                      'Commandes',
                      '$_nbCommandes',
                      () => ongletAcheteurDemande.value = 3,
                    ),
                    (
                      Icons.favorite_border_rounded,
                      'Favoris',
                      '$_nbFavoris',
                      () => ongletAcheteurDemande.value = 2,
                    ),
                    (
                      Icons.shopping_cart_outlined,
                      'Panier',
                      '${sl<PanierService>().nombreArticles}',
                      () => Navigator.of(
                        context,
                      ).pushNamed(AppRouter.panierRoute),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionProfil(
                titre: 'Mon activité',
                entrees: [
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
                  // La section « Près de chez vous » de l'accueil en dépend.
                  LigneProfil(
                    icone: localisationActivee()
                        ? Icons.my_location_rounded
                        : Icons.location_off_outlined,
                    libelle: 'Géolocalisation',
                    sousTitre: localisationActivee()
                        ? 'Activée — touchez pour mettre à jour votre position'
                        : 'Activer pour voir les boutiques près de chez vous',
                    onTap: () async {
                      await activerLocalisation(context);
                      if (mounted) setState(() {});
                    },
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
                    sousTitre: 'Service client',
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

/// Les compteurs du compte, côte à côte dans une carte blanche ; chacun
/// mène à ce qu'il compte.
class _Compteurs extends StatelessWidget {
  final List<(IconData, String, String, VoidCallback)> entrees;
  const _Compteurs({required this.entrees});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < entrees.length; i++) ...[
              if (i > 0)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColor.kLine,
                ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: entrees[i].$4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            entrees[i].$1,
                            size: 20,
                            color: AppColor.kPrimaryMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entrees[i].$3,
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColor.kGrayscaleDark100,
                            ),
                          ),
                          Text(
                            entrees[i].$2,
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 12.5,
                              color: AppColor.kGrayscale40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
