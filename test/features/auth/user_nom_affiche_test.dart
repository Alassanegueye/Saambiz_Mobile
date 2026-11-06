import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';

User _user({
  String prenom = '',
  String nom = '',
  String email = '',
  String telephone = '',
}) => User(
  id: '1',
  nom: nom,
  prenom: prenom,
  email: email,
  mot_de_passe: '',
  adresse: '',
  telephone: telephone,
  role: 'VENDEUR',
);

void main() {
  test('prénom et nom en priorité', () {
    final u = _user(prenom: 'Awa', nom: 'Diop', email: 'awa@exemple.com');
    expect(u.nomAffiche, 'Awa Diop');
  });

  test('un seul des deux suffit, sans espace en trop', () {
    expect(_user(prenom: ' Awa ').nomAffiche, 'Awa');
    expect(_user(nom: 'Diop').nomAffiche, 'Diop');
  });

  test("sans nom, l'e-mail puis le téléphone", () {
    expect(
      _user(email: 'awa@exemple.com', telephone: '770000000').nomAffiche,
      'awa@exemple.com',
    );
    expect(_user(telephone: '770000000').nomAffiche, '770000000');
  });

  test('rien de renseigné : chaîne vide', () {
    expect(_user().nomAffiche, '');
  });
}
