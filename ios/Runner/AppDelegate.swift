import Flutter
import GoogleSignIn
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    private let metronomePlugin = MetronomePlugin()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Fallback URL handler for non-Scene-aware call paths (e.g. when the app
    // is launched cold via the REVERSED_CLIENT_ID scheme on older iOS or in
    // certain simulator configurations where UIScene callbacks are skipped).
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        return super.application(app, open: url, options: options)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        // pluginRegistry.registrar(forPlugin:) 是 Flutter embedding 保證存在的 API，
        // 用 messenger() 取得 FlutterBinaryMessenger，比直接存取 binaryMessenger 屬性更安全
        guard let registrar = engineBridge.pluginRegistry
            .registrar(forPlugin: "MetronomePlugin") else { return }
        metronomePlugin.setup(with: registrar.messenger())
    }
}
