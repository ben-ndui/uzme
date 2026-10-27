import Flutter
import UIKit
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps
    GMSServices.provideAPIKey("AIzaSyDI1EK7Se-iNCB428RtWZ0mhgZ_6jUOMFw")

    // Firebase
    FirebaseApp.configure()

    // Google Sign-In — explicit config required for distribution builds.
    // serverClientID (web client) is required by GIDSignIn 7.x to generate a valid idToken.
    if let clientID = FirebaseApp.app()?.options.clientID {
      let serverClientID = "830017708682-l5976rfnqen0ap7ofmhn6adb7bt6p4j3.apps.googleusercontent.com"
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID, serverClientID: serverClientID)
    }

    // Push Notifications
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Cycle de vie UIScene (Xcode 27+) : l'enregistrement des plugins ne se fait
  // plus dans didFinishLaunchingWithOptions mais ici, une fois le moteur
  // Flutter implicite créé par le FlutterViewController du storyboard.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // Handle APNs token
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
