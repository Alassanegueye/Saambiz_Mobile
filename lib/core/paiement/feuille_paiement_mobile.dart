import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/env.dart';
import '../theme/app_color.dart';
import '../theme/police.dart';
import 'paiement_simule.dart';

/// Choix fait dans [FeuillePaiementMobile].
class ChoixPaiementMobile {
  /// `orange_money` ou `wave`, comme l'attend le backend.
  final String methode;

  /// Neuf chiffres, sans indicatif.
  final String numero;
  const ChoixPaiementMobile(this.methode, this.numero);
}

/// Ouvre la feuille de paiement mobile (Orange Money / Wave) et renvoie le
/// choix validé, ou `null` si l'utilisateur ferme la feuille.
Future<ChoixPaiementMobile?> choisirPaiementMobile(
  BuildContext context, {
  required String titre,
  num? montant,
  String? numeroInitial,
}) {
  return showModalBottomSheet<ChoixPaiementMobile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FeuillePaiementMobile(
      titre: titre,
      montant: montant,
      numeroInitial: numeroInitial,
    ),
  );
}

class FeuillePaiementMobile extends StatefulWidget {
  final String titre;
  final num? montant;
  final String? numeroInitial;

  const FeuillePaiementMobile({
    super.key,
    required this.titre,
    this.montant,
    this.numeroInitial,
  });

  @override
  State<FeuillePaiementMobile> createState() => _FeuillePaiementMobileState();
}

class _FeuillePaiementMobileState extends State<FeuillePaiementMobile> {
  late final _numero = TextEditingController(text: widget.numeroInitial);
  String _methode = 'orange_money';
  String? _erreur;

  @override
  void dispose() {
    _numero.dispose();
    super.dispose();
  }

  void _valider() {
    if (!numeroValide(_numero.text)) {
      setState(
        () =>
            _erreur = 'Saisissez un numéro à 9 chiffres, par ex. 77 123 45 67',
      );
      return;
    }
    Navigator.of(
      context,
    ).pop(ChoixPaiementMobile(_methode, normaliserNumero(_numero.text)));
  }

