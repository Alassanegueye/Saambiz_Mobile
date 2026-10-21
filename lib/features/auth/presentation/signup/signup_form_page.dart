import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final String? telephone;

  const SignupDraft({
    required this.role,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.motDePasse,
    this.telephone,
  });

  bool get isVendeur => role == 'Vendeur';
}

/// Inscription en plusieurs pages, une question à la fois, adaptées au profil
/// choisi :
///
///   1. Vous          — le nom
///   2. Contact       — l'e-mail, et le téléphone (WhatsApp, obligatoire
///                      pour un vendeur : c'est là que ses clients l'écrivent)
///   3. Sécurité      — le mot de passe, règles cochées en direct
///   4. Vérification  — le code reçu par e-mail (EmailVerificationPage)
///   5. Vos goûts (client) ou Votre boutique (vendeur)
///
/// Chaque page ne demande qu'une chose : moins de champs à l'écran, moins
/// d'abandons. La flèche retour ramène à la page précédente du parcours.
class SignupFormPage extends StatefulWidget {
  final String role;
  const SignupFormPage({super.key, required this.role});

  @override
  State<SignupFormPage> createState() => _SignupFormPageState();
}

class _SignupFormPageState extends State<SignupFormPage> {
  static const _nbPages = 3;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  int _page = 0;
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String? _nameError;
  String? _emailError;
  String? _telError;
  String? _passError;

  bool get _isVendeur => widget.role == 'Vendeur';

