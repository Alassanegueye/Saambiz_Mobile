/// Adresse d'image allégée pour l'affichage.
///
/// Les photos des vendeurs sont envoyées depuis un téléphone (3 à 5 Mo,
/// 4000 px de large) et étaient téléchargées telles quelles dans chaque liste
/// de produits : lent sur une connexion mobile, coûteux en forfait, et lourd à
/// décoder (une image de 4000 px occupe ~60 Mo de mémoire une fois décodée).
///
/// Cloudinary sait livrer une version réduite si on l'indique dans l'adresse :
///   .../image/upload/v123/saambiz/x.jpg
///   .../image/upload/c_limit,w_1080,q_auto/v123/saambiz/x.jpg
///   - `c_limit` ne fait que réduire, jamais agrandir ni recadrer ;
///   - `q_auto` laisse Cloudinary choisir la compression.
/// Pas de `f_auto` volontairement : il peut livrer de l'AVIF, que les
/// décodeurs de Flutter ne lisent pas sur toutes les plateformes.
///
/// Toute autre adresse (image locale, autre hébergeur) est rendue telle quelle.
String imageOptimisee(String url, {int largeur = 1080}) {
  const marqueur = '/image/upload/';
  if (!url.contains('res.cloudinary.com')) return url;
  final i = url.indexOf(marqueur);
  if (i < 0) return url;
  final debut = i + marqueur.length;
  // Déjà transformée par nous : ne pas empiler une seconde transformation.
  if (url.startsWith('c_limit,w_', debut)) return url;
  return '${url.substring(0, debut)}c_limit,w_$largeur,q_auto/${url.substring(debut)}';
}
