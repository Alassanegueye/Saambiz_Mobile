import 'package:flutter/material.dart';

/// Corps d'un espace à onglets : un onglet est construit à sa première visite,
/// puis conservé. Y revenir l'affiche aussitôt, avec ses données et sa position
/// de défilement, au lieu de tout recharger.
class OngletsConserves extends StatefulWidget {
  final int index;
  final List<Widget> pages;

  const OngletsConserves({super.key, required this.index, required this.pages});

  /// Faux si la page est dans un onglet masqué. Vrai hors d'un espace à onglets.
  /// Lecture ponctuelle, utilisable dans un minuteur.
  static bool estVisible(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_OngletInfo>()?.visible ?? true;

  @override
  State<OngletsConserves> createState() => _OngletsConservesState();
}

class _OngletsConservesState extends State<OngletsConserves> {
  late final Set<int> _visites = {widget.index};

  @override
  void didUpdateWidget(OngletsConserves ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.index == widget.index) return;
    _visites.add(widget.index);
    // Un champ d'un onglet masqué garderait sinon le clavier ouvert.
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.pages.length; i++)
          if (_visites.contains(i))
            Offstage(
              key: ValueKey(i),
              offstage: i != widget.index,
              child: TickerMode(
                enabled: i == widget.index,
                child: _OngletInfo(
                  visible: i == widget.index,
                  child: widget.pages[i],
                ),
              ),
            ),
      ],
    );
  }
}

class _OngletInfo extends InheritedWidget {
  final bool visible;

  const _OngletInfo({required this.visible, required super.child});

  @override
  bool updateShouldNotify(_OngletInfo ancien) => ancien.visible != visible;
}

/// Pour un `State` : [surRetourOnglet] est appelé quand son onglet redevient
/// visible. C'est là qu'on actualise les données, sans masquer celles affichées.
mixin RetourSurOnglet<T extends StatefulWidget> on State<T> {
  bool? _visible;

  void surRetourOnglet();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible =
        context.dependOnInheritedWidgetOfExactType<_OngletInfo>()?.visible ??
        true;
    if (_visible == false && visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) surRetourOnglet();
      });
    }
    _visible = visible;
  }
}

/// [RetourSurOnglet] pour une page sans `State`, sous son `BlocProvider`.
class ActualiserAuRetour extends StatefulWidget {
  final void Function(BuildContext context) onRetour;
  final Widget child;

  const ActualiserAuRetour({
    super.key,
    required this.onRetour,
    required this.child,
  });

  @override
  State<ActualiserAuRetour> createState() => _ActualiserAuRetourState();
}

class _ActualiserAuRetourState extends State<ActualiserAuRetour>
    with RetourSurOnglet {
  @override
  void surRetourOnglet() => widget.onRetour(context);

  @override
  Widget build(BuildContext context) => widget.child;
}
