/// Minuscules, sans accents : « beaute » trouve « Beauté & cosmétiques ».
///
/// Sert aux recherches faites sur place, dans une liste déjà chargée.
String plierTexte(String texte) {
  const avec = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ';
  const sans = 'aaaaaaceeeeiiiinooooouuuuyyoa';
  final buffer = StringBuffer();
  for (final c in texte.toLowerCase().trim().split('')) {
    final i = avec.indexOf(c);
    buffer.write(i < 0 ? c : sans[i]);
  }
  return buffer.toString();
}

/// Vrai si [texte] contient [recherche], sans tenir compte des accents ni
/// de la casse. Une recherche vide correspond à tout.
bool contientRecherche(String texte, String recherche) =>
    plierTexte(texte).contains(plierTexte(recherche));
