class ClientRecherche {
  final String id;
  final String nom;
  final String prenom;
  final String email;

  ClientRecherche({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
  });

  factory ClientRecherche.fromJson(Map<String, dynamic> json) {
    return ClientRecherche(
      id: json['id'].toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
    );
  }
}