import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/signup_remote_datasource.dart';
import '../../domain/usecases/login_user.dart';
import '../widgets/mise_en_page_auth.dart';
import 'signup_form_page.dart';
import 'signup_kit.dart';

/// Écrans 3A et 3B : saisie du code à 6 chiffres reçu par email.
///
/// La maquette prévoyait un SMS ; la vérification passe par l'adresse email
/// (expéditeur noreply@saambiz.com), ce qui évite les coûts et les
/// indisponibilités SMS et fonctionne hors du Sénégal.
class EmailVerificationPage extends StatefulWidget {
  final SignupDraft draft;
  const EmailVerificationPage({super.key, required this.draft});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  static const _length = 6;
  static const _cooldown = 30; // secondes avant de pouvoir renvoyer un code

  final List<TextEditingController> _ctrls = List.generate(
    _length,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(_length, (_) => FocusNode());
  // Nœuds dédiés au KeyboardListener (détection de la touche « retour »).
  final List<FocusNode> _rawNodes = List.generate(_length, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _info;
  int _secondsLeft = _cooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    for (final n in _rawNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  String get _code => _ctrls.map((c) => c.text).join();

  /// Gère la saisie d'une case : avance, recule, et accepte un collage du code
  /// complet depuis l'application mail.
  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _length; i++) {
        _ctrls[i].text = i < digits.length ? digits[i] : '';
      }
      setState(() => _error = null);
      FocusScope.of(context).unfocus();
      if (_code.length == _length) _verifier();
      return;
    }

    if (value.isNotEmpty && index < _length - 1) {
      _nodes[index + 1].requestFocus();
    }
    setState(() => _error = null);
    if (_code.length == _length) _verifier();
  }

  Future<void> _verifier() async {
    if (_loading) return;
    if (_code.length < _length) {
      setState(() => _error = 'Saisissez les 6 chiffres du code.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    final signup = SignupRemoteDataSource(sl<Dio>());
    try {
      // 1. Le code est validé : le serveur rend un jeton qui atteste de cette
      //    vérification précise.
      final jeton = await signup.verifierCode(
        email: widget.draft.email,
        code: _code,
      );

      // 2. Le compte est créé maintenant seulement, en présentant ce jeton.
      //    L'adresse est donc confirmée avant même que la ligne n'existe.
      await signup.register(
        nom: widget.draft.nom,
        prenom: widget.draft.prenom,
        email: widget.draft.email,
        motDePasse: widget.draft.motDePasse,
        role: widget.draft.role,
        jetonEmail: jeton,
        telephone: widget.draft.telephone,
      );

      // 3. On connecte l'utilisateur pour qu'il enchaîne sur ses centres
      //    d'intérêt (client) ou la création de sa boutique (vendeur) sans
      //    ressaisir ses identifiants.
      final connexion = await sl<LoginUser>()(
        widget.draft.email,
        widget.draft.motDePasse,
      );

      if (!mounted) return;

      await connexion.fold(
        (failure) async {
          // Compte bien vérifié mais connexion impossible : on renvoie vers
          // l'écran de connexion plutôt que de bloquer l'utilisateur ici.
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé. Connectez-vous pour continuer.'),
            ),
          );
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
        },
        (user) async {
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            widget.draft.isVendeur
                ? AppRouter.creerBoutiqueRoute
                : AppRouter.interetsRoute,
            (_) => false,
            arguments: user,
          );
        },
      );
    } on SignupException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _renvoyer() async {
    if (_secondsLeft > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    try {
      final message = await SignupRemoteDataSource(
        sl<Dio>(),
      ).renvoyerCode(widget.draft.email);
      if (mounted) setState(() => _info = message);
      _startCooldown();
    } on SignupException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SbPageAuth(
      etape: 4,
      vendeur: widget.draft.isVendeur,
      icone: Icons.mark_email_unread_outlined,
      titre: 'Vérifiez votre e-mail',
      sousTitre: 'Code envoyé à ${widget.draft.email}',
      carte: [
        const LibelleChamp('Code à 6 chiffres'),
        Row(
          children: [
            for (var i = 0; i < _length; i++) ...[
              Expanded(child: _buildBox(i)),
              if (i < _length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 18),
        if (_error != null) SbErrorBanner(_error),
        if (_info != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Sb.green.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 18, color: Sb.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _info!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
        SbPrimaryButton(label: 'Vérifier', loading: _loading, onPressed: _verifier),
        const SizedBox(height: 14),
        Center(
          child: _resending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
              : _secondsLeft > 0
                  ? Text('Renvoyer dans $_secondsLeft s', style: Sb.body(13))
                  : TextButton(
                      onPressed: _renvoyer,
                      child: Text(
                        'Renvoyer le code',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Sb.navy,
                        ),
                      ),
                    ),
        ),
      ],
      apres: [
        Text(
          'Pensez à vérifier vos spams.',
          textAlign: TextAlign.center,
          style: Sb.body(12),
        ),
      ],
    );
  }

  Widget _buildBox(int i) {
    final filled = _ctrls[i].text.isNotEmpty;
    return SizedBox(
      height: 54,
      // « Retour » dans une case vide remonte à la précédente et l'efface :
      // sans ça, corriger un chiffre oblige à tout reprendre.
      child: KeyboardListener(
        focusNode: _rawNodes[i],
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _ctrls[i].text.isEmpty &&
              i > 0) {
            _ctrls[i - 1].clear();
            _nodes[i - 1].requestFocus();
            setState(() {});
          }
        },
        child: TextField(
          controller: _ctrls[i],
          focusNode: _nodes[i],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          // Une seule case n'accepte qu'un chiffre, mais on laisse passer un
          // collage plus long pour le remplissage automatique du code.
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Sb.navy,
          ),
          onChanged: (v) => _onChanged(i, v),
          onTap: () => _ctrls[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _ctrls[i].text.length,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: filled ? Sb.navyTint : Sb.surface,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: filled ? Sb.navy : Sb.border,
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Sb.navy, width: 1.8),
            ),
          ),
        ),
      ),
    );
  }
}
