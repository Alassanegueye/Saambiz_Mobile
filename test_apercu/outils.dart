import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:saambiz/core/routes/app_router.dart';
import 'package:saambiz/core/theme/app_theme.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';

import 'donnees.dart';

/// Dossier des captures produites.
const String dossierCaptures = 'test_apercu/captures';

/// Journal : requêtes sans données prévues et erreurs de rendu par écran.
final StringBuffer journal = StringBuffer();
final List<String> _requetesInconnues = [];

bool _pret = false;

/// Le jeton n'est rendu qu'une fois l'injection faite : la connexion temps
/// réel (socket), qui démarre si un jeton existe à l'ouverture, reste ainsi
/// éteinte pendant les aperçus.
bool _jetonDisponible = false;

/// Canaux des extensions natives : en test, aucune n'est installée. On
/// répond « rien » plutôt que de laisser lever MissingPluginException.
const _canaux = [
  'plugins.it_nomads.com/flutter_secure_storage',
  'plugins.flutter.io/path_provider',
  'flutter.baseflow.com/geolocator',
  'flutter.baseflow.com/geolocator_updates',
  'flutter.baseflow.com/permissions/methods',
  'plugins.flutter.io/url_launcher',
  'plugins.flutter.io/url_launcher_android',
  'plugins.flutter.io/image_picker',
  'plugins.flutter.io/image_picker_android',
  'dev.fluttercommunity.plus/package_info',
];

Future<void> preparer() async {
  if (_pret) return;
  final messager =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in _canaux) {
    messager.setMockMethodCallHandler(MethodChannel(c), (appel) async {
      if (appel.method == 'getTemporaryDirectory' ||
          appel.method == 'getApplicationDocumentsDirectory' ||
          appel.method == 'getApplicationSupportDirectory') {
        return Directory.systemTemp.path;
      }
      if (appel.method == 'readAll') return <String, String>{};
      if (appel.method == 'read' &&
          _jetonDisponible &&
          (appel.arguments as Map?)?['key'] == 'jwt_token') {
        return 'jeton-apercu';
      }
      return null;
    });
  }

  SharedPreferences.setMockInitialValues({
    ...Donnees.preferences,
    'panier_items': Donnees.panier,
  });

  await di.init();
  di.sl<Dio>().httpClientAdapter = AdaptateurApercu();
  _jetonDisponible = true;
  ImageReseau.substitut = (url) => MemoryImage(octetsImage(url));
  await _chargerPolices();
  _pret = true;
}

/// Polices déclarées dans l'application (Plus Jakarta Sans, icônes
/// Material et Cupertino). Sans elles, le moteur de test écrit en carrés.
Future<void> _chargerPolices() async {
  final manifeste =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final famille in manifeste) {
    final chargeur = FontLoader(famille['family'] as String);
    for (final police in famille['fonts'] as List) {
      chargeur.addFont(rootBundle.load(police['asset'] as String));
    }
    await chargeur.load();
  }
}

final Map<String, Uint8List> _images = {};

/// Octets de l'image `apercu:<nom>` (jpg ou png du dossier images).
Uint8List octetsImage(String url) {
  final nom = url.startsWith('apercu:') ? url.substring(7) : 'robe';
  return _images.putIfAbsent(nom, () {
    for (final ext in ['jpg', 'png']) {
      final f = File('test_apercu/images/$nom.$ext');
      if (f.existsSync()) return f.readAsBytesSync();
    }
    return File('test_apercu/images/robe.jpg').readAsBytesSync();
  });
}

/// Répond aux requêtes de l'application avec les données fictives.
class AdaptateurApercu implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final reponse = Donnees.repondre(
      options.method,
      options.path,
      options.queryParameters,
    );
    final entetes = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (reponse == null) {
      _requetesInconnues.add('${options.method} ${options.path}');
      return ResponseBody.fromString(
        '{"message":"absent des aperçus"}',
        404,
        headers: entetes,
      );
    }
    return ResponseBody.fromString(jsonEncode(reponse), 200, headers: entetes);
  }

  @override
  void close({bool force = false}) {}
}

/// Couleur des icônes de la barre d'état, relue sur l'écran affiché.
final ValueNotifier<Brightness> _iconesBarre = ValueNotifier(Brightness.dark);

