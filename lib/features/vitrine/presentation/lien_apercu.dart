/// Adresse du site d'une boutique, ouverte par son propre vendeur depuis
/// l'application : marquée `apercu=1` pour que ses passages ne comptent pas
/// comme des visites. Le site garde ce mode pour l'onglet.
///
/// Seul le bouton « ouvrir » s'en sert : le lien copié ou partagé avec les
/// clients reste propre.
String lienApercu(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return url;
  return uri
      .replace(queryParameters: {...uri.queryParameters, 'apercu': '1'})
      .toString();
}