  @override
  void initState() {
    super.initState();
    // Les règles du mot de passe se cochent au fil de la saisie.
    _passCtrl.addListener(() => setState(() => _passError = null));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// « Alassane Gueye » → prénom « Alassane », nom « Gueye ».
  (String prenom, String nom) _splitName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, parts.first);
    return (parts.first, parts.sublist(1).join(' '));
  }

  String get _telNormalise => _telCtrl.text.replaceAll(RegExp(r'[\s.-]'), '');

  bool _valider() {
    setState(() {
      _error = null;
      switch (_page) {
        case 0:
          _nameError = _nameCtrl.text.trim().length < 2 ? 'Indiquez votre nom.' : null;
        case 1:
          _emailError = kEmailRegExp.hasMatch(_emailCtrl.text.trim()) ? null : 'Adresse e-mail invalide.';
          final tel = _telNormalise;
          if (tel.isEmpty) {
            _telError = _isVendeur ? 'Vos clients vous contacteront sur ce numéro.' : null;
          } else {
            _telError = RegExp(r'^\+?\d{8,15}$').hasMatch(tel) ? null : 'Numéro invalide.';
          }
        default:
          _passError = validateMotDePasse(_passCtrl.text);
      }
    });
    return switch (_page) {
      0 => _nameError == null,
      1 => _emailError == null && _telError == null,
      _ => _passError == null,
    };
  }

  Future<void> _suivant() async {
    if (!_valider()) return;
    if (_page < _nbPages - 1) {
      _allerA(_page + 1);
      return;
    }
    await _envoyerCode();
  }

  void _allerA(int page) {
    FocusScope.of(context).unfocus();
    setState(() {
      _page = page;
      _error = null;
    });
  }

  void _retour() {
    if (_page > 0) {
      _allerA(_page - 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _envoyerCode() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    final (prenom, nom) = _splitName(_nameCtrl.text);
    final email = _emailCtrl.text.trim().toLowerCase();

    try {
      // Le compte n'est PAS créé ici : on demande d'abord un code à l'adresse
      // saisie. Il ne naîtra qu'une fois ce code validé, à l'écran suivant.
      await SignupRemoteDataSource(sl<Dio>()).envoyerCode(email: email, prenom: prenom);
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AppRouter.emailVerificationRoute,
        arguments: SignupDraft(
          role: widget.role,
          prenom: prenom,
          nom: nom,
          email: email,
          motDePasse: _passCtrl.text,
          telephone: _telNormalise.isEmpty ? null : _telNormalise,
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
    final libelleBouton = _page < _nbPages - 1 ? 'Suivant' : 'Recevoir mon code';
    final etape = switch (_page) {
      0 => _etapeNom(),
      1 => _etapeContact(),
      _ => _etapeMotDePasse(),
    };

    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (aPoppe, _) {
        if (!aPoppe) _retour();
      },
      child: SbPageAuth(
        etape: _page + 1,
        vendeur: _isVendeur,
        onRetour: _retour,
        icone: etape.icone,
        titre: etape.titre,
        sousTitre: etape.texte,
        carte: [
          SbErrorBanner(_error),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: etape.champs,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SbPrimaryButton(
            label: libelleBouton,
            icon: Icons.arrow_forward_rounded,
            loading: _loading,
            onPressed: _suivant,
          ),
        ],
        apres: [
          if (_page == 0)
            SbLoginLink(onTap: () => Navigator.of(context).pushNamed(AppRouter.loginRoute)),
        ],
      ),
    );
  }

  // ─── Étapes ───────────────────────────────────────────────────────────────

  _Etape _etapeNom() => _Etape(
        icone: _isVendeur ? Icons.badge_outlined : Icons.person_outline_rounded,
        titre: 'Votre nom',
        texte: _isVendeur ? 'Le responsable de la boutique.' : 'Pour préparer vos commandes.',
        champs: [
          SbField(
            label: 'Nom complet',
            hint: 'Ex. Awa Diop',
            icon: Icons.person_outline_rounded,
            controller: _nameCtrl,
            keyboardType: TextInputType.name,
            autofillHint: AutofillHints.name,
            errorText: _nameError,
            onSubmitted: (_) => _suivant(),
          ),
        ],
      );

  _Etape _etapeContact() => _Etape(
        icone: Icons.alternate_email_rounded,
        titre: 'Vos coordonnées',
        texte: 'Un code vous sera envoyé par e-mail.',
        champs: [
          SbField(
            label: 'E-mail',
            hint: 'exemple@email.com',
            icon: Icons.mail_outline_rounded,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHint: AutofillHints.email,
            errorText: _emailError,
          ),
          const SizedBox(height: 16),
          SbField(
            label: _isVendeur ? 'WhatsApp' : 'Téléphone (facultatif)',
            hint: 'Ex. 77 123 45 67',
            icon: Icons.phone_outlined,
            controller: _telCtrl,
            keyboardType: TextInputType.phone,
            autofillHint: AutofillHints.telephoneNumber,
            textInputAction: TextInputAction.done,
            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
            errorText: _telError,
            onSubmitted: (_) => _suivant(),
          ),
        ],
      );

  _Etape _etapeMotDePasse() {
    final mdp = _passCtrl.text;
    return _Etape(
      icone: Icons.lock_outline_rounded,
      titre: 'Mot de passe',
      texte: 'Protégez votre compte.',
      champs: [
        SbField(
          label: 'Mot de passe',
          hint: 'Votre mot de passe',
          icon: Icons.lock_outline_rounded,
          controller: _passCtrl,
          obscure: _obscure,
          textInputAction: TextInputAction.done,
          autofillHint: AutofillHints.newPassword,
          errorText: _passError,
          onSubmitted: (_) => _suivant(),
          suffix: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: Sb.textLight,
            ),
            tooltip: _obscure ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
          ),
        ),
        const SizedBox(height: 14),
        _Regle('8 caractères', mdp.length >= 8),
        _Regle('Une majuscule', RegExp(r'[A-Z]').hasMatch(mdp)),
        _Regle('Un chiffre', RegExp(r'[0-9]').hasMatch(mdp)),
        _Regle('Un caractère spécial', RegExp(r'[^A-Za-z0-9]').hasMatch(mdp)),
      ],
    );
  }
}

/// Contenu d'une étape : en-tête (pictogramme, titre, texte) et champs.
class _Etape {
  final IconData icone;
  final String titre;
  final String texte;
  final List<Widget> champs;

  const _Etape({
    required this.icone,
    required this.titre,
    required this.texte,
    required this.champs,
  });
}

/// Règle du mot de passe, cochée dès qu'elle est respectée.
class _Regle extends StatelessWidget {
  final String texte;
  final bool ok;
  const _Regle(this.texte, this.ok);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? Sb.green : Colors.transparent,
              border: Border.all(color: ok ? Sb.green : Sb.border, width: 1.6),
            ),
            child: ok ? const Icon(Icons.check_rounded, size: 13, color: Sb.white) : null,
          ),
          const SizedBox(width: 10),
          Text(
            texte,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: ok ? FontWeight.w600 : FontWeight.w500,
              color: ok ? Sb.navy : Sb.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
