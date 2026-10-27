import Flutter
import UIKit
import GoogleSignIn

// Cycle de vie UIScene (Xcode 27+) : remplace application(_:open:options:)
// de l'ancien AppDelegate pour le callback Google Sign-In.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      if GIDSignIn.sharedInstance.handle(context.url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
