import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/police.dart';
import 'logo_anime.dart';

/// Écran d'arrivée de l'application, repris du site vitrine (IntroMarque.jsx).
///
/// Le logo se dessine sur fond blanc et « SaamBiz » s'écrit dessous, puis le
/// rideau blanc remonte et découvre le premier écran (onboarding, connexion ou
/// accueil). Posé au-dessus du Navigator (voir `MaterialApp.builder`) : le
/// premier écran est déjà en place quand le rideau se lève.
///
/// Le rideau attend deux choses : la fin du dessin du logo, et le signal
/// [IntroMarque.signalerPret] envoyé par `AppBootstrap` une fois la session
/// lue et le premier écran choisi. Si ce choix tarde (renouvellement de
/// session sur un réseau lent), une fine barre de chargement apparaît.
class IntroMarque extends StatefulWidget {
  const IntroMarque({super.key, required this.child});

  final Widget child;

  static final ValueNotifier<bool> _pret = ValueNotifier(false);

  /// Le premier écran est choisi : le rideau peut se lever.
  static void signalerPret() => _pret.value = true;

  @override
  State<IntroMarque> createState() => _IntroMarqueState();
}

class _IntroMarqueState extends State<IntroMarque>
    with TickerProviderStateMixin {
  static const _dureeLogo = Duration(milliseconds: 1450);
  static const _dureeSortie = Duration(milliseconds: 700);
  static const _courbeRideau = Cubic(0.76, 0, 0.24, 1);

  late final AnimationController _entree = AnimationController(
    vsync: this,
    duration: _dureeLogo,
  );
  late final AnimationController _sortie = AnimationController(
    vsync: this,
    duration: _dureeSortie,
  );

  /// Le logo complet reste affiché ce temps-là après son animation.
  static const _tenue = Duration(seconds: 2);

  /// Au-delà (3 s au plus de logo fixe), si le premier écran n'est toujours
  /// pas prêt, une barre de chargement apparaît.
  static const _tenueMax = Duration(seconds: 3);

  bool _visible = true;
  bool _attente = false; // logo tenu 3 s, premier écran pas encore prêt
  bool _tenueFinie = false;
  bool _demarre = false;
  bool _mouvementReduit = false;
  Timer? _minuterieTenue;
  Timer? _minuterieAttente;

  @override
  void initState() {
    super.initState();
    _entree.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      _minuterieTenue = Timer(_tenue, () {
        _tenueFinie = true;
        _peutSortir();
      });
      _minuterieAttente = Timer(_tenueMax, () {
        if (mounted && !IntroMarque._pret.value && !_sortie.isAnimating) {
          setState(() => _attente = true);
        }
      });
    });
    IntroMarque._pret.addListener(_peutSortir);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demarre) return;
    _demarre = true;
    // Animations réduites (réglage d'accessibilité) : logo fixe, simple fondu.
    _mouvementReduit = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_mouvementReduit) {
      _sortie.duration = const Duration(milliseconds: 250);
      _entree.duration = Duration.zero;
      _entree.forward(); // logo complet d'emblée, puis la même tenue
    } else {
      _entree.forward();
    }
  }

  void _peutSortir() {
    if (!mounted || !_visible || _sortie.isAnimating) return;
    if (!_entree.isCompleted || !_tenueFinie) return;
    if (!IntroMarque._pret.value) return;
    _minuterieAttente?.cancel();
    // Arrivé après coup : on laisse le premier écran finir son entrée.
    final delai = _attente ? const Duration(milliseconds: 300) : Duration.zero;
    Future.delayed(delai, () {
      if (!mounted) return;
      _sortie.forward().whenComplete(() {
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void dispose() {
    IntroMarque._pret.removeListener(_peutSortir);
    _minuterieTenue?.cancel();
    _minuterieAttente?.cancel();
    _entree.dispose();
    _sortie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible) Positioned.fill(child: _rideau(context)),
      ],
    );
  }

  Widget _rideau(BuildContext context) {
    final hauteur = MediaQuery.sizeOf(context).height;
    return AnimatedBuilder(
      animation: Listenable.merge([_entree, _sortie]),
      builder: (context, _) {
        final s = _sortie.value;
        final ms = _entree.value * _dureeLogo.inMilliseconds;

        Widget contenu = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Même hauteur que la barre du bas : le logo reste au centre.
            const SizedBox(height: 36),
            CustomPaint(
              size: const Size(
                116,
                116 * LogoAnimePainter.hauteurRepere /
                    LogoAnimePainter.largeurRepere,
              ),
              painter: LogoAnimePainter(ms: ms),
            ),
            const SizedBox(height: 20),
            _Nom(ms: ms),
            AnimatedOpacity(
              opacity: _attente && s == 0 ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: const _Chargement(),
            ),
          ],
        );

        if (_mouvementReduit) {
          return Opacity(
            opacity: 1 - s,
            child: _fond(contenu),
          );
        }

        // Le rideau remonte ; le logo, lui, descend en s'effaçant.
        final r = _courbeRideau.transform(s);
        final fondu = Curves.ease.transform(
          (s * _dureeSortie.inMilliseconds / 450).clamp(0.0, 1.0),
        );
        contenu = Transform.translate(
          offset: Offset(0, 0.4 * hauteur * r),
          child: Opacity(opacity: 1 - fondu, child: contenu),
        );
        return Transform.translate(
          offset: Offset(0, -hauteur * r),
          child: _fond(contenu),
        );
      },
    );
  }

  Widget _fond(Widget contenu) => Material(
        color: Colors.white,
        child: ExcludeSemantics(child: Center(child: contenu)),
      );
}

/// « Saam » bleu marine, « Biz » doré : il s'écrit de gauche à droite en
/// remontant légèrement (0,6 s, à partir de 0,8 s).
class _Nom extends StatelessWidget {
  const _Nom({required this.ms});

  final double ms;

  static const _courbe = Cubic(0.2, 0.8, 0.2, 1);

  @override
  Widget build(BuildContext context) {
    final u = _courbe.transform(((ms - 800) / 600).clamp(0.0, 1.0));
    const style = TextStyle(
      fontFamily: kPolice,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1,
      color: Color(0xFF021E54),
      decoration: TextDecoration.none,
    );
    return Opacity(
      opacity: u,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - u)),
        child: ClipRect(
          clipper: _DevoilementGauche(u),
          child: const Text.rich(
            TextSpan(
              text: 'Saam',
              children: [
                TextSpan(
                  text: 'Biz',
                  style: TextStyle(color: Color(0xFFFEB603)),
                ),
              ],
            ),
            style: style,
          ),
        ),
      ),
    );
  }
}

class _DevoilementGauche extends CustomClipper<Rect> {
  const _DevoilementGauche(this.u);

  final double u;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(-8, -8, (size.width + 16) * u, size.height + 16);

  @override
  bool shouldReclip(_DevoilementGauche ancien) => ancien.u != u;
}

/// Barre de chargement, si le premier écran se fait attendre.
class _Chargement extends StatelessWidget {
  const _Chargement();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 32),
      child: SizedBox(
        width: 120,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          child: LinearProgressIndicator(
            minHeight: 4,
            color: Color(0xFF01154B),
            backgroundColor: Color(0xFFFEF3D6),
          ),
        ),
      ),
    );
  }
}
