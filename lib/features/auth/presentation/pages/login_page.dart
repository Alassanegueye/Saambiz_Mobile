import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/services/comptes_memorises.dart';
import '../../../../core/services/session_service.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/boutons_connexion_sociale.dart';
import '../widgets/choix_compte.dart';
import '../widgets/mise_en_page_auth.dart';

/// Connexion : en-tete marine (logo, titre), puis une feuille blanche
/// arrondie qui porte e-mail ou telephone et mot de passe, puis Google / Apple
/// sous un separateur « ou » ; l'inscription est proposee en bas de page.
///
/// Si des comptes ont deja servi sur ce telephone (clients comme vendeurs),
/// la carte les propose d'abord : on touche celui ou l'on revient. Session
/// restee ouverte (« Changer de compte ») : on entre directement. Sinon le
/// formulaire s'ouvre, pre-rempli.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifiantController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focusMotDePasse = FocusNode();

  /// Comptes deja utilises sur ce telephone.
  List<CompteMemorise> _comptes = const [];

  /// `null` tant que la liste n'est pas lue : rien ne clignote.
  bool? _formulaireVisible;

  @override
  void initState() {
    super.initState();
    _chargerComptes();
  }

  Future<void> _chargerComptes() async {
    final comptes = await sl<ComptesMemorises>().lister();
    if (!mounted) return;
    setState(() {
      _comptes = comptes;
      _formulaireVisible ??= comptes.isEmpty;
    });
  }

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    _focusMotDePasse.dispose();
    super.dispose();
  }

  void _choisirCompte(CompteMemorise compte) {
    context.read<AuthBloc>().add(RepriseCompteDemandee(compte));
  }

  /// Ouvre le formulaire pre-rempli pour ce compte.
  void _reconnecter(CompteMemorise compte) {
    setState(() {
      _formulaireVisible = true;
      _identifiantController.text = compte.identifiant;
      _passwordController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusMotDePasse.requestFocus();
    });
  }

  Future<void> _retirerCompte(CompteMemorise compte) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer ce compte ?'),
        content: Text(
          '${compte.nomComplet} ne sera plus proposé sur ce téléphone, et '
          'sa session y sera fermée : il faudra son mot de passe pour y '
          'revenir. Le compte lui-même n\'est pas supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    sl<SessionService>().fermerSessionMemorisee(compte).ignore();
    await sl<ComptesMemorises>().oublier(compte.id);
    if (!mounted) return;
    setState(() {
      _comptes = _comptes.where((c) => c.id != compte.id).toList();
      if (_comptes.isEmpty) _formulaireVisible = true;
    });
  }

  void _onLoginPressed() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final input = _identifiantController.text.trim();
    // E-mail ou telephone : le serveur attend l'un ou l'autre.
    final isEmail = RegExp(r'\S+@\S+\.\S+').hasMatch(input);
    context.read<AuthBloc>().add(
      LoginRequested(
        email: isEmail ? input : null,
        telephone: isEmail ? null : input,
        mot_de_passe: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kPrimary,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev != curr,
        listener: (context, state) {
          // AuthBloc est global : cette page ne reagit que lorsqu'elle est la
          // route visible.
          if (ModalRoute.of(context)?.isCurrent != true) return;

          if (state is AuthSuccess) {
            final role = state.user.role.toUpperCase();
            final String? route = switch (role) {
              'ACHETEUR' || 'CLIENT' => AppRouter.acheteurRoute,
              'VENDEUR' => AppRouter.vendeurRoute,
              _ => null,
            };
            if (route == null) {
              showToast(
                context,
                'Échec de la connexion',
                'Ce type de compte ne peut pas se connecter à l\'application.',
                ToastificationType.error,
              );
              return;
            }
            showToast(
              context,
              'Connexion réussie',
              'Bienvenue sur SaamBiz !',
              ToastificationType.success,
            );
            Navigator.of(context).pushNamedAndRemoveUntil(
              route,
              (_) => false,
              arguments: state.user,
            );
          } else if (state is AuthCompteAReconnecter) {
            _reconnecter(state.compte);
            if (state.message != null) {
              showToast(
                context,
                'Reconnexion nécessaire',
                state.message!,
                ToastificationType.info,
              );
            }
            _chargerComptes(); // le compte a perdu sa session
          } else if (state is AuthConnexionIndisponible) {
            showToast(
              context,
              'Bientôt disponible',
              state.message,
              ToastificationType.info,
            );
          } else if (state is AuthFailure) {
            showToast(
              context,
              'Échec de la connexion',
              state.message.trim().isEmpty
                  ? 'Identifiant ou mot de passe incorrect.'
                  : state.message,
              ToastificationType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final choix = _formulaireVisible == false && _comptes.isNotEmpty;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            // En-tête marine : icônes de la barre d'état en blanc.
            value: SystemUiOverlayStyle.light,
            child: LayoutBuilder(
              builder: (context, contraintes) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: contraintes.maxHeight),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _EnteteConnexion(
                              titre: choix ? 'Bon retour !' : 'Connexion',
                              sousTitre: choix
                                  ? 'Touchez votre compte pour y revenir.'
                                  : 'Vos boutiques, commandes et favoris '
                                        'vous attendent.',
                            ),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColor.kWhite,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(32),
                                  ),
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  24,
                                  28,
                                  24,
                                  16 + MediaQuery.paddingOf(context).bottom,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_formulaireVisible != null)
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        child: choix
                                            ? ChoixCompte(
                                                key: const ValueKey('choix'),
                                                comptes: _comptes,
                                                avecEntete: false,
                                                occupe: isLoading,
                                                compteEnCours:
                                                    state is AuthRepriseEnCours
                                                    ? state.idCompte
                                                    : null,
                                                onChoisir: _choisirCompte,
                                                onRetirer: _retirerCompte,
                                                onAutreCompte: () => setState(
                                                  () {
                                                    _formulaireVisible = true;
                                                    _identifiantController
                                                        .clear();
                                                    _passwordController.clear();
                                                  },
                                                ),
                                              )
                                            : KeyedSubtree(
                                                key: const ValueKey(
                                                  'formulaire',
                                                ),
                                                child: _formulaire(
                                                  isLoading,
                                                  state,
                                                ),
                                              ),
                                      ),
                                    const Spacer(),
                                    const SizedBox(height: 24),
                                    _CreerCompte(
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pushNamed(AppRouter.profileChoiceRoute),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formulaire(bool isLoading, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_comptes.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () => setState(() => _formulaireVisible = false),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Choisir un compte enregistré'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.kPrimary,
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ChampFormulaire(
          libelle: 'E-mail ou téléphone',
          hint: 'exemple@mail.com ou 77 000 00 00',
          controller: _identifiantController,
          icone: Icons.alternate_email_rounded,
          clavier: TextInputType.emailAddress,
          action: TextInputAction.next,
          autofill: const [AutofillHints.username, AutofillHints.email],
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'E-mail ou téléphone requis'
              : null,
        ),
        const SizedBox(height: 16),
        const LibelleChamp('Mot de passe'),
        ChampMotDePasse(
          controller: _passwordController,
          focusNode: _focusMotDePasse,
          action: TextInputAction.done,
          onSubmitted: (_) => _onLoginPressed(),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.forgotPasswordRoute),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Mot de passe oublié ?',
              style: TextStyle(
                fontFamily: kPolice,
                color: AppColor.kPrimaryMedium,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        BoutonAuth(
          texte: 'Se connecter',
          onPressed: _onLoginPressed,
          // Le bouton ne tourne que pour une connexion par mot de passe :
          // pendant Google / Apple, c'est leur bouton qui tourne.
          chargement: isLoading && state is! AuthSocialEnCours,
        ),
        // Google / Apple sous le formulaire, après un séparateur « ou ».
        const BoutonsConnexionSociale(),
      ],
    );
  }
}

/// En-tête marine : logo clair, nom de la marque, titre et sous-titre en
/// blanc, posés sur deux halos aux couleurs de la marque. La feuille blanche
/// du formulaire remonte ensuite par-dessus.
class _EnteteConnexion extends StatelessWidget {
  const _EnteteConnexion({required this.titre, required this.sousTitre});

  final String titre;
  final String sousTitre;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -120,
          right: -90,
          child: _Halo(
            taille: 300,
            couleur: AppColor.kSecondary.withValues(alpha: 0.28),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -100,
          child: _Halo(
            taille: 260,
            couleur: AppColor.kPrimaryMedium.withValues(alpha: 0.55),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/picto_clair.png',
                      height: 34,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 10),
                    const Text.rich(
                      TextSpan(
                        text: 'Saam',
                        children: [
                          TextSpan(
                            text: 'Biz',
                            style: TextStyle(color: AppColor.kSecondary),
                          ),
                        ],
                      ),
                      semanticsLabel: 'SaamBiz',
                      style: TextStyle(
                        fontFamily: kPolice,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColor.kWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 44),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    titre,
                    key: ValueKey(titre),
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                      height: 1.1,
                      color: AppColor.kWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sousTitre,
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 15,
                    height: 1.45,
                    color: AppColor.kWhite.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.taille, required this.couleur});

  final double taille;
  final Color couleur;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [couleur, couleur.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

/// Bas de page : lien d'inscription, sobre mais bien visible.
class _CreerCompte extends StatelessWidget {
  const _CreerCompte({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text.rich(
            TextSpan(
              text: 'Pas encore de compte ?  ',
              style: TextStyle(color: AppColor.kGrayscale40),
              children: [
                TextSpan(
                  text: 'Créer un compte',
                  style: TextStyle(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColor.kSecondary,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
            style: TextStyle(fontFamily: kPolice, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
