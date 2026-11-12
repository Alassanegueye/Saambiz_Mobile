/// Simulation des paiements mobiles (Orange Money, Wave), utilisée tant que
/// les API des opérateurs ne sont pas branchées (voir `Env.paiementSimule`).
///
/// Le résultat dépend uniquement du numéro saisi : les numéros de test
/// ci-dessous donnent toujours la même issue, pour pouvoir rejouer chaque
/// cas. Tout autre numéro est refusé, afin qu'on ne croie jamais avoir payé
/// pour de vrai.
library;

enum IssuePaiementTest { reussi, soldeInsuffisant, annule }

class NumeroTest {
  final String numero;
  final String libelle;
  final IssuePaiementTest issue;
  const NumeroTest(this.numero, this.libelle, this.issue);

  /// `77 000 00 01`, plus lisible que les neuf chiffres collés.
  String get affiche =>
      '${numero.substring(0, 2)} ${numero.substring(2, 5)} '
      '${numero.substring(5, 7)} ${numero.substring(7)}';
}

const numerosTest = <NumeroTest>[
  NumeroTest('770000001', 'Paiement réussi', IssuePaiementTest.reussi),
  NumeroTest(
    '770000002',
    'Solde insuffisant',
    IssuePaiementTest.soldeInsuffisant,
  ),
  NumeroTest('770000003', 'Refusé par le client', IssuePaiementTest.annule),
];

class ResultatPaiementTest {
  final bool reussi;
  final String message;
  final String reference;
  const ResultatPaiementTest({
    required this.reussi,
    required this.message,
    required this.reference,
  });
}

/// Garde uniquement les chiffres et retire l'indicatif +221.
String normaliserNumero(String saisie) {
  var n = saisie.replaceAll(RegExp(r'\D'), '');
  if (n.startsWith('00221')) n = n.substring(5);
  if (n.startsWith('221') && n.length == 12) n = n.substring(3);
  return n;
}

/// Numéro mobile sénégalais : 9 chiffres commençant par 7.
bool numeroValide(String saisie) =>
    RegExp(r'^7\d{8}$').hasMatch(normaliserNumero(saisie));

Future<ResultatPaiementTest> simulerPaiement({
  required String numero,
  required String methode,
  required num montant,
}) async {
  // Le temps que l'opérateur réponde, pour un rendu réaliste.
  await Future<void>.delayed(const Duration(milliseconds: 1800));
  final n = normaliserNumero(numero);
  final reference =
      'TEST-${methode == 'wave' ? 'WV' : 'OM'}-'
      '${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
  final cas = numerosTest.where((t) => t.numero == n).firstOrNull;
  final operateur = methode == 'wave' ? 'Wave' : 'Orange Money';
  return switch (cas?.issue) {
    IssuePaiementTest.reussi => ResultatPaiementTest(
      reussi: true,
      reference: reference,
      message:
          'Paiement de ${montant.toStringAsFixed(0)} FCFA réussi via '
          '$operateur (simulation).',
    ),
    IssuePaiementTest.soldeInsuffisant => ResultatPaiementTest(
      reussi: false,
      reference: reference,
      message: 'Solde $operateur insuffisant (simulation).',
    ),
    IssuePaiementTest.annule => ResultatPaiementTest(
      reussi: false,
      reference: reference,
      message: 'Paiement refusé depuis le téléphone (simulation).',
    ),
    null => ResultatPaiementTest(
      reussi: false,
      reference: reference,
      message:
          'Mode test : utilisez un des numéros de test indiqués. '
          'Aucun vrai paiement n\'est possible pour l\'instant.',
    ),
  };
}
