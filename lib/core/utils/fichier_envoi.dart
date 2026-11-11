import 'package:dio/dio.dart';

/// Fichier prêt à partir dans un formulaire multipart, avec son vrai type.
///
/// `MultipartFile.fromFile` seul envoie « application/octet-stream » : le
/// serveur, qui n'accepte que JPEG, PNG et PDF, refusait alors la photo et
/// l'ajout d'un produit échouait en « erreur 500 ». Le type est déduit de
/// l'extension ; le serveur vérifie de toute façon le contenu réel.
Future<MultipartFile> fichierAEnvoyer(String chemin, {String? nom}) {
  final extension = chemin.split('.').last.toLowerCase();
  final type = switch (extension) {
    'png' => DioMediaType('image', 'png'),
    'pdf' => DioMediaType('application', 'pdf'),
    _ => DioMediaType('image', 'jpeg'),
  };
  return MultipartFile.fromFile(
    chemin,
    filename: nom ?? chemin.split(RegExp(r'[\\/]')).last,
    contentType: type,
  );
}
