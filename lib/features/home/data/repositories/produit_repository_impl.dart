import '../models/produit_model.dart';
import '../datasources/produit_remote_datasource.dart';

class ProduitRepository {
  final ProduitRemoteDataSource remote;

  ProduitRepository(this.remote);

  Future<List<ProduitModel>> getProduits() => remote.getProduits();

  Future<List<ProduitModel>> rechercher(String query) =>
      remote.rechercher(query);

  Future<List<ProduitModel>> filtrerVille(String ville) =>
      remote.filtrerVille(ville);
}