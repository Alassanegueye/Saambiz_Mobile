import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/services/comptes_memorises.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/email.dart';
import '../../../../core/utils/telephone.dart';
import '../../../../core/widgets/bouton_indicatif.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
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

  /// Onglet choisi au-dessus du champ identifiant : e-mail ou telephone.
  bool _parTelephone = false;

  /// Pays du numéro, en mode téléphone.
  final _paysTel = ValueNotifier<PaysTelephone>(senegal);

  void _choisirMode(bool parTelephone) {
    if (parTelephone == _parTelephone) return;
    setState(() {
      _parTelephone = parTelephone;
      _identifiantController.clear();
    });
  }

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
    _paysTel.dispose();
    super.dispose();
  }

  void _choisirCompte(CompteMemorise compte) {
    context.read<AuthBloc>().add(RepriseCompteDemandee(compte));
  }

  /// Ouvre le formulaire pre-rempli pour ce compte.
  void _reconnecter(CompteMemorise compte) {
    setState(() {
      _formulaireVisible = true;
      _parTelephone = !compte.identifiant.contains('@');
      if (_parTelephone) {
        final lu = lireTelephone(compte.identifiant);
        _paysTel.value = lu.pays;
        _identifiantController.text = lu.national;
      } else {
        _identifiantController.text = compte.identifiant;
      }
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
    // E-mail ou telephone, selon l'onglet choisi : le serveur attend l'un ou
    // l'autre.
    context.read<AuthBloc>().add(
      LoginRequested(
        email: _parTelephone ? null : input.toLowerCase(),
        telephone: _parTelephone
            ? telephoneInternational(input, _paysTel.value)
            : null,
        mot_de_passe: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Blanc comme la feuille du formulaire : quand le clavier monte, ce qui
      // se voit derrière ses coins arrondis est la feuille, pas un liseré bleu.
      backgroundColor: AppColor.kWhite,
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
                        child: ColoredBox(
                          // Le bleu de l'en-tête, derrière les coins arrondis
                          // de la feuille blanche.
                          color: AppColor.kPrimary,
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _EnteteConnexion(
                              titre: choix ? 'Bon retour !' : 'Connexion',
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
                                  20,
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
                                    const SizedBox(height: 8),
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
        _ChoixIdentifiant(
          parTelephone: _parTelephone,
          onChange: isLoading ? null : _choisirMode,
        ),
        const SizedBox(height: 14),
        // La cle reconstruit le champ a chaque changement d'onglet : le
        // clavier et l'erreur affichee repartent de zero.
        ChampFormulaire(
          key: ValueKey(_parTelephone),
          libelle: _parTelephone ? 'Numéro de téléphone' : 'E-mail',
          hint: _parTelephone ? _paysTel.value.exemple : 'exemple@mail.com',
          prefixe: _parTelephone
              ? BoutonIndicatif(
                  pays: _paysTel,
                  onChange: () => setState(_identifiantController.clear),
                )
              : null,
          formats: _parTelephone ? [FormatTelephone(_paysTel)] : formatsEmail,
          controller: _identifiantController,
          icone: _parTelephone
              ? Icons.smartphone_outlined
              : Icons.mail_outline_rounded,
          clavier: _parTelephone
              ? TextInputType.phone
              : TextInputType.emailAddress,
          action: TextInputAction.next,
          autofill: _parTelephone
              ? const [AutofillHints.telephoneNumber]
              : const [AutofillHints.username, AutofillHints.email],
          validator: (v) {
            if (_parTelephone) return verifierTelephone(v, _paysTel.value);
            return verifierEmail(v);
          },
        ),
        const SizedBox(height: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Mot de passe oublié ?',
              style: TextStyle(
                fontFamily: kPolice,
                color: AppColor.kPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        BoutonAuth(
          texte: 'Se connecter',
          onPressed: _onLoginPressed,
          // Le bouton ne tourne que pour une connexion par mot de passe :
          // pendant Google / Apple, c'est leur bouton qui tourne.
          chargement: isLoading && state is! AuthSocialEnCours,
          // Jaune de la marque sur fond blanc, texte marine.
          fond: AppColor.kSecondary,
          couleurTexte: AppColor.kPrimary,
        ),
      ],
    );
  }
}

/// En-tête marine : pictogramme seul, titre en
/// blanc, avec un trait jaune sous le titre. La feuille blanche du
/// formulaire remonte ensuite par-dessus.
class _EnteteConnexion extends StatelessWidget {
  const _EnteteConnexion({required this.titre});

  final String titre;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
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
                  ],
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    titre,
                    key: ValueKey(titre),
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                      height: 1.1,
                      color: AppColor.kWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.kSecondary,
                    borderRadius: BorderRadius.circular(2),
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

/// Deux onglets en pilule, « E-mail » et « Téléphone », au-dessus du champ
/// identifiant.
class _ChoixIdentifiant extends StatelessWidget {
  const _ChoixIdentifiant({required this.parTelephone, this.onChange});

  final bool parTelephone;
  final ValueChanged<bool>? onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.kLine),
      ),
      child: Row(
        children: [_onglet('E-mail', false), _onglet('Téléphone', true)],
      ),
    );
  }

  Widget _onglet(String texte, bool valeur) {
    final actif = parTelephone == valeur;
    final couleur = actif ? AppColor.kWhite : AppColor.kGrayscale60;
    return Expanded(
      child: Semantics(
        button: true,
        selected: actif,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChange == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onChange!(valeur);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 38,
            decoration: BoxDecoration(
              color: actif ? AppColor.kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              texte,
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: couleur,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
