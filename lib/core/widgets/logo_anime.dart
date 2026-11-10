import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

/// Pictogramme SaamBiz dessiné pièce par pièce, pour pouvoir l'animer.
///
/// Reprise fidèle de `LogoAnime.jsx` / `marque.css` du site vitrine : mêmes
/// formes (relevées sur picto-navy.png, repère 460 × 412), mêmes couleurs,
/// mêmes durées, retards et courbes. Le sac arrive en filant, l'anse se trace,
/// les trois barres montent l'une après l'autre, puis la flèche s'élance.
///
/// [ms] est le temps écoulé depuis le début de l'entrée, en millisecondes :
/// à [LogoAnimePainter.dureeEntree] et au-delà, le logo est complet.
class LogoAnimePainter extends CustomPainter {
  LogoAnimePainter({required this.ms, this.clair = false});

  /// Durée totale de l'entrée (la pointe de la flèche finit à 1,36 s).
  static const double dureeEntree = 1360;

  /// Proportions du dessin (repère du SVG du site).
  static const double largeurRepere = 460;
  static const double hauteurRepere = 412;

  final double ms;

  /// Variante « clair » : sac blanc, flèche bleu marine (sur fond sombre).
  final bool clair;

  static const Color _marine = Color(0xFF021E54);
  static const Color _or = Color(0xFFFEB603);
  static const Color _blanc = Color(0xFFFFFFFF);

  // Courbes du site (cubic-bezier CSS).
  static const Cubic _cSac = Cubic(0.2, 0.8, 0.25, 1.15);
  static const Cubic _cTrait = Cubic(0.2, 0.8, 0.2, 1);
  static const Cubic _cAnse = Cubic(0, 0, 0.58, 1); // ease-out
  static const Cubic _cBarre = Cubic(0.3, 1.45, 0.5, 1);
  static const Cubic _cFleche = Cubic(0.6, 0, 0.3, 1);
  static const Cubic _cPointe = Cubic(0.3, 1.6, 0.5, 1);

