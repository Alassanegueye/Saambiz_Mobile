import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pays proposés pour un numéro de téléphone, avec leurs règles.
///
/// La liste est volontairement courte : les pays où vendent et achètent les
/// utilisateurs de SaamBiz. Les mêmes règles sont appliquées par le serveur
/// (Backend/src/utils/telephone.js) : les deux listes doivent rester alignées.
class PaysTelephone {
  /// Code ISO (« SN »).
  final String code;
  final String nom;
  final String drapeau;

  /// Indicatif, avec le « + » (« +221 »).
  final String indicatif;

  /// Nombre de chiffres du numéro national, sans l'indicatif.
  final int longueur;

  /// Débuts autorisés du numéro national (vide : tous).
  final List<String> debuts;

  /// Exemple affiché dans le champ.
  final String exemple;

  /// Le « 0 » de tête de la numérotation nationale se retire avant
  /// l'indicatif (France, Maroc : 06… → +33 6…).
  final bool zeroNational;

  const PaysTelephone({
    required this.code,
    required this.nom,
    required this.drapeau,
    required this.indicatif,
    required this.longueur,
    required this.exemple,
    this.debuts = const [],
    this.zeroNational = false,
  });

  /// Longueur maximale de ce que l'utilisateur peut taper (avec le 0 de tête).
  int get longueurSaisie => zeroNational ? longueur + 1 : longueur;
}

const senegal = PaysTelephone(
  code: 'SN',
  nom: 'Sénégal',
  drapeau: '🇸🇳',
  indicatif: '+221',
  longueur: 9,
  // Mobiles (Orange, Free, Expresso, Promobile) et fixes.
  debuts: ['70', '71', '75', '76', '77', '78', '33'],
  exemple: '77 123 45 67',
);

const paysTelephone = <PaysTelephone>[
  senegal,
  PaysTelephone(
    code: 'ML',
    nom: 'Mali',
    drapeau: '🇲🇱',
    indicatif: '+223',
    longueur: 8,
    debuts: ['2', '4', '5', '6', '7', '8', '9'],
    exemple: '76 12 34 56',
  ),
  PaysTelephone(
    code: 'CI',
    nom: 'Côte d’Ivoire',
    drapeau: '🇨🇮',
    indicatif: '+225',
    longueur: 10,
    debuts: ['01', '05', '07', '21', '25', '27'],
    exemple: '07 12 34 56 78',
  ),
  PaysTelephone(
    code: 'GN',
    nom: 'Guinée',
    drapeau: '🇬🇳',
    indicatif: '+224',
    longueur: 9,
    debuts: ['6', '3'],
    exemple: '621 12 34 56',
  ),
  PaysTelephone(
    code: 'MR',
    nom: 'Mauritanie',
    drapeau: '🇲🇷',
    indicatif: '+222',
    longueur: 8,
    debuts: ['2', '3', '4'],
    exemple: '22 12 34 56',
  ),
  PaysTelephone(
    code: 'GM',
    nom: 'Gambie',
    drapeau: '🇬🇲',
    indicatif: '+220',
    longueur: 7,
    exemple: '301 23 45',
  ),
  PaysTelephone(
    code: 'BF',
    nom: 'Burkina Faso',
    drapeau: '🇧🇫',
    indicatif: '+226',
    longueur: 8,
    exemple: '70 12 34 56',
  ),
  PaysTelephone(
    code: 'MA',
    nom: 'Maroc',
    drapeau: '🇲🇦',
    indicatif: '+212',
    longueur: 9,
    debuts: ['5', '6', '7'],
    exemple: '06 12 34 56 78',
    zeroNational: true,
  ),
  PaysTelephone(
    code: 'FR',
    nom: 'France',
    drapeau: '🇫🇷',
    indicatif: '+33',
    longueur: 9,
    debuts: ['1', '2', '3', '4', '5', '6', '7', '9'],
    exemple: '06 12 34 56 78',
    zeroNational: true,
  ),
];

