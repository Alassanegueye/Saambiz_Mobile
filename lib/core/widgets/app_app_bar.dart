import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color.dart';
import '../theme/police.dart';

/// En-tete unifie des ecrans SaamBiz : fond transparent ou personnalise,
/// titre marine aligne a gauche, bouton retour simple sans pastille.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool implyLeading;

  /// Fond de l'en-tete ; transparent par defaut pour laisser voir le degrade.
  final Color? couleurFond;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.bottom,
    this.implyLeading = true,
    this.couleurFond,
  });

  @override
  Size get preferredSize {
    double h = kToolbarHeight;
    if (bottom != null) h += bottom!.preferredSize.height;
    return Size.fromHeight(h);
  }

  @override
  Widget build(BuildContext context) {
    final avecRetour =
        leading != null ||
        (implyLeading &&
            (ModalRoute.of(context)?.impliesAppBarDismissal ?? false));
    return AppBar(
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: couleurFond ?? Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      leading: leading,
      automaticallyImplyLeading: implyLeading,
      titleSpacing: avecRetour ? 0 : 16,
      title:
          titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColor.kGrayscaleDark100,
                  ),
                )),
      actions: [...?actions, if (actions != null) const SizedBox(width: 4)],
      bottom: bottom,
    );
  }
}
