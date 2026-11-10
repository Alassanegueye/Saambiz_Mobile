import Flutter
import UIKit
import UserNotifications
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Notifications push : Firebase ne démarre que si GoogleService-Info.plist
    // est dans l'application (console Firebase → app iOS « com.saambiz.app »).
    // Sans ce garde, FirebaseApp.configure() plante l'application au lancement.
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      FirebaseApp.configure()
    } else {
      NSLog("GoogleService-Info.plist introuvable : notifications push désactivées sur iOS.")
    }
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
