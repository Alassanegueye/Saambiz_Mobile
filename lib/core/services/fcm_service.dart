import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/data/repositories/notifications_repository.dart';
import '../../features/abonnement/presentation/pages/mon_abonnement_page.dart';
import '../../features/catalogue/presentation/pages/boutique_publique_page.dart';
import '../../features/commande/data/datasources/commande_remote_datasource.dart';
import '../../features/commande/presentation/pages/commande_detail_page.dart'
    show CommandeDetailArgs;
import '../../features/messagerie/presentation/pages/chat_page.dart';
import '../../features/notifications/presentation/destination_notification.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../routes/app_router.dart';
import '../../injection_container.dart';
import '../connection/auth_interceptor.dart';
import '../utils/app_logger.dart';
import '../../features/certification/certification_page.dart';

// Même mise en place que le projet SIGNS : Firebase Cloud Messaging pour
// l'acheminement, flutter_local_notifications pour l'affichage quand
// l'application est ouverte.

/// Canal Android : le même que le serveur (push.service.js) et que le
/// manifeste (default_notification_channel_id).
const _kCanalId = 'saambiz_push_channel';
const _kCanalNom = 'Boutiques suivies';
const _kCanalDescription =
    'Promotions et nouvelles des boutiques dont vous avez activé la cloche';

final FlutterLocalNotificationsPlugin _notifLocales =
    FlutterLocalNotificationsPlugin();

/// Messages reçus application fermée ou en arrière-plan : le système
/// affiche lui-même la notification. Doit rester une fonction de haut niveau.
@pragma('vm:entry-point')
Future<void> gestionnairePushArrierePlan(RemoteMessage message) async {}

/// Initialise Firebase s'il est configuré (google-services.json /
/// GoogleService-Info.plist présents). Sans configuration, l'application
/// tourne normalement, sans notifications push.
Future<void> initialiserFirebase() async {
  try {
    FirebaseMessaging.onBackgroundMessage(gestionnairePushArrierePlan);
    await Firebase.initializeApp();
  } catch (e) {
    logDebug('Firebase non configuré : notifications push désactivées ($e)');
  }
}

class FcmService {
  static bool _ecouteurs = false;
  static String? _jeton;

  /// La conversation ouverte à l'écran, s'il y en a une.
  ///
  /// Les messages arrivent en push pour atteindre un téléphone rangé dans une
  /// poche. Mais application ouverte, c'est NOUS qui dessinons la bannière
  /// (FCM n'affiche rien dans ce cas) : sans cette information, on affichait
  /// une bannière pour le message que l'utilisateur était en train de lire,
  /// par-dessus la conversation elle-même. Le temps réel l'a déjà posé dans
  /// le fil.
  static String? _conversationOuverte;

  /// Appelé par l'écran de discussion à son ouverture et à sa fermeture.
  static void conversationOuverte(String? interlocuteurId) {
    _conversationOuverte = interlocuteurId;
  }

  /// Faut-il dessiner une bannière pour ce message, application ouverte ?
  ///
  /// Non quand il vient de la conversation déjà sous les yeux : le temps réel
  /// l'a posé dans le fil une fraction de seconde plus tôt, et la bannière ne
  /// ferait que masquer ce qu'elle annonce. Oui pour tout le reste, y compris
  /// un message d'une AUTRE conversation.
  static bool banniereUtile(
    Map<String, dynamic> donnees, {
    String? conversationOuverte,
  }) {
    final de = donnees['interlocuteurId']?.toString();
    if (de == null || de.isEmpty) return true;
    return de != conversationOuverte;
  }

  static bool get _firebasePret => Firebase.apps.isNotEmpty;

