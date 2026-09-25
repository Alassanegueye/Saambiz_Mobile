import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/theme/app_color.dart';
import '../../domain/entities/colis.dart';
import '../../domain/entities/personne.dart';
import 'detail_chip.dart';

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

Widget buildColisCard({required Colis colis, required bool isReception}) {
  final Personne? personne = isReception ? colis.expediteur : colis.recepteur;
  final String personneLabel = isReception ? 'Expéditeur' : 'Destinataire';
  final String personneNom = personne?.nomComplet ?? 'Inconnu';

  Color statusColor;
  switch (colis.statut.toLowerCase()) {
    case 'livré':
    case 'livrée':
      statusColor = Colors.green;
      break;
    case 'recupere':
    case 'en_cours':
      statusColor = Colors.orange;
      break;
    case 'en_attente':
      statusColor = Colors.red;
      break;
    default:
      statusColor = AppColor.kGrayscale60;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColor.kWhite,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: AppColor.kPrimary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        colis.destination,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColor.kGrayscaleDark100,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  colis.statut,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColor.kPrimary.withOpacity(0.1),
                child: Text(
                  personneNom.isNotEmpty ? personneNom[0] : '?',
                  style: TextStyle(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personneLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColor.kGrayscale60,
                      ),
                    ),
                    Text(
                      personneNom,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColor.kGrayscaleDark100,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (personne?.email != null && personne!.email.isNotEmpty)
                      Text(
                        personne.email,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColor.kGrayscale40,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              buildDetailChip(
                icon: Icons.scale,
                label: '${colis.poids.toStringAsFixed(2)} kg',
              ),
              const SizedBox(width: 8),
              buildDetailChip(
                icon: Icons.euro,
                label: '${colis.prix.toStringAsFixed(2)} €',
              ),
              const Spacer(),
              Text(
                formatDate(colis.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}