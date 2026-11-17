import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/messagerie/presentation/pages/chat_page.dart';

void main() {
  test('les séparateurs du fil : aujourd’hui, hier, puis la date', () {
    final midi = DateTime(2026, 11, 17, 12);
    expect(
      libelleJourMessage(DateTime(2026, 11, 17, 9), maintenant: midi),
      'Aujourd’hui',
    );
    expect(
      libelleJourMessage(DateTime(2026, 11, 16, 22), maintenant: midi),
      'Hier',
    );
    expect(
      libelleJourMessage(DateTime(2026, 11, 12, 10), maintenant: midi),
      '12 novembre 2026',
    );
  });
}