  /// À appeler une fois le client ou le vendeur connecté (pages principales).
  /// Demande l'autorisation, enregistre le jeton de l'appareil sur le
  /// serveur, et branche l'affichage et l'ouverture des notifications.
  static Future<void> init() async {
    if (!_firebasePret) return;
    try {
      final messagerie = FirebaseMessaging.instance;
      await _initNotifLocales();

      final reglages = await messagerie.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (reglages.authorizationStatus == AuthorizationStatus.denied) return;

      await _envoyerJeton();

      if (_ecouteurs) return;
      _ecouteurs = true;

      messagerie.onTokenRefresh.listen((_) => _envoyerJeton());

      // Application ouverte : FCM n'affiche rien, on le fait nous-mêmes.
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n == null) return;
        // Sauf pour la conversation déjà sous les yeux : le message vient
        // d'arriver dans le fil par le temps réel, une bannière par-dessus
        // ne ferait que masquer ce qu'elle annonce.
        if (!banniereUtile(
          message.data,
          conversationOuverte: _conversationOuverte,
        )) {
          return;
        }
        _afficher(
          titre: n.title ?? 'SaamBiz',
          texte: n.body ?? '',
          donnees: message.data,
        );
      });

      // Toucher une notification, application en arrière-plan.
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _ouvrir(m.data));

      // Application lancée depuis une notification : le navigateur n'existe
      // qu'après la première image.
      final initial = await messagerie.getInitialMessage();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _ouvrir(initial.data),
        );
      }
    } catch (e) {
      logDebug('Notifications push : initialisation impossible ($e)');
    }
  }

  /// À la déconnexion : ce téléphone ne doit plus recevoir les notifications
  /// du compte qui part.
  static Future<void> desinscrire() async {
    if (!_firebasePret) return;
    try {
      final jeton = _jeton ?? await FirebaseMessaging.instance.getToken();
      if (jeton == null) return;
      await sl<NotificationsRepository>()
          .unregisterDeviceToken(jeton)
          .timeout(const Duration(seconds: 5));
      _jeton = null;
    } catch (_) {
      // Au pire, le serveur rattachera le jeton au prochain compte connecté.
    }
  }

  static Future<void> _envoyerJeton() async {
    try {
      final jeton = await FirebaseMessaging.instance.getToken();
      if (jeton == null) return;
      _jeton = jeton;
      await sl<NotificationsRepository>().registerDeviceToken(
        token: jeton,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (_) {
      // Sans réseau : nouvel essai au prochain lancement.
    }
  }

  static Future<void> _initNotifLocales() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifLocales.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (reponse) {
        final charge = reponse.payload;
        if (charge == null || charge.isEmpty) return;
        try {
          _ouvrir(jsonDecode(charge) as Map<String, dynamic>);
        } catch (_) {}
      },
    );

    if (Platform.isAndroid) {
      await _notifLocales
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _kCanalId,
              _kCanalNom,
              description: _kCanalDescription,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );
    }
  }

  /// Petite icône de la barre d'état : voir le manifeste. Android n'en garde
  /// que le canal alpha, donc le picto sur fond transparent et non l'icône de
  /// lancement, qui est un carré plein et deviendrait un carré blanc.
  static const _kPetiteIcone = '@drawable/ic_launcher_foreground';

  /// Télécharge l'image d'une notification, ou rend `null`.
  ///
  /// Le serveur demande déjà à Cloudinary une version ≤ 1024 px (voir
  /// `imagePourPush` côté API) ; la limite de taille et le délai ci-dessous
  /// ne sont qu'un garde-fou : une notification ne doit jamais faire attendre,
  /// et mieux vaut l'afficher sans image que pas du tout.
  static Future<Uint8List?> _imageDeLaNotification(String? url) async {
    if (url == null || !url.startsWith('https://')) return null;
    try {
      final reponse = await Dio()
          .get<List<int>>(
            url,
            options: Options(responseType: ResponseType.bytes),
          )
          .timeout(const Duration(seconds: 6));
      final octets = reponse.data;
      if (octets == null || octets.isEmpty || octets.length > 1024 * 1024) {
        return null;
      }
      return Uint8List.fromList(octets);
    } catch (e) {
      logDebug('Image de notification non récupérée : $e');
      return null;
    }
  }

  static Future<void> _afficher({
    required String titre,
    required String texte,
    Map<String, dynamic> donnees = const {},
  }) async {
    // Application OUVERTE : c'est nous qui dessinons la notification, et
    // `android.notification.imageUrl` du serveur ne s'applique pas — il n'est
    // honoré que lorsque le système affiche lui-même le message, donc
    // application fermée ou en arrière-plan. Sans ce qui suit, la même
    // notification montrait le logo de la boutique hors de l'application et
    // rien du tout dedans.
    final image = await _imageDeLaNotification(donnees['image']?.toString());

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kCanalId,
        _kCanalNom,
        channelDescription: _kCanalDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: _kPetiteIcone,
        color: const Color(0xFFFBB900),
        styleInformation: image == null
            ? null
            : BigPictureStyleInformation(
                ByteArrayAndroidBitmap(image),
                // Vignette ronde à droite, repliée ; la grande image se
                // découvre quand on déplie la notification.
                largeIcon: ByteArrayAndroidBitmap(image),
                contentTitle: titre,
                summaryText: texte,
                hideExpandedLargeIcon: true,
              ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
    await _notifLocales.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: titre,
      body: texte,
      notificationDetails: details,
      payload: jsonEncode(donnees),
    );
  }

  /// Un toucher ouvre la liste des notifications, où le client retrouve le
  /// message et la boutique.
  /// Toucher la notification, hors de l'application, ouvre l'ecran qu'elle
  /// annonce — la meme regle que dans la liste des notifications, voir
  /// `destinationNotification`.
  ///
  /// Auparavant, toute notification touchee ouvrait la liste : le client
  /// prevenu que sa commande etait prete devait encore la retrouver lui-meme.
  static Future<void> _ouvrir(Map<String, dynamic> donnees) async {
    final navigateur = AuthInterceptor.navigatorKey.currentState;
    if (navigateur == null) return;

    final notification = notificationDepuisPush(donnees);
    final destination = destinationNotification(notification);

    switch (destination.cible) {
      case CibleNotification.commande:
        // La fiche attend la commande entiere ; le push n'en porte que
        // l'identifiant. Si la lecture echoue — reseau coupe au moment du
        // reveil, commande supprimee —, la liste des notifications reste un
        // repli honnete : l'utilisateur voit au moins de quoi il s'agissait.
        try {
          final commande = await sl<CommandeRemoteDataSource>().getCommande(
            destination.id!,
          );
          await navigateur.pushNamed(
            AppRouter.commandeDetailRoute,
            arguments: CommandeDetailArgs(
              commande,
              isVendeur: notification.pourVendeur,
            ),
          );
        } catch (e) {
          logDebug('Commande du push illisible : $e');
          _ouvrirListe(navigateur, notification.pourVendeur);
        }

      case CibleNotification.boutique:
        navigateur.push(
          MaterialPageRoute(
            builder: (_) => BoutiquePubliquePage(boutiqueId: destination.id!),
          ),
        );

      case CibleNotification.abonnement:
        navigateur.push(
          MaterialPageRoute(builder: (_) => const MonAbonnementPage()),
        );

      case CibleNotification.certification:
        // L'écran où le vendeur lit la décision et, s'il a été refusé,
        // renvoie ses photos — ce que la notification lui dit de faire.
        navigateur.push(
          MaterialPageRoute(builder: (_) => const CertificationPage()),
        );

      case CibleNotification.conversation:
        navigateur.push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              interlocuteurId: destination.id!,
              interlocuteurNom: notification.interlocuteurNom.isNotEmpty
                  ? notification.interlocuteurNom
                  : notification.titre,
            ),
          ),
        );

      case CibleNotification.messagerie:
        _ouvrirListe(navigateur, notification.pourVendeur);
    }
  }

  static void _ouvrirListe(NavigatorState navigateur, bool pourVendeur) {
    navigateur.push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(pourVendeur: pourVendeur),
      ),
    );
  }
}
