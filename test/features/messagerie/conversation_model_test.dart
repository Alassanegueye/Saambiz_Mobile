import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/messagerie/data/models/message_model.dart';

/// Une conversation telle que GET /messages/conversations la renvoie : le
/// dernier message brut, plus `interlocuteur` et `nombreNonLus`.
Map<String, dynamic> _conversation({Map<String, dynamic>? boutique}) => {
  'id': 'm3',
  'contenu': 'Fils',
  'createdAt': '2026-11-12T13:34:00Z',
  'expediteurId': 'v1',
  'destinataireId': 'a1',
  'interlocuteurId': 'v1',
  'interlocuteur': {
    'id': 'v1',
    'prenom': 'Alou',
    'nom': 'Diop',
    'photoProfil': 'https://cdn/photo.png',
    'boutique': boutique,
  },
  'nombreNonLus': 2,
};

void main() {
  test('un vendeur apparaît sous le nom et le logo de sa boutique', () {
    final c = ConversationModel.fromJson(
      _conversation(
        boutique: {
          'id': 'b1',
          'nom': 'Aloushop',
          'logo': 'https://cdn/logo.png',
        },
      ),
    );
    expect(c.interlocuteurId, 'v1');
    expect(c.interlocuteurNom, 'Aloushop');
    expect(c.interlocuteurPhoto, 'https://cdn/logo.png');
    expect(c.dernierMessage, 'Fils');
    expect(c.nombreNonLus, 2);
  });

  test('sans boutique : prénom, nom et photo de profil', () {
    final c = ConversationModel.fromJson(_conversation());
    expect(c.interlocuteurNom, 'Alou Diop');
    expect(c.interlocuteurPhoto, 'https://cdn/photo.png');
  });

  test('une boutique sans logo garde la photo de profil', () {
    final c = ConversationModel.fromJson(
      _conversation(boutique: {'id': 'b1', 'nom': 'Aloushop', 'logo': null}),
    );
    expect(c.interlocuteurNom, 'Aloushop');
    expect(c.interlocuteurPhoto, 'https://cdn/photo.png');
  });
}