  @override
  Widget build(BuildContext context) {
    final bas = MediaQuery.of(context).viewInsets.bottom;
    final montant = widget.montant;
    return Padding(
      padding: EdgeInsets.only(bottom: bas),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColor.kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColor.kGrayscale20,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.titre,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                if (montant != null && montant > 0) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: 'Montant à payer : ',
                      children: [
                        TextSpan(
                          text: '${montant.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14,
                      color: AppColor.kGrayscale40,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const _Libelle('Moyen de paiement'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _CarteOperateur(
                        operateur: Operateur.orangeMoney,
                        choisi: _methode == 'orange_money',
                        onTap: () => setState(() => _methode = 'orange_money'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CarteOperateur(
                        operateur: Operateur.wave,
                        choisi: _methode == 'wave',
                        onTap: () => setState(() => _methode = 'wave'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Libelle(
                  'Numéro ${_methode == 'wave' ? 'Wave' : 'Orange Money'}',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _numero,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
                    LengthLimitingTextInputFormatter(16),
                  ],
                  onChanged: (_) {
                    if (_erreur != null) setState(() => _erreur = null);
                  },
                  onSubmitted: (_) => _valider(),
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: '77 123 45 67',
                    errorText: _erreur,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Text(
                        '🇸🇳 +221',
                        style: TextStyle(
                          fontFamily: kPolice,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColor.kGrayscale60,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  ),
                ),
                if (Env.paiementSimule) ...[
                  const SizedBox(height: 16),
                  _EncadreTest(
                    onChoisir: (n) => setState(() {
                      _numero.text = n.numero;
                      _erreur = null;
                    }),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _valider,
                    style: FilledButton.styleFrom(
                      backgroundColor: _methode == 'wave'
                          ? Operateur.wave.couleur
                          : Operateur.orangeMoney.couleur,
                      foregroundColor: AppColor.kWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      montant != null && montant > 0
                          ? 'Payer ${montant.toStringAsFixed(0)} FCFA'
                          : 'Payer',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.kGrayscale40,
                  ),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Libelle extends StatelessWidget {
  final String texte;
  const _Libelle(this.texte);

  @override
  Widget build(BuildContext context) => Text(
    texte,
    style: const TextStyle(
      fontFamily: kPolice,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColor.kGrayscale60,
    ),
  );
}

/// Opérateurs de paiement mobile pris en charge.
enum Operateur {
  orangeMoney(
    nom: 'Orange Money',
    couleur: Color(0xFFFF7900),
    logo: 'assets/images/orange_money.png',
  ),
  wave(nom: 'Wave', couleur: Color(0xFF1DC4FF), logo: 'assets/images/wave.png');

  final String nom;
  final Color couleur;

  /// Logo officiel : il suffit de déposer le fichier à cet emplacement.
  /// Sans lui, une pastille aux couleurs de l'opérateur le remplace.
  final String logo;
  const Operateur({
    required this.nom,
    required this.couleur,
    required this.logo,
  });
}

/// Logo de l'opérateur, avec une pastille de repli dessinée.
class LogoOperateur extends StatelessWidget {
  final Operateur operateur;
  final double taille;
  const LogoOperateur(this.operateur, {super.key, this.taille = 44});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(taille * 0.26),
      child: SizedBox(
        width: taille,
        height: taille,
        child: Image.asset(
          operateur.logo,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _repli(),
        ),
      ),
    );
  }

  Widget _repli() {
    return switch (operateur) {
      Operateur.orangeMoney => ColoredBox(
        color: AppColor.kNoir,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: taille * 0.3,
              child: ColoredBox(color: operateur.couleur),
            ),
            Align(
              alignment: const Alignment(0, -0.25),
              child: Text(
                'OM',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: taille * 0.36,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kWhite,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      Operateur.wave => ColoredBox(
        color: operateur.couleur,
        child: Icon(
          Icons.waves_rounded,
          size: taille * 0.6,
          color: AppColor.kWhite,
        ),
      ),
    };
  }
}

class _CarteOperateur extends StatelessWidget {
  final Operateur operateur;
  final bool choisi;
  final VoidCallback onTap;

  const _CarteOperateur({
    required this.operateur,
    required this.choisi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: choisi,
      button: true,
      label: operateur.nom,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: choisi
              ? operateur.couleur.withValues(alpha: 0.08)
              : AppColor.kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: choisi ? operateur.couleur : AppColor.kLine,
            width: choisi ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      LogoOperateur(operateur),
                      const SizedBox(height: 10),
                      Text(
                        operateur.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.kGrayscaleDark100,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: -4,
                    right: -2,
                    child: AnimatedOpacity(
                      opacity: choisi ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: operateur.couleur,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Numéros de test, affichés tant que les paiements sont simulés.
class _EncadreTest extends StatelessWidget {
  final ValueChanged<NumeroTest> onChoisir;
  const _EncadreTest({required this.onChoisir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColor.kSecondaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.kSecondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: 18,
                color: AppColor.kSecondaryDark,
              ),
              SizedBox(width: 6),
              Text(
                'Mode test : aucun argent ne sera débité',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Touchez un numéro pour simuler le cas correspondant.',
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 12,
              color: AppColor.kGrayscale60,
            ),
          ),
          const SizedBox(height: 4),
          for (final n in numerosTest)
            InkWell(
              onTap: () => onChoisir(n),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      n.affiche,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        n.libelle,
                        style: TextStyle(
                          fontFamily: kPolice,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: n.issue == IssuePaiementTest.reussi
                              ? AppColor.kSucces
                              : AppColor.kErreur,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.touch_app_outlined,
                      size: 16,
                      color: AppColor.kGrayscale40,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
