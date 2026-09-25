import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/routes/app_router.dart';

// ─── Palette SaamBiz ───────────────────────────────────────────────────────────
class _C {
  static const gold = Color(0xFFD4A72C);
  static const white = Color(0xFFFFFFFF);
}

/// Un écran d'onboarding : son visuel, et le bleu marine sur lequel il se
/// termine.
///
/// Les trois visuels ne sont pas au même format et ne finissent pas sur
/// exactement le même bleu. Calés sur la largeur (aucun texte tronqué), ils
/// laissent donc sous eux une hauteur variable : c'est cette couleur, relevée
/// sur la dernière ligne de chaque image, qui la remplit. L'écran se lit alors
/// comme un seul visuel plein écran, sans démarcation.
class _Slide {
  final String image;
  final Color fond;
  const _Slide(this.image, this.fond);

  /// Encre des boutons or : le même bleu marine sur les trois écrans, pour
  /// que le bouton ne change pas de teinte d'une page à l'autre.
  static const Color encreBouton = Color(0xFF04223D);
}

// Versions rognées de 1.png / 2.png / 3.png (sources dans design/onboarding) :
// les points de progression et le bouton « Commencer » gravés dans les visuels
// ont été coupés, c'est le code qui les dessine — états animés et vraie zone
// tactile.
const List<_Slide> _slides = [
  _Slide('assets/images/onb1.jpg', Color(0xFF031F37)),
  _Slide('assets/images/onb2.jpg', Color(0xFF011226)),
  _Slide('assets/images/onb3.jpg', Color(0xFF02213D)),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (!mounted) return;
    // L'onboarding débouche sur le choix du profil : c'est là que se décide
    // le parcours client ou vendeur.
    Navigator.of(context).pushReplacementNamed(AppRouter.profileChoiceRoute);
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    final fond = _slides[_index].fond;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Le visuel monte jusque sous la barre d'état, et son haut est clair :
      // il faut des icônes système sombres pour rester lisible.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        // Le fond suit le visuel courant, en fondu pendant le balayage.
        backgroundColor: fond,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          color: fond,
          child: Stack(
            children: [
              // Chaque page peint son propre fond : pendant le balayage, on voit
              // celui de la page qui arrive, pas celui de la précédente.
              PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => Container(
                  color: _slides[i].fond,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      _slides[i].image,
                      // Calé sur la largeur : aucun recadrage horizontal, donc
                      // aucun texte tronqué. La hauteur restante est comblée par
                      // le fond du visuel, dans la continuité de son bandeau.
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              // Bouton « Passer » (masqué sur la dernière étape)
              if (!isLast)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 6,
                  right: 12,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Passer',
                      style: GoogleFonts.dmSans(
                        color: _C.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              // Barre navy en bas : masque les points gravés + points animés + bouton
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    34,
                    24,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [fond.withOpacity(0), fond, fond],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: isLast ? _buildLastBar() : _buildStepBar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Étapes intermédiaires : points à gauche + « Suivant » à droite
  Widget _buildStepBar() {
    return Row(
      children: [
        _buildDots(),
        const Spacer(),
        GestureDetector(
          onTap: _next,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            decoration: BoxDecoration(
              color: _C.gold,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Suivant',
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _Slide.encreBouton,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: _Slide.encreBouton,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Dernière étape : points centrés + « Commencer » pleine largeur
  Widget _buildLastBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDots(),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.gold,
              foregroundColor: _Slide.encreBouton,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Commencer',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Points de progression animés (suivent la page courante)
  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_slides.length, (i) {
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: active ? _C.gold : _C.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
