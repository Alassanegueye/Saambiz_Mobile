import 'package:flutter/material.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/texte.dart';
import '../../data/models/commande_model.dart';
// Les étapes d'une commande viennent de la fiche commande : la carte et la
// fiche suivent ainsi exactement le même parcours.
import '../pages/commande_detail_page.dart' show etapesSuiviCommande;

/// Couleur d'un statut de commande, selon la charte SaamBiz : or foncé
/// quand une action est attendue, marine pour une étape en cours, vert pour
/// le paiement reçu et la livraison, rouge pour une annulation.
///
/// L'anthracite et l'orange « de la maquette » ont été retirés : ils
/// n'appartenaient pas à la charte.
Color couleurStatutCommande(String statut) {
  switch (statut) {
    case 'livree':
    case 'payee':
      return AppColor.kSucces;
    case 'annulee':
    case 'rejetee':
      return AppColor.kErreur;
    case 'en_attente':
      return AppColor.kSecondaryDark;
    case 'acceptee':
    case 'confirmee':
    case 'en_preparation':
    case 'prete':
    case 'en_livraison':
      return AppColor.kPrimary;
    default:
      return AppColor.kGrayscale40;
  }
}

IconData iconeStatutCommande(String statut) {
  switch (statut) {
    case 'livree':
      return Icons.check_circle_rounded;
    case 'annulee':
    case 'rejetee':
      return Icons.cancel_rounded;
    case 'acceptee':
    case 'payee':
      return Icons.check_circle_outline_rounded;
    case 'en_livraison':
      return Icons.local_shipping_rounded;
    case 'prete':
      return Icons.inventory_2_rounded;
    case 'confirmee':
    case 'en_preparation':
      return Icons.autorenew_rounded;
    default:
      return Icons.schedule_rounded;
  }
}

/// Ce que le statut veut dire pour celui qui regarde la carte, en une
/// phrase courte : ce qui se passe, ou ce qu'il lui reste à faire. Le nom
/// de l'étape, lui, s'affiche sous la frise.
String messageCarteCommande(
  String statut, {
  required bool isVendeur,
  required String modePaiement,
}) {
  final enLigne = modePaiement == 'en_ligne';
  switch (statut) {
    case 'en_attente':
      return isVendeur
          ? 'Nouvelle commande : à accepter ou refuser'
          : 'Le vendeur doit confirmer votre commande';
    case 'acceptee':
      if (isVendeur) {
        return enLigne ? 'En attente du paiement du client' : 'À préparer';
      }
      return enLigne
          ? 'Vous pouvez payer votre commande'
          : 'Le vendeur va préparer votre commande';
    case 'payee':
      return isVendeur
          ? 'Payée : à préparer'
          : 'Paiement reçu, le vendeur va préparer votre commande';
    case 'confirmee':
      return isVendeur ? 'À préparer' : 'Le vendeur va préparer votre commande';
    case 'en_preparation':
      return isVendeur ? 'Préparez le colis' : 'Le vendeur prépare votre colis';
    case 'prete':
      return isVendeur ? 'À remettre au livreur' : 'Votre colis part bientôt';
    case 'en_livraison':
      return isVendeur ? 'En route vers le client' : 'Votre colis est en route';
    case 'livree':
      return isVendeur ? 'Livrée au client' : 'Votre commande a été livrée';
    case 'annulee':
      return 'Commande annulée';
    case 'rejetee':
      return isVendeur
          ? 'Vous avez refusé cette commande'
          : 'Refusée par le vendeur';
    default:
      return kStatutCommandeLabels[statut] ?? 'Statut inconnu';
  }
}

/// Les étapes de la commande et la position de son statut parmi elles.
/// Position -1 : statut absent du parcours (annulée, refusée, inconnu).
({List<String> etapes, int index}) etapesEtPosition(CommandeModel commande) {
  var etapes = etapesSuiviCommande(
    commande.statut,
    modePaiement: commande.modePaiement,
  );
  var index = etapes.indexOf(commande.statut);
  if (index < 0 && commande.statut == 'payee') {
    // Payée alors que le mode annonçait un règlement à la livraison : on
    // montre le parcours du paiement en ligne, qui contient cette étape.
    etapes = etapesSuiviCommande(commande.statut, modePaiement: 'en_ligne');
    index = etapes.indexOf(commande.statut);
  }
  return (etapes: etapes, index: index);
}

