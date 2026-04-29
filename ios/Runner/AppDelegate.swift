import Flutter
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

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        // pluginRegistry.registrar(forPlugin:) 是 Flutter embedding 保證存在的 API，
        // 用 messenger() 取得 FlutterBinaryMessenger，比直接存取 binaryMessenger 屬性更安全
        let messenger = engineBridge.pluginRegistry
            .registrar(forPlugin: "MetronomePlugin")
            .messenger()
        metronomePlugin.setup(with: messenger)
    }
}