/// Affiche [ecran] dans un téléphone de 390 × [hauteur] points, attend la
/// fin des chargements, exécute [action] (ouvrir un onglet, faire défiler…)
/// puis enregistre `captures/<nom>.png`.
Future<void> capturer(
  WidgetTester tester,
  String nom,
  Widget ecran, {
  Future<void> Function(WidgetTester tester)? action,
  double hauteur = 844,
  String profil = 'client',
}) async {
  Donnees.profil = profil;
  _requetesInconnues.clear();
  final erreurs = <String>[];
  final gestionnaire = FlutterError.onError;
  FlutterError.onError = (details) {
    final texte = details.exceptionAsString().split('\n').take(2).join(' ');
    if (!erreurs.contains(texte)) erreurs.add(texte);
  };

  tester.view.physicalSize = Size(390 * 3, hauteur * 3);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 28 * 3, bottom: 16 * 3);
  tester.view.viewPadding = const FakeViewPadding(top: 28 * 3, bottom: 16 * 3);

  final cle = GlobalKey();
  try {
    await tester.pumpWidget(
      RepaintBoundary(
        key: cle,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              BlocProvider(
                create: (_) => di.sl<AuthBloc>(),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'SaamBiz',
                  theme: AppTheme.light(),
                  home: ecran,
                  onGenerateRoute: AppRouter.onGenerateRoute,
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 28,
                child: _BarreEtat(),
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 16,
                child: _BarreGestes(),
              ),
            ],
          ),
        ),
      ),
    );
    await _attendre(tester);
    if (action != null) {
      await action(tester);
      await _attendre(tester);
    }
    await _chargerImages(tester);
    final style = SystemChrome.latestStyle;
    _iconesBarre.value =
        style?.statusBarIconBrightness == Brightness.light
            ? Brightness.light
            : Brightness.dark;
    await tester.pump(const Duration(milliseconds: 400));

    await tester.runAsync(() async {
      final rendu =
          cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await rendu.toImage(pixelRatio: 2);
      final octets = await image.toByteData(format: ui.ImageByteFormat.png);
      final fichier = File('$dossierCaptures/$nom.png');
      fichier.parent.createSync(recursive: true);
      fichier.writeAsBytesSync(octets!.buffer.asUint8List());
    });
  } catch (e, pile) {
    erreurs.add('ÉCHEC : $e ${pile.toString().split('\n').take(4).join(' | ')}');
  } finally {
    FlutterError.onError = gestionnaire;
    journal.writeln('■ $nom');
    for (final r in _requetesInconnues.toSet()) {
      journal.writeln('   requête sans données : $r');
    }
    for (final e in erreurs) {
      journal.writeln('   erreur : $e');
    }
    File('$dossierCaptures/journal.txt')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(journal.toString());
    // Démonte l'écran : arrête les minuteurs (comptes à rebours…).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    tester.view.reset();
  }
}

Future<void> _attendre(WidgetTester tester) async {
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Les images se décodent hors de l'horloge simulée du test.
Future<void> _chargerImages(WidgetTester tester) async {
  for (var tour = 0; tour < 2; tour++) {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate().toList()) {
        final image = element.widget as Image;
        try {
          await precacheImage(image.image, element);
        } catch (_) {}
      }
    });
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Fausse barre d'état Android : heure, réseau, batterie.
class _BarreEtat extends StatelessWidget {
  const _BarreEtat();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: _iconesBarre,
      builder: (context, luminosite, _) {
        final couleur = luminosite == Brightness.light
            ? Colors.white
            : const Color(0xFF111111);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              Text(
                '9:41',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: couleur,
                ),
              ),
              const Spacer(),
              Icon(Icons.signal_cellular_alt_rounded, size: 15, color: couleur),
              const SizedBox(width: 4),
              Icon(Icons.wifi_rounded, size: 15, color: couleur),
              const SizedBox(width: 4),
              Icon(Icons.battery_full_rounded, size: 16, color: couleur),
            ],
          ),
        );
      },
    );
  }
}

class _BarreGestes extends StatelessWidget {
  const _BarreGestes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 108,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0x55111111),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
