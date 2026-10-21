import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/routes/app_router.dart';

import '../../../../core/theme/app_color.dart';

/// Fond des illustrations : blanc à peine cassé, repris tel quel pour que
/// l'image se fonde dans l'écran sans démarcation.
const Color _fond = Color(0xFFFEFEFE);

/// Un écran d'onboarding : son illustration, son titre et son texte.
class _Slide {
  final String image;
  final String titre;
  final String texte;
  const _Slide(this.image, this.titre, this.texte);
}

// Illustrations 3D (sources : saambiz_3d_0X_*.png), recadrées sur la partie
// illustrée et fondues dans le blanc en bas : le texte se pose dessous.
const List<_Slide> _slides = [
  _Slide(
    'assets/images/onb1.webp',
    'Créez votre boutique en quelques minutes',
    'Ajoutez vos produits, vos prix et vos photos directement depuis votre téléphone.',
  ),
  _Slide(
    'assets/images/onb2.webp',
    'Gérez vos ventes et vos promotions',
    'Suivez vos commandes et vos livraisons, et lancez des offres pour vos abonnés.',
  ),
  _Slide(
    'assets/images/onb3.webp',
    'Votre boutique a son propre site web',
    'Partagez votre lien sur WhatsApp : vos clients commandent sans rien installer.',
  ),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Les trois illustrations sont chargées d'avance : pas d'écran vide au
    // premier balayage.
    for (final s in _slides) {
      precacheImage(AssetImage(s.image), context);
    }
  }

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Écran clair : icônes système sombres.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _fond,
        body: SafeArea(
          child: Column(
            children: [
              // « Passer » en haut à droite (masqué sur la dernière étape)
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isLast ? 0 : 1,
                    child: TextButton(
                      onPressed: isLast ? null : _finish,
                      child: Text(
                        'Passer',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColor.kGrayscale40,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Illustration + texte : défilent ensemble au balayage.
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _PageSlide(slide: _slides[i]),
                ),
              ),

              // Points de progression + bouton
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: isLast ? _buildLastBar() : _buildStepBar(),
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
        ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.kPrimary,
            foregroundColor: AppColor.kWhite,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Suivant',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 19),
            ],
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
          height: 52,
          child: ElevatedButton(
            onPressed: _finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.kSecondary,
              foregroundColor: AppColor.kPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Commencer',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
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
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColor.kPrimary : AppColor.kGrayscale20,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Une page : l'illustration prend la place disponible (sans être rognée),
/// le titre et le texte se posent dessous, dans le blanc de l'image.
class _PageSlide extends StatelessWidget {
  final _Slide slide;
  const _PageSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Image.asset(
            slide.image,
            fit: BoxFit.contain,
            width: double.infinity,
            alignment: Alignment.bottomCenter,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
          child: Column(
            children: [
              Text(
                slide.titre,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColor.kPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.texte,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  height: 1.55,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
