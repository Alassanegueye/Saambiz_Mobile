// Constantes des endpoints REST du backend SaamBiz.
//
// Regroupées par domaine fonctionnel afin d'éviter les chaînes littérales
// éparpillées dans les datasources. Le préfixe commun de l'API vient de
// `API_BASE_URL` (.env) et sert de `baseUrl` au Dio partagé
// (voir injection_container.dart) : il ne doit donc PAS être répété ici.

/// Authentification (déjà utilisée par [AuthRemoteDataSource]).
class AuthEndpoints {
  AuthEndpoints._();

  static const login = '/auth/login';
  static const register = '/auth/register';

  /// Vérification de l'adresse email par code à 6 chiffres (POST { email, code }).
  // Inscription en deux temps
  // L'adresse est vérifiée AVANT que le compte n'existe : une adresse jamais
  // confirmée ne laisse donc aucune ligne utilisateur derrière elle.
  static const envoyerCodeInscription = '/auth/inscription/envoyer-code';
  static const verifierCodeInscription = '/auth/inscription/verifier-code';

  // Vérification d'un compte DÉJÀ créé, conservée pour les comptes ouverts
  // avant l'inscription en deux temps.
  static const verifyEmail = '/auth/verify-email';

  // `/auth/resend-verification` n'est pas déclarée ici : l'inscription en deux
  // temps renvoie un code par `envoyerCodeInscription`, et cette constante
  // n'était appelée nulle part. La route existe toujours côté backend pour les
  // comptes ouverts avant ce changement.
}

/// Produits/boutiques côté acheteur (feature `home`).
class ProduitEndpoints {
  ProduitEndpoints._();

  static const listeProduits = '/acheteurs/liste-produits';
  static const listeBoutiques = '/acheteurs/liste-boutiques';
  static const rechercherProduitCategorie =
      '/acheteurs/rechercher-produit-categorie';
  static const filtrerProduitVille = '/acheteurs/filtrer-produit-ville';
  static String listeProduitParBoutique(String boutiqueId) =>
      '/acheteurs/liste-produit-par-boutique/$boutiqueId';
  static String contacterVendeurParWhatsapp(String produitId) =>
      '/acheteurs/contacter-vendeur-par-whatsapp/$produitId';
  static String produit(String id) => '/acheteurs/produit/$id';
}

/// Commandes / panier (feature `commande`).
class CommandeEndpoints {
  CommandeEndpoints._();

  static const commandes = '/commandes';
  static const commandesVendeur = '/commandes/vendeur';
  static String commande(String id) => '/commandes/$id';
  static String annuler(String id) => '/commandes/$id/annuler';
  static String payer(String id) => '/commandes/$id/payer';
  static String statut(String id) => '/commandes/$id/statut';
  static String paiement(String id) => '/commandes/$id/paiement';
  static String demandeRetour(String id) => '/commandes/$id/demande-retour';
}

/// Gestion des produits côté vendeur (feature `vendeur`).
class VendeurProduitEndpoints {
  VendeurProduitEndpoints._();

  static const listeProduits = '/vendeur/liste-produits';
  static const categories = '/categories';
  static const ajouterProduit = '/vendeur/ajout-produit';
  static String modifierProduit(String id) => '/vendeur/modifier-produit/$id';
  static String supprimerProduit(String id) => '/vendeur/supprimer-produit/$id';
  static String disponibilite(String id) =>
      '/vendeur/produit/$id/disponibilite';
  static String dupliquer(String id) => '/vendeur/produit/$id/dupliquer';
  static String images(String id) => '/vendeur/produit/$id/images';
  static String image(String id, String imageId) =>
      '/vendeur/produit/$id/images/$imageId';
}

/// Compte utilisateur (profil connecté, mot de passe).
class CompteEndpoints {
  CompteEndpoints._();

  static const me = '/account/me';
  static const modifierProfil = '/account/modifier-profil';
  static const changePassword = '/account/change-password';
  static const forgotPassword = '/account/forgot-password';
  static const resetPassword = '/account/reset-password';
  // Suppression de compte en libre-service (exigence Google Play : toute app
  // avec création de compte doit permettre à l'utilisateur de le supprimer).
  static const deleteAccount = '/account/me';
}

/// Boutique du vendeur.
class BoutiqueEndpoints {
  BoutiqueEndpoints._();

  static const maBoutique = '/vendeur/ma-boutique';
  static const creerBoutique = '/vendeur/creer-boutique';
  static const modifierBoutique = '/vendeur/modifier-boutique';
  static const pause = '/vendeur/boutique/pause';
  static const reactiver = '/vendeur/boutique/reactiver';

  /// Badge « Boutique vérifiée » : état de la demande, et dépôt du dossier.
  static const statutVerification = '/vendeur/statut-verification';
  static const soumettreVerification = '/vendeur/soumettre-verification';

  /// Abonnés de la boutique, et fiche d'un abonné.
  static const abonnes = '/vendeur/abonnes';
  static String abonne(String id) => '/vendeur/abonnes/$id';
}

