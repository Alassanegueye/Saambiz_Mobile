import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/police.dart';

/// Ce que le serveur dit d'une liste paginée : où l'on est, et combien il
/// reste. Le même bloc revient dans toutes les réponses de liste.
class Pagination {
  final int page;
  final int pages;
  final int total;

  const Pagination({this.page = 1, this.pages = 1, this.total = 0});

  /// Lue depuis la réponse de l'API. Une réponse sans pagination — un ancien
  /// endpoint, ou une liste courte — donne une page unique : la barre ne
  /// s'affiche alors pas, et rien ne casse.
  factory Pagination.depuis(Map<String, dynamic>? json) {
    int lire(String cle, int defaut) {
      final v = json?[cle];
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? defaut;
    }

    return Pagination(
      page: lire('page', 1),
      pages: lire('pages', 1),
      total: lire('total', 0),
    );
  }

  bool get aPrecedent => page > 1;
  bool get aSuivant => page < pages;

  /// Vrai quand il n'y a qu'une page : inutile d'encombrer l'écran.
  bool get inutile => pages <= 1;
}

/// « Précédent · Page 2 sur 7 · Suivant », sous une liste.
///
/// Les listes de l'application rendaient tout d'un bloc : toutes les
/// commandes, toutes les notifications. Le serveur en rend désormais dix à
/// la fois ; il faut donc de quoi atteindre les suivantes.
///
/// Elle ne s'affiche pas quand il n'y a qu'une page, et un bouton qui ne
/// mène nulle part est grisé plutôt que caché : la place reste stable d'une
/// page à l'autre.
class BarrePagination extends StatelessWidget {
  final Pagination pagination;

  /// Appelés avec la page visée. `null` pendant un chargement : les deux
  /// boutons sont alors inertes, et un second appui ne part pas.
  final ValueChanged<int>? onPage;

  const BarrePagination({
    super.key,
    required this.pagination,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    if (pagination.inutile) return const SizedBox.shrink();
    final p = pagination;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: _Bouton(
              icone: Icons.chevron_left_rounded,
              libelle: 'Précédent',
              // `onPage` nul = chargement en cours.
              onTap: p.aPrecedent && onPage != null
                  ? () => onPage!(p.page - 1)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Page ${p.page} sur ${p.pages}',
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                if (p.total > 0)
                  Text(
                    '${p.total} au total',
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
            child: _Bouton(
              icone: Icons.chevron_right_rounded,
              libelle: 'Suivant',
              aDroite: true,
              onTap: p.aSuivant && onPage != null
                  ? () => onPage!(p.page + 1)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bouton extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final bool aDroite;
  final VoidCallback? onTap;

  const _Bouton({
    required this.icone,
    required this.libelle,
    required this.onTap,
    this.aDroite = false,
  });

  @override
  Widget build(BuildContext context) {
    final actif = onTap != null;
    final contenu = <Widget>[
      Icon(
        icone,
        size: 18,
        color: actif ? AppColor.kPrimary : AppColor.kGrayscale30,
      ),
      Flexible(
        child: Text(
          libelle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: kPolice,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: actif ? AppColor.kPrimary : AppColor.kGrayscale30,
          ),
        ),
      ),
    ];

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide(color: actif ? AppColor.kLine : AppColor.kBackground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: aDroite ? contenu.reversed.toList() : contenu,
      ),
    );
  }
}