PaysTelephone paysDuCode(String? code) => paysTelephone.firstWhere(
  (p) => p.code == code,
  orElse: () => senegal,
);

/// Les chiffres du numéro national : espaces retirés, et le 0 de tête pour
/// les pays qui le portent.
String chiffresNationaux(String saisie, PaysTelephone pays) {
  var c = saisie.replaceAll(RegExp(r'\D'), '');
  if (pays.zeroNational && c.startsWith('0')) c = c.substring(1);
  return c;
}

/// Message d'erreur, ou null si le numéro est valable pour ce pays.
String? verifierTelephone(
  String? saisie,
  PaysTelephone pays, {
  bool obligatoire = true,
}) {
  final brut = (saisie ?? '').trim();
  if (brut.isEmpty) return obligatoire ? 'Numéro de téléphone requis.' : null;
  final c = chiffresNationaux(brut, pays);
  if (c.length != pays.longueur) {
    return 'Un numéro ${_du(pays)} compte ${pays.longueur} chiffres '
        '(ex. ${pays.exemple}).';
  }
  if (pays.debuts.isNotEmpty && !pays.debuts.any(c.startsWith)) {
    return 'Ce numéro ne correspond pas à un numéro ${_du(pays)} '
        '(ex. ${pays.exemple}).';
  }
  return null;
}

String _du(PaysTelephone p) => switch (p.code) {
  'SN' => 'sénégalais',
  'ML' => 'malien',
  'CI' => 'ivoirien',
  'GN' => 'guinéen',
  'MR' => 'mauritanien',
  'GM' => 'gambien',
  'BF' => 'burkinabè',
  'MA' => 'marocain',
  'FR' => 'français',
  _ => 'de ce pays',
};

/// Numéro au format international (« +221771234567 »), celui qu'on envoie
/// au serveur. Chaîne vide si rien n'est saisi.
String telephoneInternational(String saisie, PaysTelephone pays) {
  final c = chiffresNationaux(saisie, pays);
  return c.isEmpty ? '' : '${pays.indicatif}$c';
}

/// Découpe un numéro enregistré en pays + numéro national, pour préremplir
/// un formulaire. Un ancien numéro à 9 chiffres sans indicatif est
/// sénégalais.
({PaysTelephone pays, String national}) lireTelephone(String? stocke) {
  var t = (stocke ?? '').replaceAll(RegExp(r'[^\d+]'), '');
  if (t.startsWith('00')) t = '+${t.substring(2)}';
  if (t.startsWith('+')) {
    // L'indicatif le plus long d'abord (+2xx avant +2x).
    final tries = [...paysTelephone]
      ..sort((a, b) => b.indicatif.length.compareTo(a.indicatif.length));
    for (final p in tries) {
      if (t.startsWith(p.indicatif)) {
        final national = t.substring(p.indicatif.length);
        return (
          pays: p,
          national: p.zeroNational ? '0$national' : national,
        );
      }
    }
    return (pays: senegal, national: t.replaceAll('+', ''));
  }
  if (t.startsWith('221') && t.length == 12) {
    return (pays: senegal, national: t.substring(3));
  }
  return (pays: senegal, national: t);
}

/// N'accepte que des chiffres (et des espaces), jusqu'à la longueur du pays
/// choisi : un numéro sénégalais ne peut pas dépasser 9 chiffres.
class FormatTelephone extends TextInputFormatter {
  final ValueListenable<PaysTelephone> pays;
  FormatTelephone(this.pays);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue ancien,
    TextEditingValue nouveau,
  ) {
    final propre = nouveau.text.replaceAll(RegExp(r'[^\d ]'), '');
    final chiffres = propre.replaceAll(' ', '');
    if (chiffres.length > pays.value.longueurSaisie) return ancien;
    if (propre == nouveau.text) return nouveau;
    return TextEditingValue(
      text: propre,
      selection: TextSelection.collapsed(offset: propre.length),
    );
  }
}
