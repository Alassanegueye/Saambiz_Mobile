import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/signup_remote_datasource.dart';
import 'signup_kit.dart';

/// Données transportées d'un écran à l'autre pendant l'inscription.
/// Le mot de passe est conservé le temps du parcours pour connecter
/// l'utilisateur automatiquement une fois son email vérifié — il n'est jamais
/// écrit sur le disque.
class SignupDraft {
  final String role; // 'Acheteur' ou 'Vendeur'
  final String prenom;
  final String nom;
  final String email;
  final String motDePasse;

  const SignupDraft({
    required this.role,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.motDePasse,
  });

  bool get isVendeur => role == 'Vendeur';
}

/// Écrans 2A et 2B : création du compte. Un seul écran paramétré par le rôle,
/// les deux formulaires demandant exactement les mêmes informations ; seuls
/// le titre, l'accroche et la suite du parcours changent.
class SignupFormPage extends StatefulWidget {
  final String role;
  const SignupFormPage({super.key, required this.role});

  @override
  State<SignupFormPage> createState() => _SignupFormPageState();
}

class _SignupFormPageState extends State<SignupFormPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String? _nameError;
  String? _emailError;
  String? _passError;

  bool get _isVendeur => widget.role == 'Vendeur';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// « Alassane Gueye » → prénom « Alassane », nom « Gueye ».
  /// Sans espace, le backend exige tout de même un nom : on reprend la même
  /// valeur pour les deux champs plutôt que de bloquer l'inscription.
  (String prenom, String nom) _splitName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, parts.first);
    return (parts.first, parts.sublist(1).join(' '));
  }

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    setState(() {
      _nameError = name.length < 2 ? 'Indiquez votre nom.' : null;
      _emailError = kEmailRegExp.hasMatch(email)
          ? null
          : 'Adresse email invalide.';
      _passError = validateMotDePasse(pass);
    });

    return _nameError == null && _emailError == null && _passError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final (prenom, nom) = _splitName(_nameCtrl.text);
    final email = _emailCtrl.text.trim().toLowerCase();

    try {
      // Le compte n'est PAS créé ici : on demande d'abord un code à l'adresse
      // saisie. Il ne naîtra qu'une fois ce code validé, à l'écran suivant.
      // Sans cet ordre, une faute de frappe dans l'adresse laissait une ligne
      // utilisateur définitive, rattachée à une boîte mail inexistante.
      await SignupRemoteDataSource(sl<Dio>()).envoyerCode(
        email: email,
        prenom: prenom,
      );

      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AppRouter.emailVerificationRoute,
        arguments: SignupDraft(
          role: widget.role,
          prenom: prenom,
          nom: nom,
          email: email,
          motDePasse: _passCtrl.text,
        ),
      );
    } on SignupException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SbScaffold(
      children: [
        Align(alignment: Alignment.centerLeft, child: SbBackButton()),
        const SizedBox(height: 4),
        const SbWordmark(),
        const SizedBox(height: 24),

        Text(
          _isVendeur
              ? 'Développez votre activité\navec SaamBiz'
              : 'Créer votre compte',
          style: Sb.title(23),
        ),
        const SizedBox(height: 10),
        Text(
          _isVendeur
              ? 'Ouvrez votre boutique, publiez vos produits et vendez à toute la communauté SaamBiz.'
              : 'Rejoignez SaamBiz et découvrez des boutiques près de chez vous.',
          style: Sb.body(14),
        ),
        const SizedBox(height: 26),

        SbErrorBanner(_error),

        SbField(
          label: 'Nom complet',
          hint: 'Ex. Alassane Gueye',
          controller: _nameCtrl,
          keyboardType: TextInputType.name,
          autofillHint: AutofillHints.name,
          errorText: _nameError,
        ),
        const SizedBox(height: 18),

        SbField(
          label: 'Adresse email',
          hint: 'exemple@email.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofillHint: AutofillHints.email,
          errorText: _emailError,
        ),
        const SizedBox(height: 6),
        Text(
          'Nous y enverrons votre code de vérification.',
          style: Sb.body(12),
        ),
        const SizedBox(height: 18),

        SbField(
          label: 'Mot de passe',
          hint: '••••••••',
          controller: _passCtrl,
          obscure: _obscure,
          textInputAction: TextInputAction.done,
          autofillHint: AutofillHints.newPassword,
          errorText: _passError,
          onSubmitted: (_) => _submit(),
          suffix: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: Sb.textLight,
            ),
            tooltip: _obscure
                ? 'Afficher le mot de passe'
                : 'Masquer le mot de passe',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '8 caractères minimum, avec une majuscule, un chiffre et un caractère spécial.',
          style: Sb.body(12),
        ),

        const SizedBox(height: 26),
        SbPrimaryButton(
          label: _isVendeur ? 'Créer mon compte' : 'Continuer',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 18),
        SbLoginLink(
          onTap: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
        ),
      ],
    );
  }
}
