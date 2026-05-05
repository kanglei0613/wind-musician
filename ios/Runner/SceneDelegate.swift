import Flutter
import GoogleSignIn
import UIKit

class SceneDelegate: FlutterSceneDelegate {

    // Required for Google Sign In: the OAuth flow redirects back to the app via
    // the REVERSED_CLIENT_ID URL scheme. Without this override the redirect is
    // never forwarded to GIDSignIn and the sign-in silently fails / crashes.
    override func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        // Always forward to super first so FlutterSceneDelegate can process
        // any Flutter-level deep links (e.g. platform channel callbacks).
        super.scene(scene, openURLContexts: URLContexts)

        guard let url = URLContexts.first?.url else { return }
        // Forward the OAuth redirect URL to GoogleSignIn so it can complete
        // the sign-in flow when Safari/ASWebAuthenticationSession returns.
        // GIDSignIn 8.x: handleURL(_:) is the Swift name for handleURL: (ObjC).
        GIDSignIn.sharedInstance.handle(url)
    }
}
