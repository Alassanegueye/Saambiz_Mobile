/// Masque les valeurs sensibles avant qu'elles n'atteignent le journal.
///
/// L'intercepteur HTTP imprime le corps de chaque requête et de chaque
/// réponse. C'est précieux pour déboguer, et c'est aussi le chemin le plus
/// court pour voir passer en clair :
///
///   * le mot de passe, sur `/auth/login` et `/account/change-password` ;
///   * le jeton d'identité Google ou Apple, sur `/auth/social` ;
///   * le jeton de session et son jeton de renouvellement, dans la réponse
///     de connexion.
///
/// Ces impressions sont déjà limitées au mode débogage — rien n'est écrit
/// dans une version publiée. Mais un journal de développement se retrouve
/// dans une capture d'écran, un partage d'écran, un rapport de bogue ou les
/// traces d'une intégration continue, et un mot de passe réel y reste un mot
/// de passe réel.
///
/// Le masquage est donc fait à la source, pas laissé à la vigilance de celui
/// qui lit.
library;

/// Noms de champs dont la valeur ne doit jamais apparaître, comparés sans
/// tenir compte de la casse ni des séparateurs.
const Set<String> _champsSensibles = {
  'password',
  'motdepasse',
  'mot_de_passe',
  'ancienmotdepasse',
  'nouveaumotdepasse',
  'token',
  'idtoken',
  'accesstoken',
  'refreshtoken',
  'jwt',
  'secret',
  'cle',
  'apikey',
  'authorization',
  'code',
  'nonce',
};

const String _masque = '•••';

bool _estSensible(String cle) {
  final normalisee = cle.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
  if (_champsSensibles.contains(normalisee)) return true;
  // `motDePasseConfirmation`, `refreshTokenExpire`… : un champ qui CONTIENT
  // un nom sensible l'est aussi.
  return _champsSensibles.any(
    (sensible) => sensible.length > 4 && normalisee.contains(sensible),
  );
}

/// Rend une copie de [donnees] où toute valeur sensible est remplacée.
///
/// Parcourt les dictionnaires et les listes imbriqués : une charge utile
/// `{ utilisateur: { token: … } }` est masquée aussi profond qu'il le faut.
/// Les valeurs non sensibles sont conservées telles quelles — un journal
/// entièrement masqué ne sert plus à déboguer.
Object? masquerDonneesSensibles(Object? donnees) {
  if (donnees is Map) {
    return {
      for (final entree in donnees.entries)
        entree.key: _estSensible(entree.key.toString())
            ? _masque
            : masquerDonneesSensibles(entree.value),
    };
  }
  if (donnees is List) {
    return donnees.map(masquerDonneesSensibles).toList();
  }
  return donnees;
}

/// Variante pour les champs d'un envoi multipart, qui sont des chaînes.
String masquerChampMultipart(String cle, String valeur) =>
    _estSensible(cle) ? _masque : valeur;

/// Masque un en-tête HTTP (`Authorization: Bearer …`).
Object? masquerEntete(String cle, Object? valeur) =>
    _estSensible(cle) ? _masque : valeur;
