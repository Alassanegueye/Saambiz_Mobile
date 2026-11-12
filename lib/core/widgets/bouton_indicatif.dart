import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/police.dart';
import '../utils/telephone.dart';

/// Le pays d'un numéro, posé en tête du champ téléphone : drapeau et
/// indicatif. Un appui ouvre la liste des pays proposés.
///
/// S'utilise comme `prefixIcon` d'un champ de saisie.
class BoutonIndicatif extends StatelessWidget {
  final ValueNotifier<PaysTelephone> pays;

  /// Appelé après un changement (pour revalider le champ, par exemple).
  final VoidCallback? onChange;
  final bool actif;

  const BoutonIndicatif({
    super.key,
    required this.pays,
    this.onChange,
    this.actif = true,
  });

  Future<void> _choisir(BuildContext context) async {
    final choix = await showModalBottomSheet<PaysTelephone>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColor.kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Pays du numéro',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kPrimary,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in paysTelephone)
                    ListTile(
                      leading: Text(
                        p.drapeau,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        p.nom,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${p.indicatif} · ${p.longueur} chiffres',
                        style: const TextStyle(fontFamily: kPolice),
                      ),
                      trailing: p.code == pays.value.code
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColor.kPrimary,
                            )
                          : null,
                      onTap: () => Navigator.of(ctx).pop(p),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (choix != null && choix.code != pays.value.code) {
      pays.value = choix;
      onChange?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaysTelephone>(
      valueListenable: pays,
      builder: (context, p, _) => InkWell(
        onTap: actif ? () => _choisir(context) : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.drapeau, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                p.indicatif,
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColor.kPrimary,
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.only(left: 4),
                color: AppColor.kLine,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
