import 'package:saambiz/core/utils/fichier_envoi.dart';
import 'package:dio/dio.dart';

/// Où en est la certification du vendeur.
///
/// - `non_soumis` : il n'a encore rien envoyé ;
/// - `en_attente` : sa demande est entre les mains de l'équipe SaamBiz ;
/// - `approuve`   : il est certifié, sa boutique porte le badge ;
/// - `rejete`     : la demande a été refusée, [motifRejet] dit pourquoi.
class StatutCertification {
  final String statut;
  final String? motifRejet;

  const StatutCertification({required this.statut, this.motifRejet});

  bool get certifie => statut == 'approuve';
  bool get enAttente => statut == 'en_attente';
  bool get rejete => statut == 'rejete';

  /// Le vendeur a quelque chose à faire : c'est ce qui allume le point rouge.
  bool get actionRequise => statut == 'non_soumis' || statut == 'rejete';
}

/// Appels réseau de la certification (pièce d'identité recto + verso).
class CertificationService {
  final Dio dio;
  CertificationService(this.dio);

  Future<StatutCertification> statut() async {
    final res = await dio.get('/vendeur/statut-verification');
    final data = res.data;
    final v = data is Map && data['verification'] is Map
        ? data['verification'] as Map
        : const {};
    return StatutCertification(
      statut: (v['statutValidation'] ?? 'non_soumis').toString(),
      motifRejet: v['motifRejet']?.toString(),
    );
  }

  /// Envoie les deux photos. Retourne le message du serveur.
  Future<String> soumettre({
    required String rectoPath,
    required String versoPath,
  }) async {
    final form = FormData.fromMap({
      'typePiece': "Pièce d'identité",
      'recto': await fichierAEnvoyer(rectoPath, nom: 'recto.jpg'),
      'verso': await fichierAEnvoyer(versoPath, nom: 'verso.jpg'),
    });
    final res = await dio.post('/vendeur/soumettre-verification', data: form);
    final data = res.data;
    return data is Map && data['message'] != null
        ? data['message'].toString()
        : 'Demande envoyée.';
  }
}
