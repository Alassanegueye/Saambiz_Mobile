import 'package:flutter/material.dart';

import '../../../../core/services/comptes_memorises.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/utils/texte.dart';
import '../../../../core/widgets/image_reseau.dart';

/// Comptes déjà utilisés sur ce téléphone, clients et vendeurs : on touche
/// celui où l'on veut revenir.
class ChoixCompte extends StatelessWidget {
  const ChoixCompte({
    super.key,
    required this.comptes,
    required this.onChoisir,
    required this.onRetirer,
    required this.onAutreCompte,
    this.compteEnCours,
    this.occupe = false,
    this.avecEntete = true,
  });

  /// Titre « Choisissez un compte » : inutile quand la page le dit déjà.
  final bool avecEntete;

  final List<CompteMemorise> comptes;
  final ValueChanged<CompteMemorise> onChoisir;
  final ValueChanged<CompteMemorise> onRetirer;
  final VoidCallback onAutreCompte;

  /// Compte dont la reprise est en cours (indicateur sur sa ligne).
  final String? compteEnCours;
  final bool occupe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (avecEntete) ...[
          const Text(
            'Choisissez un compte',
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Comptes utilisés sur ce téléphone',
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 13,
              color: AppColor.kGrayscale40,
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (final c in comptes) ...[
          _LigneCompte(
            compte: c,
            chargement: compteEnCours == c.id,
            onTap: occupe ? null : () => onChoisir(c),
            onRetirer: occupe ? null : () => onRetirer(c),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: occupe ? null : onAutreCompte,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
            label: const Text('Utiliser un autre compte'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.kPrimary,
              side: const BorderSide(color: AppColor.kPrimaryBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontFamily: kPolice,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LigneCompte extends StatelessWidget {
  const _LigneCompte({
    required this.compte,
    required this.chargement,
    required this.onTap,
    required this.onRetirer,
  });

  final CompteMemorise compte;
  final bool chargement;
  final VoidCallback? onTap;
  final VoidCallback? onRetirer;

  @override
  Widget build(BuildContext context) {
    final initiales = Center(
      child: Text(
        initialesDe(compte.nomComplet),
        style: const TextStyle(
          fontFamily: kPolice,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColor.kPrimary,
        ),
      ),
    );
    final photo = compte.photoProfil;

    return Material(
      color: AppColor.kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColor.kSecondary,
                  shape: BoxShape.circle,
                ),
                child: photo != null && photo.isNotEmpty
                    ? ImageReseau(
                        photo,
                        largeurServeur: 128,
                        fit: BoxFit.cover,
                        repli: initiales,
                      )
                    : initiales,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      compte.nomComplet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      compte.identifiant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 12.5,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pastille(
                          texte: compte.estVendeur ? 'Vendeur' : 'Client',
                          fond: compte.estVendeur
                              ? AppColor.kSecondaryLight
                              : AppColor.kPrimaryLight,
                          couleur: compte.estVendeur
                              ? AppColor.kSecondaryDark
                              : AppColor.kPrimary,
                        ),
                        if (!compte.sessionOuverte)
                          const _Pastille(
                            texte: 'Mot de passe requis',
                            fond: AppColor.kLine,
                            couleur: AppColor.kGrayscale60,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (chargement)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Retirer ce compte',
                  onPressed: onRetirer,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColor.kGrayscale30,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({
    required this.texte,
    required this.fond,
    required this.couleur,
  });

  final String texte;
  final Color fond;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: fond,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      texte,
      style: TextStyle(
        fontFamily: kPolice,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: couleur,
      ),
    ),
  );
}
