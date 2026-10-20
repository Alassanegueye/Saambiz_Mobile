/// Libellé lisible d'une valeur technique renvoyée par l'API (statut,
/// formule, moyen de paiement…) : « essai » → « Essai », « expire » →
/// « Expiré », « orange_money » → « Orange Money ». Une valeur inconnue prend
/// une majuscule initiale : rien ne s'affiche en minuscules brutes.
const Map<String, String> _libelles = {
  'actif': 'Actif',
  'inactif': 'Inactif',
  'suspendu': 'Suspendu',
  'essai': 'Essai',
  'mensuel': 'Mensuel',
  'annuel': 'Annuel',
  'premium': 'Premium',
  'gratuit': 'Gratuit',
  'expire': 'Expiré',
  'revoque': 'Révoqué',
  'en_attente': 'En attente',
  'en_cours': 'En cours',
  'reussi': 'Réussi',
  'echoue': 'Échoué',
  'echec': 'Échec',
  'paye': 'Payé',
  'non_paye': 'Non payé',
  'rembourse': 'Remboursé',
  'annule': 'Annulé',
  'wave': 'Wave',
  'orange_money': 'Orange Money',
  'free_money': 'Free Money',
};

String libelle(String? valeur, {String vide = '—'}) {
  if (valeur == null || valeur.trim().isEmpty) return vide;
  final v = valeur.trim();
  final connu = _libelles[v.toLowerCase()];
  if (connu != null) return connu;
  final texte = v.replaceAll('_', ' ');
  return texte[0].toUpperCase() + texte.substring(1);
}