String _date(DateTime? d) {
  if (d == null) return 'Date inconnue';
  const mois = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  final l = d.toLocal();
  return '${l.day} ${mois[l.month - 1]} ${l.year}';
}

/// « 15 000 FCFA ».
String montantFcfa(double v) {
  final s = v.toStringAsFixed(0);
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b FCFA';
}

/// Carte d'une commande : vignette, identifiant, suivi (phrase, frise
/// numérotée de toutes les étapes) et adresses De / À.
///
/// Le ruban diagonal « PROCESS » / « TRANSIT » a été retiré : des mots
/// anglais, en capitales, en travers de la carte. Le statut se lit
/// maintenant en français, à sa place dans le parcours.
class CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  final VoidCallback onTap;
  final bool isVendeur;
  const CommandeCard({
    super.key,
    required this.commande,
    required this.onTap,
    this.isVendeur = false,
  });

  @override
  Widget build(BuildContext context) {
    final nbArticles = commande.lignes.fold<int>(0, (s, l) => s + l.quantite);
    final image = commande.lignes.isNotEmpty
        ? commande.lignes.first.imageProduit
        : null;
    final premier = commande.lignes.isNotEmpty
        ? commande.lignes.first.nomProduit
        : 'Commande';
    final nomClient = (commande.acheteurNom ?? '').trim();
    final titre = isVendeur
        ? (nomClient.isEmpty ? 'Client' : nomClient)
        : (nbArticles > 1 ? '$premier +${nbArticles - 1}' : premier);
    final paye = commande.statutPaiement == 'paye';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: AppColor.kWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColor.kLine, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vignette (ou initiales du client), identifiant, contenu.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isVendeur)
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColor.kPrimaryLight,
                      child: Text(
                        nomClient.isEmpty ? '?' : initialesDe(nomClient),
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColor.kPrimary,
                        ),
                      ),
                    )
                  else
                    _VignetteProduit(image: image),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: #${commande.referenceCommande}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColor.kGrayscaleDark100,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          titre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 12.5,
                            color: AppColor.kGrayscale40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Suivi(commande: commande, isVendeur: isVendeur),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColor.kLine),
              const SizedBox(height: 10),

              // De (boutique) / À (destination) et prix.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DE',
                          style: TextStyle(
                            fontFamily: kPolice,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kGrayscale40,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          commande.vendeurNom?.isNotEmpty == true
                              ? commande.vendeurNom!
                              : 'Boutique SaamBiz',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                        Text(
                          _date(commande.createdAt),
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 11,
                            color: AppColor.kGrayscale40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'À',
                          style: TextStyle(
                            fontFamily: kPolice,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kGrayscale40,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (commande.adresseLivraison?.isNotEmpty == true)
                              ? commande.adresseLivraison!
                              : (commande.acheteurNom?.isNotEmpty == true
                                    ? commande.acheteurNom!
                                    : 'Dakar, Sénégal'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              montantFcfa(commande.montantTotal),
                              style: const TextStyle(
                                fontFamily: kPolice,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColor.kPrimary,
                              ),
                            ),
                            if (paye) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: AppColor.kSucces,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le suivi de la carte : une phrase en français (ce qui se passe, ou ce
/// qu'il reste à faire), « Étape 3 sur 6 », puis la frise. Une commande
/// annulée ou refusée n'a pas de parcours : un bandeau rouge le dit.
class _Suivi extends StatelessWidget {
  final CommandeModel commande;
  final bool isVendeur;
  const _Suivi({required this.commande, required this.isVendeur});

  @override
  Widget build(BuildContext context) {
    final statut = commande.statut;
    final message = messageCarteCommande(
      statut,
      isVendeur: isVendeur,
      modePaiement: commande.modePaiement,
    );
    final couleur = couleurStatutCommande(statut);

    if (statut == 'annulee' || statut == 'rejetee') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.kErreurLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, size: 18, color: AppColor.kErreur),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kErreur,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final parcours = etapesEtPosition(commande);
    final position = parcours.index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(iconeStatutCommande(statut), size: 16, color: couleur),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 12.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: couleur,
                ),
              ),
            ),
            if (position >= 0) ...[
              const SizedBox(width: 8),
              Text(
                'Étape ${position + 1} sur ${parcours.etapes.length}',
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
          ],
        ),
        if (position >= 0) ...[
          const SizedBox(height: 14),
          FriseSuiviCommande(
            etapes: parcours.etapes,
            indexCourant: position,
            terminee: statut == 'livree',
            couleur: couleur,
          ),
        ],
      ],
    );
  }
}

