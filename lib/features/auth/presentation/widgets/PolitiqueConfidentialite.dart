import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PolitiqueConfidentialite extends StatelessWidget {
  const PolitiqueConfidentialite({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          'Politique de confidentialité',
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
              _title('Politique de confidentialité – SIGNS'),

              _paragraph(
                  'SIGNS s’engage à protéger les données personnelles de ses utilisateurs '
                      'conformément à la loi n° 2008-12 du 25 janvier 2008 relative à la protection '
                      'des données à caractère personnel au Sénégal.'
              ),

              _section('1. Données collectées'),
              _paragraph(
                  'SIGNS collecte uniquement les données strictement nécessaires au '
                      'fonctionnement du service, notamment : données d’identification et de '
                      'contact, informations liées à l’utilisation de l’application, factures et '
                      'contrats générés par l’utilisateur.'
              ),

              _section('2. Finalité du traitement'),
              _paragraph(
                  'Les données sont utilisées pour la création, la gestion, la consultation '
                      'et le stockage des documents, l’amélioration du service, le support '
                      'utilisateur, la prévention des fraudes et le respect des obligations légales.'
              ),

              _section('3. Partage des données'),
              _paragraph(
                  'SIGNS ne vend ni ne loue aucune donnée personnelle. Les données peuvent être '
                      'transmises uniquement à des prestataires techniques nécessaires au '
                      'fonctionnement du service ou aux autorités compétentes si la loi l’exige.'
              ),

              _section('4. Sécurité'),
              _paragraph(
                  'SIGNS met en œuvre des mesures techniques et organisationnelles appropriées '
                      'afin de protéger les données personnelles contre tout accès non autorisé.'
              ),

              _section('5. Conservation'),
              _paragraph(
                  'Les données sont conservées uniquement pendant la durée nécessaire à la '
                      'fourniture du service ou au respect des obligations légales.'
              ),

              _section('6. Droits de l’utilisateur'),
              _paragraph(
                  'Conformément à la législation sénégalaise, l’utilisateur dispose d’un droit '
                      'd’accès, de rectification, de suppression et d’opposition concernant ses '
                      'données personnelles.'
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
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 1.6,
        color: Colors.black54,
      ),
    );
  }
}
