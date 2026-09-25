import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConditionUtilisation extends StatelessWidget {
  const ConditionUtilisation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          'Conditions d’utilisation',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Conditions Générales d’Utilisation (CGU) – SIGNS'),

              _section('Article 1 – Objet'),
              _paragraph(
                  'Les présentes CGU régissent l’utilisation de l’application SIGNS. '
                      'L’application permet aux utilisateurs de créer des factures et des contrats, '
                      'et de sécuriser les contrats via des signatures bilatérales. Les factures '
                      'sont considérées comme des documents commerciaux.'
              ),

              _section('Article 2 – Acceptation'),
              _paragraph(
                  'L’accès et l’utilisation de SIGNS impliquent l’acceptation pleine et entière '
                      'des présentes CGU. Si l’utilisateur n’accepte pas ces conditions, il ne doit '
                      'pas utiliser l’application.'
              ),

              _section('Article 3 – Responsabilité de l’utilisateur'),
              _bullet('du contenu des documents qu’il crée'),
              _bullet('de la conformité légale des contrats ou factures'),
              _bullet('de la transmission des documents à des tiers'),
              _paragraph(
                  'SIGNS agit uniquement comme un outil technique et ne peut être tenu '
                      'responsable du contenu des documents ni des relations juridiques entre '
                      'les parties.'
              ),

              _section('Article 4 – Compte utilisateur'),
              _paragraph(
                  'L’utilisateur doit fournir des informations exactes et à jour. '
                      'Il est responsable de la confidentialité et de la sécurité de ses identifiants.'
              ),

              _section('Article 5 – Données personnelles'),
              _paragraph(
                  'Les données collectées sont traitées conformément à la politique de '
                      'confidentialité et à la législation sénégalaise en vigueur.'
              ),

              _section('Article 6 – Sécurisation des contrats'),
              _paragraph(
                  'Seuls les contrats créés et signés via l’application sont considérés '
                      'comme sécurisés. Les factures restent des documents commerciaux.'
              ),

              _section('Article 7 – Propriété intellectuelle'),
              _paragraph(
                  'L’application SIGNS, son logo, son contenu et son code sont protégés '
                      'par le droit de la propriété intellectuelle.'
              ),

              _section('Article 8 – Modification des CGU'),
              _paragraph(
                  'SIGNS se réserve le droit de modifier les présentes CGU à tout moment. '
                      'Les utilisateurs seront informés de toute modification importante.'
              ),

              _section('Article 9 – Résiliation'),
              _paragraph(
                  'SIGNS peut suspendre ou résilier un compte utilisateur en cas de violation '
                      'des CGU ou de comportement frauduleux.'
              ),

              _section('Article 10 – Loi applicable'),
              _paragraph(
                  'Les présentes CGU sont régies par la loi sénégalaise. '
                      'Tout litige sera soumis aux tribunaux sénégalais compétents.'
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Dernière mise à jour : 2026',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.6,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
