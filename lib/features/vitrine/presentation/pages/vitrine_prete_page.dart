import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/vitrine.dart';

class _C {
  static const navy      = Color(0xFF0D1B3D);
  static const navyLight = Color(0xFFE8EDF7);
  static const gold      = Color(0xFFF2B705);
  static const bg        = Color(0xFFF7F9FC);
  static const white     = Color(0xFFFFFFFF);
  static const border    = Color(0xFFE2E7F0);
  static const text      = Color(0xFF0D1B3D);
  static const muted     = Color(0xFF5B6C8A);
  static const success   = Color(0xFF15803D);
  static const successBg = Color(0xFFE9F8EE);
}

/// « Votre site vitrine est prêt ».
///
/// L'écran d'arrivée de l'assistant. Trois choses à faire, dans cet ordre :
/// annoncer, donner l'adresse, et proposer de la voir. Le vendeur vient de
/// répondre à quatre questions — il veut voir le résultat, pas relire des
/// réglages.
///
/// La modification vient après, et elle est explicitement offerte : « vous
/// pouvez tout changer » est ce qui rend acceptable un site composé
/// automatiquement.
class VitrinePretePage extends StatelessWidget {
  final Vitrine vitrine;

  /// Faux quand le vendeur revient d'une modification : le texte d'accueil
  /// change, on ne va pas lui annoncer une création qu'il a déjà faite.
  final bool premiereCreation;

  const VitrinePretePage({
    super.key,
    required this.vitrine,
    this.premiereCreation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 82, height: 82,
                  decoration: const BoxDecoration(
                    color: _C.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 44, color: _C.success),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                premiereCreation
                    ? 'Votre site vitrine est prêt'
                    : 'Votre site est à jour',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: _C.text, height: 1.25),
              ),

              const SizedBox(height: 10),

              Text(
                premiereCreation
                    ? 'Il est en ligne. Consultez-le, et modifiez tout ce qui '
                      'ne vous convient pas — rien n\'est figé.'
                    : 'Vos modifications sont visibles par vos clients.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _C.muted, height: 1.55),
              ),

              // Le logo n'est pas parti : le site existe, mais il lui manque
              // son image. Dit ici, à l'endroit où le vendeur regarde son
              // résultat, plutôt que découvert plus tard sur le site public.
              if (vitrine.logoEnregistre == false) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xFFB0850B), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Votre logo n\'a pas pu être enregistré. Votre site '
                          'affiche l\'initiale de votre boutique en attendant — '
                          'reprenez-le depuis « Ma boutique ».',
                          style: TextStyle(
                              fontSize: 12.6,
                              color: Color(0xFF8A6503),
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 26),

              // ── L'adresse ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _C.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                ),
                child: Column(
                  children: [
                    const Text('L\'adresse de votre site',
                        style: TextStyle(fontSize: 12.5, color: _C.muted)),
                    const SizedBox(height: 7),
                    SelectableText(
                      vitrine.url,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700, color: _C.navy),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _C.navy,
                              side: const BorderSide(color: _C.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: vitrine.url));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Adresse copiée.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copier',
                                style: TextStyle(
                                    fontSize: 13.5, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _C.navy,
                              side: const BorderSide(color: _C.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _partager(context, vitrine.url),
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: const Text('Partager',
                                style: TextStyle(
                                    fontSize: 13.5, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _C.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _ouvrir(vitrine.url),
                child: const Text('Voir mon site',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              ),

              const SizedBox(height: 10),

              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _C.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                // Retour à l'écran « Mon site », qui recharge l'état et
                // propose la modification.
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Modifier mon site',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),

              const SizedBox(height: 22),

              // ── La suite ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: _C.navyLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.gold,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('GRATUIT',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: _C.navy,
                                  letterSpacing: 0.7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    const Text(
                      'Votre site ne vous coûte rien : aucun abonnement, '
                      'aucune commission sur vos ventes.',
                      style: TextStyle(
                          fontSize: 13, color: _C.navy, height: 1.55,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 13),
                    const _Conseil(
                      icone: Icons.chat_bubble_outline_rounded,
                      texte: 'Envoyez l\'adresse à vos clients sur WhatsApp.',
                    ),
                    const _Conseil(
                      icone: Icons.qr_code_2_rounded,
                      texte: 'Imprimez le QR code depuis votre tableau de bord '
                          'et collez-le dans votre boutique.',
                    ),
                    const _Conseil(
                      icone: Icons.inventory_2_outlined,
                      texte: 'Ajoutez vos produits : un site sans catalogue ne '
                          'vend rien.',
                      dernier: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Conseil extends StatelessWidget {
  final IconData icone;
  final String texte;
  final bool dernier;

  const _Conseil({
    required this.icone,
    required this.texte,
    this.dernier = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: dernier ? 0 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 16, color: _C.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texte,
                style: const TextStyle(
                    fontSize: 12.6, color: _C.navy, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

Future<void> _ouvrir(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _partager(BuildContext context, String url) async {
  final texte = Uri.encodeComponent('Découvrez ma boutique en ligne : $url');
  final ouvert = await launchUrl(
    Uri.parse('https://wa.me/?text=$texte'),
    mode: LaunchMode.externalApplication,
  );

  // WhatsApp absent : l'adresse part dans le presse-papier plutôt que rien.
  if (!ouvert && context.mounted) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse copiée : collez-la où vous voulez.')),
      );
    }
  }
}
