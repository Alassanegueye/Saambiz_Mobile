import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_color.dart';

/// En-tête unifié des écrans SaamBiz : fond de l'écran, titre et icônes au
/// bleu de la marque, ombre légère seulement au défilement.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool implyLeading;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.bottom,
    this.implyLeading = true,
  });

  @override
  Size get preferredSize {
    double h = kToolbarHeight;
    if (bottom != null) h += bottom!.preferredSize.height;
    return Size.fromHeight(h);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppColor.kPrimary.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColor.kBackground,
      foregroundColor: AppColor.kPrimary,
      iconTheme: const IconThemeData(color: AppColor.kPrimary, size: 22),
      actionsIconTheme: const IconThemeData(color: AppColor.kPrimary, size: 22),
      leading: leading,
      automaticallyImplyLeading: implyLeading,
      titleSpacing: leading != null ? 0 : null,
      title: titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kPrimary,
                  ),
                )),
      actions: actions,
      bottom: bottom,
    );
  }
}