  /// Avancement (0 → 1) d'une animation CSS de [duree] ms lancée à [retard].
  double _p(double retard, double duree) =>
      ((ms - retard) / duree).clamp(0.0, 1.0);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / largeurRepere, size.height / hauteurRepere);

    final sac = clair ? _blanc : _marine;
    final fleche = clair ? _marine : _blanc;

    // ── Traits de vitesse (ordre de départ : 2, 1, 3) ──
    _trait(canvas, const Rect.fromLTWH(46, 216, 81, 18), 100);
    _trait(canvas, const Rect.fromLTWH(2, 259, 125, 18), 40);
    _trait(canvas, const Rect.fromLTWH(51, 300, 76, 18), 160);

    // ── Le sac : il arrive en glissant depuis la gauche, en grossissant. ──
    final pSac = _cSac.transform(_p(0, 500));
    final opaciteSac = pSac.clamp(0.0, 1.0);
    if (opaciteSac > 0) {
      // Origine : milieu du bas du sac (boîte de 141→458 × 18,5→410).
      const ox = 299.5, oy = 410.0;
      final echelle = _lerp(0.84, 1, pSac);
      canvas.save();
      canvas.translate(ox + _lerp(-0.16 * 317, 0, pSac), oy);
      canvas.scale(echelle);
      canvas.translate(-ox, -oy);
      final calque = opaciteSac < 1;
      if (calque) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromRGBO(0, 0, 0, opaciteSac),
        );
      }

      // Anse : se trace de gauche à droite.
      final anse = Path()
        ..moveTo(227.5, 114)
        ..lineTo(227.5, 90)
        ..arcToPoint(
          const Offset(370.5, 90),
          radius: const Radius.circular(71.5),
        )
        ..lineTo(370.5, 114);
      _trace(
        canvas,
        anse,
        _p(200, 420),
        _cAnse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 32
          ..color = sac,
      );

      // Corps du sac.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(141, 107, 317, 303),
          const Radius.circular(56),
        ),
        Paint()..color = sac,
      );

      // Trois barres qui montent.
      _barre(canvas, const Rect.fromLTWH(196, 314, 47, 63), 360);
      _barre(canvas, const Rect.fromLTWH(269, 281, 50, 96), 460);
      _barre(canvas, const Rect.fromLTWH(348, 241, 49, 136), 560);

      // Flèche qui s'élance.
      final trajet = Path()
        ..moveTo(201, 272)
        ..lineTo(266, 214)
        ..lineTo(299, 243)
        ..lineTo(372, 178);
      _trace(
        canvas,
        trajet,
        _p(680, 420),
        _cFleche,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 21
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = fleche,
      );

      // Pointe de la flèche : elle éclot avec un petit rebond.
      final pPointe = _cPointe.transform(_p(1020, 340));
      if (pPointe > 0) {
        const px = 363.5, py = 190.0; // 25 % / 75 % de sa boîte
        final pointe = Path()
          ..moveTo(347, 153)
          ..lineTo(413, 142)
          ..lineTo(393, 206)
          ..close();
        final couleur = fleche.withValues(alpha: pPointe.clamp(0.0, 1.0));
        canvas.save();
        canvas.translate(px, py);
        canvas.scale(pPointe);
        canvas.translate(-px, -py);
        canvas.drawPath(pointe, Paint()..color = couleur);
        canvas.drawPath(
          pointe,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeJoin = StrokeJoin.round
            ..color = couleur,
        );
        canvas.restore();
      }

      if (calque) canvas.restore();
      canvas.restore();
    }

    canvas.restore();
  }

  /// Trait de vitesse : il file depuis la gauche, s'étire un peu trop, puis
  /// se pose (images clés 0 % / 60 % / 100 % du site, chacune adoucie).
  void _trait(Canvas canvas, Rect r, double retard) {
    final p = _p(retard, 550);
    double opacite, decalage, etirement;
    if (p < 0.6) {
      final u = _cTrait.transform(p / 0.6);
      opacite = u;
      decalage = _lerp(-0.4, 0.06, u);
      etirement = _lerp(0.2, 1.25, u);
    } else {
      final u = _cTrait.transform((p - 0.6) / 0.4);
      opacite = 1;
      decalage = _lerp(0.06, 0, u);
      etirement = _lerp(1.25, 1, u);
    }
    if (opacite <= 0) return;
    final ox = r.right, oy = r.center.dy; // origine : bord droit
    canvas.save();
    canvas.translate(ox + decalage * r.width, oy);
    canvas.scale(etirement, 1);
    canvas.translate(-ox, -oy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(9)),
      Paint()..color = _or.withValues(alpha: opacite.clamp(0.0, 1.0)),
    );
    canvas.restore();
  }

  /// Barre dorée qui monte depuis sa base, avec un léger dépassement.
  void _barre(Canvas canvas, Rect r, double retard) {
    final s = _cBarre.transform(_p(retard, 520));
    if (s <= 0) return;
    canvas.save();
    canvas.translate(0, r.bottom);
    canvas.scale(1, s);
    canvas.translate(0, -r.bottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(9)),
      Paint()..color = _or,
    );
    canvas.restore();
  }

  /// Tracé progressif d'un chemin (équivalent de stroke-dashoffset 1 → 0),
  /// avec l'apparition rapide sur les 8 premiers pourcents.
  void _trace(
    Canvas canvas,
    Path chemin,
    double p,
    Cubic courbe,
    Paint pinceau,
  ) {
    if (p <= 0) return;
    final fraction = courbe.transform(p).clamp(0.0, 1.0);
    final opacite = courbe.transform((p / 0.08).clamp(0.0, 1.0));
    if (fraction <= 0 || opacite <= 0) return;
    pinceau.color = pinceau.color.withValues(
      alpha: pinceau.color.a * opacite.clamp(0.0, 1.0),
    );
    if (fraction >= 1) {
      canvas.drawPath(chemin, pinceau);
      return;
    }
    final partiel = Path();
    for (final ui.PathMetric m in chemin.computeMetrics()) {
      partiel.addPath(m.extractPath(0, m.length * fraction), Offset.zero);
    }
    canvas.drawPath(partiel, pinceau);
  }

  @override
  bool shouldRepaint(LogoAnimePainter ancien) =>
      ancien.ms != ms || ancien.clair != clair;
}
