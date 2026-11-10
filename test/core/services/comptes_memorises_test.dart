import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/services/comptes_memorises.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';

User _user(String id, {String role = 'Acheteur'}) => User(
  id: id,
  nom: 'Diop',
  prenom: 'Awa $id',
  email: 'awa$id@exemple.sn',
  mot_de_passe: '',
  adresse: '',
  telephone: '',
  role: role,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ComptesMemorises comptes;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    comptes = ComptesMemorises(stockage: const FlutterSecureStorage());
  });

  test('le dernier compte utilisé passe en tête, sans doublon', () async {
    await comptes.enregistrer(_user('1'), 'r1');
    await comptes.enregistrer(_user('2', role: 'Vendeur'), 'r2');
    await comptes.enregistrer(_user('1'), 'r1-bis');

    final liste = await comptes.lister();
    expect(liste.map((c) => c.id), ['1', '2']);
    expect(liste.first.refreshToken, 'r1-bis');
    expect(liste.last.estVendeur, isTrue);
  });

  test('au plus cinq comptes : le plus ancien est oublié', () async {
    for (var i = 1; i <= 6; i++) {
      await comptes.enregistrer(_user('$i'), 'r$i');
    }
    final ids = (await comptes.lister()).map((c) => c.id).toList();
    expect(ids, ['6', '5', '4', '3', '2']);
  });

  test('la déconnexion garde le compte mais retire sa session', () async {
    await comptes.enregistrer(_user('1'), 'r1');
    await comptes.majJeton('1', null);

    final compte = (await comptes.lister()).single;
    expect(compte.sessionOuverte, isFalse);
    expect(compte.identifiant, 'awa1@exemple.sn');
  });

  test('un renouvellement remplace le jeton du bon compte', () async {
    await comptes.enregistrer(_user('1'), 'r1');
    await comptes.enregistrer(_user('2'), 'r2');
    await comptes.majJeton('1', 'r1-neuf');

    final parId = {for (final c in await comptes.lister()) c.id: c};
    expect(parId['1']!.refreshToken, 'r1-neuf');
    expect(parId['2']!.refreshToken, 'r2');
  });

  test('retirer un compte l\'enlève de la liste', () async {
    await comptes.enregistrer(_user('1'), 'r1');
    await comptes.enregistrer(_user('2'), 'r2');
    await comptes.oublier('1');
    expect((await comptes.lister()).map((c) => c.id), ['2']);
  });
}
