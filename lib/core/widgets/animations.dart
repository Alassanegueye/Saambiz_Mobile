import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// Mouvements communs de l'application.
///
/// Toutes les animations partagent les mêmes durées et la même courbe : un
/// écran qui s'anime à sa façon paraît « bricolé » à côté des autres, même
/// quand chaque animation, prise seule, est réussie.
class Mouvement {
  Mouvement._();

  static const Duration rapide = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration lent = Duration(milliseconds: 460);

  /// Décélération franche : l'élément arrive vite et se pose en douceur.
  static const Curve courbe = Curves.easeOutCubic;
}

/// Enfonce légèrement son enfant pendant l'appui, puis le relâche avec un
/// petit rebond. N'intercepte pas le toucher : l'`InkWell` ou le
/// `GestureDetector` de l'enfant reçoit toujours le tap.
class Pressable extends StatefulWidget {
  final Widget child;
  final double echelle;
  const Pressable({super.key, required this.child, this.echelle = 0.965});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _appuye = false;

  void _poser(bool v) {
    if (_appuye != v) setState(() => _appuye = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _poser(true),
      onPointerUp: (_) => _poser(false),
      onPointerCancel: (_) => _poser(false),
      child: AnimatedScale(
        scale: _appuye ? widget.echelle : 1,
        duration: _appuye ? Mouvement.rapide : Mouvement.normal,
        curve: _appuye ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Apparition en fondu, avec une légère montée. [rang] décale le départ
/// pour enchaîner les éléments d'une liste en cascade (plafonné, pour que
/// le bas d'une longue liste n'attende pas).
class Apparition extends StatelessWidget {
  final Widget child;
  final int rang;
  final double decalage;
  const Apparition({
    super.key,
    required this.child,
    this.rang = 0,
    this.decalage = 18,
  });

  @override
  Widget build(BuildContext context) {
    final retard = (rang.clamp(0, 8)) * 0.07;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          Mouvement.lent + Duration(milliseconds: (retard * 1000).round()),
      curve: Interval(retard / (0.46 + retard), 1, curve: Mouvement.courbe),
      builder: (_, t, enfant) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * decalage),
          child: enfant,
        ),
      ),
      child: child,
    );
  }
}

/// Reflet animé partagé par les squelettes de chargement d'un écran.
class Reflet extends StatefulWidget {
  final Widget child;
  const Reflet({super.key, required this.child});

  @override
  State<Reflet> createState() => _RefletState();
}

class _RefletState extends State<Reflet> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        child: widget.child,
        builder: (_, enfant) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (r) {
            final x = -1.5 + _ctrl.value * 3;
            return LinearGradient(
              begin: Alignment(x - 0.6, -0.3),
              end: Alignment(x + 0.6, 0.3),
              colors: const [
                AppColor.kBackground2,
                Color(0xFFFFFDF8),
                AppColor.kBackground2,
              ],
            ).createShader(r);
          },
          child: enfant,
        ),
      ),
    );
  }
}

/// Bloc gris arrondi d'un squelette de chargement (à placer dans un [Reflet]).
class Os extends StatelessWidget {
  final double? largeur;
  final double hauteur;
  final double rayon;
  final bool rond;
  const Os({
    super.key,
    this.largeur,
    required this.hauteur,
    this.rayon = 14,
    this.rond = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largeur,
      height: hauteur,
      decoration: BoxDecoration(
        color: AppColor.kBackground2,
        shape: rond ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: rond ? null : BorderRadius.circular(rayon),
      ),
    );
  }
}
