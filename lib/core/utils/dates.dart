/// Formats de date partagés, construits une seule fois.
///
/// `DateFormat('dd/MM/yyyy')` n'est pas un objet anodin : son constructeur
/// analyse le motif et met en place la machinerie de localisation. Il était
/// créé **à l'intérieur des constructeurs d'éléments de liste** — donc une
/// fois par conversation, par signalement, par promotion, et de nouveau à
/// chaque reconstruction pendant le défilement.
///
/// Ces instances-ci sont créées au premier usage et réutilisées ensuite. Un
/// `DateFormat` ne porte aucun état entre deux appels à `format`, le partager
/// est sûr.
library;

import 'package:intl/intl.dart';

/// `12/03/2026`
final DateFormat dateCourte = DateFormat('dd/MM/yyyy');

/// `14:05`
final DateFormat heureCourte = DateFormat('HH:mm');

/// `12/03/2026 14:05`
final DateFormat dateEtHeure = DateFormat('dd/MM/yyyy HH:mm');

/// `2026-03-12` — forme attendue par le backend.
final DateFormat dateIso = DateFormat('yyyy-MM-dd');
