class Personne {
  final String id;
  final String nom;
  final String prenom;
  final String email;

  Personne({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
  });

  factory Personne.fromJson(Map<String, dynamic> json) {
    return Personne(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
    );
  }

  String get nomComplet => '$prenom $nom'.trim();
}