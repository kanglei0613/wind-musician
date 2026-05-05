import Flutter
import UIKit

/// iOS 節拍器 Platform Channel 橋接
///
/// Channel 名稱與 Android 相同：com.kanglei.muklang/metronome
/// 支援的 method：start / stop / updateBpm / updateTimeSig / setSoundType / setPitchVariant
/// Native → Flutter 事件：透過同一 channel 回呼 "onBeat" method
class MetronomePlugin: NSObject {

    private static let channelName = "com.kanglei.muklang/metronome"
    private var channel: FlutterMethodChannel?
    private let engine = MetronomeEngine()

    // MARK: - 註冊

    static func register(with registrar: FlutterPluginRegistrar) {
        // 此方法由 AppDelegate 手動呼叫（非 FlutterPlugin protocol 自動注冊）
    }

    func setup(with binaryMessenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: MetronomePlugin.channelName,
            binaryMessenger: binaryMessenger
        )

        // Native → Flutter：每拍觸發 onBeat
        engine.onBeat = { [weak self] in
            self?.channel?.invokeMethod("onBeat", arguments: nil)
        }

        // Flutter → Native：接收控制指令
        channel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    // MARK: - MethodCall 處理

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "start":
            guard let args = call.arguments as? [String: Any],
                  let bpm         = args["bpm"]         as? Int,
                  let numerator   = args["numerator"]   as? Int,
                  let denominator = args["denominator"] as? Int
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "start 缺少必要參數", details: nil))
                return
            }
            engine.start(bpm: bpm, numerator: numerator, denominator: denominator)
            result(nil)

        case "stop":
            engine.stop()
            result(nil)

        case "updateBpm":
            guard let args = call.arguments as? [String: Any],
                  let bpm = args["bpm"] as? Int
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "updateBpm 缺少 bpm", details: nil))
                return
            }
            engine.updateBpm(bpm)
            result(nil)

        case "updateTimeSig":
            guard let args = call.arguments as? [String: Any],
                  let numerator   = args["numerator"]   as? Int,
                  let denominator = args["denominator"] as? Int
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "updateTimeSig 缺少參數", details: nil))
                return
            }
            engine.updateTimeSig(numerator: numerator, denominator: denominator)
            result(nil)

        case "setSoundType":
            guard let args = call.arguments as? [String: Any],
                  let soundStr = args["sound"] as? String,
                  let type = SoundType(rawValue: soundStr)
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "setSoundType 音色值無效", details: nil))
                return
            }
            engine.setSoundType(type)
            result(nil)

        case "setPitchVariant":
            guard let args = call.arguments as? [String: Any],
                  let variant = args["variant"] as? Int
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "setPitchVariant 缺少 variant", details: nil))
                return
            }
            engine.setPitchVariant(variant)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
