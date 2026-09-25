import '../datasources/commande_remote_datasource.dart';
import '../models/commande_model.dart';

/// Repository commande — fine couche au-dessus du datasource.
class CommandeRepository {
  final CommandeRemoteDataSource remote;
  CommandeRepository(this.remote);

  Future<CommandeModel> creerCommande({
    required List<Map<String, dynamic>> items,
    String modeLivraison = 'livraison',
    String modePaiement = 'en_ligne',
    String? adresseLivraison,
    String? numeroTelephone,
    String? note,
  }) {
    return remote.creerCommande({
      'items': items,
      'modeLivraison': modeLivraison,
      'modePaiement': modePaiement,
      if (adresseLivraison != null) 'adresseLivraison': adresseLivraison,
      if (numeroTelephone != null) 'numeroTelephone': numeroTelephone,
      if (note != null) 'note': note,
    });
  }

  Future<List<CommandeModel>> mesCommandes({String? statut}) =>
      remote.mesCommandes(statut: statut);

  Future<CommandeModel> getCommande(String id) => remote.getCommande(id);

  Future<CommandeModel> annuler(String id) => remote.annuler(id);

  Future<String?> payer(String id,
          {required String methode, String? numeroTelephone}) =>
      remote.payer(id, methode: methode, numeroTelephone: numeroTelephone);

  Future<List<CommandeModel>> commandesVendeur({String? statut}) =>
      remote.commandesVendeur(statut: statut);

  Future<CommandeModel> changerStatut(String id, String statut) =>
      remote.changerStatut(id, statut);

  Future<void> demandeRetour(String id, {required String raison}) =>
      remote.demandeRetour(id, raison: raison);
}
