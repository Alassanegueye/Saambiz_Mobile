import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/PasswordTextField.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const green       = Color(0xFF1B3A6B);
  static const greenLight  = Color(0xFFE8EEF7);
  static const greenBorder = Color(0xFFB8EDD0);
  static const greenText   = Color(0xFF12294D);
  static const greenGlow   = Color(0x141B3A6B);
  static const black       = Color(0xFF1A1A1A);
  static const white       = Color(0xFFFFFFFF);
  static const bg          = Color(0xFFF5F7F2);
  static const surface     = Color(0xFFF7F9F5);
  static const border      = Color(0xFFE3EAD0);
  static const label       = Color(0xFF1A1A1A);
  static const placeholder = Color(0xFFC2CCBA);
  static const sub         = Color(0xFF7A8473);
  static const divider     = Color(0xFFEDF0E8);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _identifiantController = TextEditingController();
  final _passwordController    = TextEditingController();
  final _formKey               = GlobalKey<FormState>();

  final _identifiantFocus = FocusNode();
  final _passwordFocus    = FocusNode();

  late AnimationController _masterCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _scaleAnim;

  // Staggered card animations
  late AnimationController _cardCtrl;
  late Animation<double>   _cardFade;
  late Animation<Offset>   _cardSlide;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim  = CurvedAnimation(parent: _masterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _masterCtrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _masterCtrl, curve: Curves.easeOutCubic));

    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _masterCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardCtrl.forward();
    });

    _identifiantFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    _identifiantFocus.dispose();
    _passwordFocus.dispose();
    _masterCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      final input = _identifiantController.text.trim();

      // Détecter si c'est un email ou un téléphone
      final isEmail = RegExp(r'\S+@\S+\.\S+').hasMatch(input);

      context.read<AuthBloc>().add(
        LoginRequested(
          email: isEmail ? input : null,
          telephone: isEmail ? null : input,
          mot_de_passe: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            final user = state.user;

            // Vérifier le rôle de l'utilisateur
            if (user.role == 'Acheteur') {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.acheteurRoute,
                    (_) => false,
                arguments: user,
              );
              showToast(
                context,
                'Connexion réussie',
                'Bienvenue acheteur !',
                ToastificationType.success,
              );
            } else if (user.role == 'Vendeur') {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.vendeurRoute,
                    (_) => false,
                arguments: user,
              );
              showToast(
                context,
                'Connexion réussie',
                'Bienvenue vendeur !',
                ToastificationType.success,
              );
            } else {
              // Aucun rôle reconnu → rediriger vers login
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.loginRoute,
                    (_) => false,
              );
              showToast(
                context,
                'Échec de la connexion',
                'Rôle utilisateur non reconnu.',
                ToastificationType.error,
              );
            }
          } else if (state is AuthFailure) {
            showToast(
              context,
              'Échec de la connexion',
              'Identifiant ou mot de passe incorrect.',
              ToastificationType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 44),
                              _buildLogo(),
                              const SizedBox(height: 18),
                              _buildBadge(),
                              const SizedBox(height: 22),
                              _buildHeader(),
                              const SizedBox(height: 32),
                              FadeTransition(
                                opacity: _cardFade,
                                child: SlideTransition(
                                  position: _cardSlide,
                                  child: _buildCard(isLoading),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bouton retour (visible seulement si la page a été empilée)
              if (Navigator.of(context).canPop())
                Positioned(
                  top: 0, left: 4,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: _C.black),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Fond décoratif ──────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1B3A6B).withOpacity(0.06),
                  const Color(0xFF1B3A6B).withOpacity(0.0),
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          right: -90,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1B3A6B).withOpacity(0.07),
                  const Color(0xFF1B3A6B).withOpacity(0.0),
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Motif de points décoratifs (top-right)
        Positioned(
          top: 60,
          right: 20,
          child: Opacity(
            opacity: 0.12,
            child: SizedBox(
              width: 80,
              height: 80,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 25,
                itemBuilder: (_, __) => Container(
                  decoration: const BoxDecoration(
                    color: _C.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Logo ───────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: _C.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(
              'assets/images/picto.png', // Pictogramme SaamBiz — fond bleu
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'SAAMBIZ',
                style: GoogleFonts.sora(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _C.black,
                  letterSpacing: -0.6,
                ),
              ),
              TextSpan(
                text: '.',
                style: GoogleFonts.sora(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _C.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Badge statut ───────────────────────────────────────────────────────────
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _C.greenLight,
        border: Border.all(color: _C.greenBorder, width: 1.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Point pulsant simulé avec deux cercles superposés
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: _C.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            'Gérez vos boutiques facilement',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _C.greenText,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── En-tête ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Se connecter',
          style: GoogleFonts.sora(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: _C.black,
            height: 1.15,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Accédez à vos boutiques et gérez\nvos produits en toute simplicité.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _C.sub,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Carte principale ───────────────────────────────────────────────────────
  Widget _buildCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _C.white.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _C.green.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('E-mail ou téléphone'),
          const SizedBox(height: 8),
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildFieldLabel('Mot de passe'),
          const SizedBox(height: 8),
          _buildPasswordField(),
          const SizedBox(height: 14),
          _buildForgotLink(),
          const SizedBox(height: 28),
          _buildLoginButton(isLoading),
          const SizedBox(height: 22),
          _buildDivider(),
          const SizedBox(height: 22),
          _buildRegisterLink(),
        ],
      ),
    );
  }

  // ── Label de champ ─────────────────────────────────────────────────────────
  Widget _buildFieldLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: _C.label,
        letterSpacing: 0.9,
      ),
    );
  }

  // ── Champ e-mail ───────────────────────────────────────────────────────────
  Widget _buildEmailField() {
    final focused = _identifiantFocus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 54,
      decoration: BoxDecoration(
        color: focused ? _C.white : _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? _C.green : _C.border,
          width: focused ? 2.0 : 1.5,
        ),
        boxShadow: focused
            ? [
          BoxShadow(
            color: _C.green.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.email_outlined,
              key: ValueKey(focused),
              size: 20,
              color: focused ? _C.green : _C.placeholder,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.transparent,
                  error: Colors.transparent,
                ),
              ),
              child: TextFormField(
                controller: _identifiantController,
                focusNode: _identifiantFocus,
                keyboardType: TextInputType.emailAddress,
                cursorColor: _C.green,
                style: GoogleFonts.dmSans(
                  color: _C.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'exemple@mail.com',
                  hintStyle: GoogleFonts.dmSans(
                    color: _C.placeholder,
                    fontSize: 14,
                  ),
                  border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
                  errorBorder: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
                  focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.only(
                    right: 16,
                    top: 14,
                    bottom: 14,
                  ),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Ce champ est requis' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Champ mot de passe ─────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    final focused = _passwordFocus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 54,
      decoration: BoxDecoration(
        color: focused ? _C.white : _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? _C.green : _C.border,
          width: focused ? 2.0 : 1.5,
        ),
        boxShadow: focused
            ? [
          BoxShadow(
            color: _C.green.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.lock_outline_rounded,
              key: ValueKey(focused),
              size: 20,
              color: focused ? _C.green : _C.placeholder,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PasswordTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              hintText: '••••••••',
              height: 54,
              width: double.infinity,
              borderRadius: BorderRadius.circular(0),
              style: GoogleFonts.dmSans(
                color: _C.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              validator: (v) =>
              (v == null || v.isEmpty) ? 'Ce champ est requis' : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Mot de passe oublié ────────────────────────────────────────────────────
  Widget _buildForgotLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/forgot-password'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            'Mot de passe oublié ?',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.green,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bouton connexion ───────────────────────────────────────────────────────
  Widget _buildLoginButton(bool isLoading) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: isLoading ? _C.black.withOpacity(0.75) : _C.black,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.black.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _onLoginPressed,
          borderRadius: BorderRadius.circular(18),
          splashColor: _C.green.withOpacity(0.25),
          highlightColor: _C.green.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(_C.white),
                    ),
                  )
                else ...[
                  Text(
                    'Se connecter',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _C.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _C.green.withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: _C.white,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Séparateur ─────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_C.divider, Color(0x00EDF0E8)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'ou',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _C.placeholder,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x00EDF0E8), _C.divider],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Lien créer un compte ───────────────────────────────────────────────────
  Widget _buildRegisterLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Pas encore de compte ? ",
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _C.label,
              ),
            ),
            TextSpan(
              text: 'Créer un compte',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.green,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.of(context).pushNamed(AppRouter.profileChoiceRoute);
                },
            ),
          ],
        ),
      ),
    );
  }
}