enum _EtatEtape { faite, enCours, aVenir }

/// Frise du suivi : toutes les étapes de la commande, numérotées sur une
/// ligne. Les étapes passées sont cochées ; l'étape en cours ressort, plus
/// grande et cerclée, avec son nom juste dessous. Quand le statut change,
/// la pastille et son nom avancent le long de la ligne.
class FriseSuiviCommande extends StatelessWidget {
  /// Statuts du parcours, dans l'ordre (voir [etapesSuiviCommande]).
  final List<String> etapes;

  /// Position du statut actuel dans [etapes].
  final int indexCourant;

  /// Dernière étape atteinte et close (livrée) : tout est coché.
  final bool terminee;
  final Color couleur;

  const FriseSuiviCommande({
    super.key,
    required this.etapes,
    required this.indexCourant,
    required this.couleur,
    this.terminee = false,
  });

  static const _duree = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    final n = etapes.length;
    if (n == 0) return const SizedBox.shrink();
    final courant = indexCourant.clamp(0, n - 1);
    final libelle = kStatutCommandeLabels[etapes[courant]] ?? etapes[courant];

    _EtatEtape etat(int i) {
      if (i < courant || (terminee && i == courant)) return _EtatEtape.faite;
      return i == courant ? _EtatEtape.enCours : _EtatEtape.aVenir;
    }

    return Semantics(
      label: 'Étape ${courant + 1} sur $n : $libelle',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                for (var i = 0; i < n; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: AnimatedContainer(
                        duration: _duree,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= courant ? couleur : AppColor.kGrayscale20,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  _PastilleEtape(
                    numero: i + 1,
                    etat: etat(i),
                    couleur: couleur,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Le nom de l'étape suit sa pastille : à gauche pour la première,
          // à droite pour la dernière, sous la pastille entre les deux.
          AnimatedAlign(
            duration: _duree,
            curve: Curves.easeOutCubic,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * courant / (n - 1), 0),
            child: Text(
              libelle,
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: couleur,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une étape de la frise : cochée (faite), numéro cerclé (en cours) ou
/// numéro gris (à venir).
class _PastilleEtape extends StatelessWidget {
  final int numero;
  final _EtatEtape etat;
  final Color couleur;
  const _PastilleEtape({
    required this.numero,
    required this.etat,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final enCours = etat == _EtatEtape.enCours;
    final aVenir = etat == _EtatEtape.aVenir;
    final cote = enCours ? 28.0 : 22.0;
    return AnimatedContainer(
      duration: FriseSuiviCommande._duree,
      curve: Curves.easeOutCubic,
      width: cote,
      height: cote,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: aVenir ? AppColor.kWhite : couleur,
        shape: BoxShape.circle,
        border: Border.all(
          color: aVenir ? AppColor.kGrayscale20 : couleur,
          width: 1.5,
        ),
        // Halo de l'étape en cours : c'est elle que l'œil doit trouver.
        boxShadow: enCours
            ? [
                BoxShadow(
                  color: couleur.withValues(alpha: 0.18),
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: etat == _EtatEtape.faite
          ? const Icon(Icons.check_rounded, size: 14, color: AppColor.kWhite)
          : Text(
              '$numero',
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: enCours ? 13 : 11.5,
                fontWeight: FontWeight.w800,
                color: aVenir ? AppColor.kGrayscale40 : AppColor.kWhite,
              ),
            ),
    );
  }
}

/// Vignette affichant la photo réelle du produit (pas de boîte carton 3D).
class _VignetteProduit extends StatelessWidget {
  final String? image;
  const _VignetteProduit({this.image});

  @override
  Widget build(BuildContext context) {
    const defaut = ColoredBox(
      color: AppColor.kPrimaryLight,
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 24,
          color: AppColor.kPrimary,
        ),
      ),
    );
    final img = image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 54,
        color: AppColor.kPrimaryLight,
        child: img != null && img.isNotEmpty
            ? ImageReseau(
                img,
                largeurServeur: 160,
                fit: BoxFit.cover,
                repli: defaut,
              )
            : defaut,
      ),
    );
  }
}