/// Le site web public de la boutique, « vitrine ».
///
/// La CRÉATION du site se fait ici, dans l'application : c'est le seul endroit
/// où le vendeur téléverse son logo et répond sur son activité. Le tableau de
/// bord web ne sert qu'à reprendre un site déjà composé.
class VitrineEndpoints {
  VitrineEndpoints._();

  static const secteurs = '/vendeur/vitrine/secteurs';
  static const analyserLogo = '/vendeur/vitrine/analyser-logo';
  static const generer = '/vendeur/vitrine/generer';
  static const maVitrine = '/vendeur/ma-vitrine';

  /// Rendu du site tel qu'il sera publié, avant de le mettre en ligne.
  static const apercu = '/vendeur/ma-vitrine/apercu';
}

/// Abonnement vendeur.
class AbonnementEndpoints {
  AbonnementEndpoints._();

  static const monAbonnement = '/vendeur/mon-abonnement';
  static const initierRenouvellement = '/vendeur/initier-renouvellement';
  static const historiquePaiements = '/vendeur/historique-paiements';
}

/// Paiement (Orange Money / Wave).
class PaiementEndpoints {
  PaiementEndpoints._();

  static const payer = '/paiement/payer';
  static const historique = '/paiement';
  static String paiement(String id) => '/paiement/$id';
}

/// Favoris / suivi de boutique (acheteur).
class FavorisEndpoints {
  FavorisEndpoints._();

  static const favoris = '/favoris';
  static String parId(String boutiqueId) => '/favoris/$boutiqueId';
  //  Cloche : activer/désactiver les notifications d'une boutique suivie
  static String cloche(String boutiqueId) => '/favoris/$boutiqueId/cloche';
  // État de suivi (suivi ? cloche active ?)
  static String statut(String boutiqueId) => '/favoris/$boutiqueId/statut';
}

/// Messagerie (temps réel via socket + REST).
class MessagerieEndpoints {
  MessagerieEndpoints._();

  static const messages = '/messages';
  static const conversations = '/messages/conversations';
  static const nonLus = '/messages/non-lus';
  static String historique(String userId) => '/messages/$userId';
  static String marquerLu(String messageId) => '/messages/$messageId/lire';
}

/// Notifications (temps réel via socket + REST) + device token FCM.
class NotificationsEndpoints {
  NotificationsEndpoints._();

  static const notifications = '/notifications';
  static const nonLues = '/notifications/non-lues';
  static const toutesLues = '/notifications/toutes-lues';
  static String marquerLue(String id) => '/notifications/$id/lire';
  static const registerDeviceToken = '/device-token/register';
  static const unregisterDeviceToken = '/device-token/unregister';
}

/// Promotions.
class PromotionsEndpoints {
  PromotionsEndpoints._();

  static const actives = '/promotions/actives';
  static const promotions = '/promotions';
  static String parId(String id) => '/promotions/$id';
}

/// Avis laissés par les acheteurs sur une boutique.
class AvisEndpoints {
  AvisEndpoints._();

  static const avis = '/avis';
  static String boutique(String boutiqueId) => '/avis/boutique/$boutiqueId';
  static String monAvis(String boutiqueId) =>
      '/avis/boutique/$boutiqueId/mon-avis';
}

/// Catégories du catalogue.
class CategorieEndpoints {
  CategorieEndpoints._();

  static const categories = '/categories';
  static String categorie(String idOuSlug) => '/categories/$idOuSlug';
  static String boutiques(String idOuSlug) => '/categories/$idOuSlug/boutiques';
}

/// Signalements.
class SignalementsEndpoints {
  SignalementsEndpoints._();

  static const signalements = '/signalements';
  static const mesSignalements = '/signalements/mes-signalements';
}

/// Réglages publics du backend, servis sans authentification.
///
/// Deux routes que l'application n'appelait pas alors qu'elles existaient :
/// le prix de l'abonnement était donc inconnu côté mobile, et l'app ne voyait
/// ni les mises en maintenance ni les versions minimales exigées.
class ConfigEndpoints {
  ConfigEndpoints._();

  /// `{ prix: 2000, devise: 'FCFA' }`
  static const prixAbonnement = '/prix-abonnement';

  /// `{ contacts: { whatsapp, email, telephone }, questions: [...] }`,
  /// rédigés depuis le dashboard admin.
  static const centreAide = '/centre-aide';

  /// `{ minVersionAndroid, minVersionIos, maintenance, message }`
  static const appConfig = '/app/config';
}

/// Dashboard / statistiques vendeur.
class VendeurDashboardEndpoints {
  VendeurDashboardEndpoints._();

  static const dashboard = '/vendeur/dashboard';
  static const statistiques = '/vendeur/statistiques';
  static const statistiquesVues = '/vendeur/statistiques-vues';
  static const nombreProduit = '/vendeur/nombre-produit';
  static const nombreProduitCategorie = '/vendeur/nombre-produit-categorie';
  static const rechercheProduits = '/vendeur/recherche-produits';
}
