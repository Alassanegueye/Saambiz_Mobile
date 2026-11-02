import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_color.dart';

/// En-tête unifié des écrans SaamBiz : fond ivoire de l'écran, grand titre
/// aligné à gauche, ombre légère seulement au défilement.
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
    this.centerTitle = false,
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
      title:
          titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColor.kPrimary,
                  ),
                )),
      actions: actions,
      bottom: bottom,
    );
  }
}
