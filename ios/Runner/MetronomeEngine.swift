import AVFoundation

// MARK: - SoundType

/// 對應 Android MetronomeEngine 的 SoundType enum
enum SoundType: String {
    case sine       = "SINE"
    case woodblock  = "WOODBLOCK"
    case stickClick = "STICK_CLICK"
    case snare      = "SNARE"
}

// MARK: - MetronomeEngine

/// iOS 節拍器音效引擎
///
/// 使用 AVAudioEngine + AVAudioPlayerNode 播放即時合成的 PCM 音效。
/// 支援 4 種音色 × 5 種音高變體，與 Android MetronomeEngine.kt 完全對應。
/// 排程策略：AVAudioPlayerNode.scheduleBuffer(at:) 使用 AVAudioTime 絕對時間，
/// 避免 Dart Timer 累積漂移，背景播放穩定。
class MetronomeEngine {

    // MARK: - 常數

    private let sampleRate: Double = 44100
    private let channelCount: AVAudioChannelCount = 1

    /// 5 種音高對應的基頻（Hz），soundType=SINE/WOODBLOCK 用 freq1，STICK_CLICK/SNARE 用 freq2
    /// 對應 Android：pitchVariant 1(最低) → 5(最高)
    private let pitchFreq1: [Double] = [500, 750, 1000, 1500, 2000]
    private let pitchFreq2: [Double] = [375, 500, 750, 1000, 1500]

    // MARK: - 狀態

    private var soundType: SoundType = .sine
    private var pitchVariant: Int = 3  // 1~5，預設 3（中音）
    private var bpm: Int = 120
    private var numerator: Int = 4
    private var denominator: Int = 4

    private var isRunning = false
    private var beatIndex: Int = 0

    // MARK: - AVAudio

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFormat: AVAudioFormat!

    /// 每次打拍後回呼（Flutter 側訂閱用）
    var onBeat: (() -> Void)?

    // MARK: - 初始化

    init() {
        audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channelCount
        )!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)
        setupAudioSession()
    }

    // MARK: - AVAudioSession

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // playback category：允許靜音模式下播放，並支援背景音訊
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[MetronomeEngine] AVAudioSession setup error: \(error)")
        }
    }

    // MARK: - 公開控制

    func start(bpm: Int, numerator: Int, denominator: Int) {
        self.bpm = bpm
        self.numerator = numerator
        self.denominator = denominator
        beatIndex = 0

        guard !isRunning else { return }
        isRunning = true

        do {
            try engine.start()
        } catch {
            print("[MetronomeEngine] AVAudioEngine start error: \(error)")
            isRunning = false
            return
        }

        playerNode.play()
        scheduleNextBeat(at: nil)
    }

    func stop() {
        isRunning = false
        playerNode.stop()
        if engine.isRunning {
            engine.stop()
        }
    }

    func updateBpm(_ newBpm: Int) {
        bpm = newBpm
        // 下一拍排程時自動套用新 BPM，無需重啟
    }

    func updateTimeSig(numerator: Int, denominator: Int) {
        self.numerator = numerator
        self.denominator = denominator
    }

    func setSoundType(_ type: SoundType) {
        soundType = type
    }

    func setPitchVariant(_ variant: Int) {
        pitchVariant = max(1, min(5, variant))
    }

    // MARK: - 排程

    /// 遞迴排程：每拍結束前已排好下一拍的 buffer，避免空隙
    private func scheduleNextBeat(at lastBeatTime: AVAudioTime?) {
        guard isRunning else { return }

        let intervalSec = (60.0 / Double(bpm)) * (4.0 / Double(denominator))
        let sampleFrames = AVAudioFrameCount(intervalSec * sampleRate)
        let beatFrames   = AVAudioFrameCount(min(intervalSec * 0.85, 0.12) * sampleRate)  // 音效長度不超過 85% 的間隔

        // 計算本拍的絕對播放時間
        let beatTime: AVAudioTime
        if let last = lastBeatTime {
            // 從上一拍時間往後推一個 interval
            let nextSample = last.sampleTime + AVAudioFramePosition(sampleFrames)
            beatTime = AVAudioTime(sampleTime: nextSample, atRate: sampleRate)
        } else {
            // 第一拍：立即播放
            let hostTime = mach_absolute_time()
            beatTime = AVAudioTime(hostTime: hostTime)
        }

        // 合成音效 PCM buffer
        let buffer = synthesize(frames: beatFrames)

        let currentBeatIndex = beatIndex
        beatIndex += 1

        // 排程播放，completion 裡遞迴排程下一拍
        playerNode.scheduleBuffer(buffer, at: beatTime, options: []) { [weak self] in
            guard let self = self, self.isRunning else { return }

            // 通知 Flutter
            DispatchQueue.main.async {
                self.onBeat?()
            }

            // 遞迴排程下一拍
            self.scheduleNextBeat(at: beatTime)
        }
    }

    // MARK: - PCM 合成

    private func synthesize(frames: AVAudioFrameCount) -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frames)!
        buffer.frameLength = frames
        let data = buffer.floatChannelData![0]

        switch soundType {
        case .sine:
            synthesizeSine(data: data, frames: frames)
        case .woodblock:
            synthesizeWoodblock(data: data, frames: frames)
        case .stickClick:
            synthesizeStickClick(data: data, frames: frames)
        case .snare:
            synthesizeSnare(data: data, frames: frames)
        }

        return buffer
    }

    /// 正弦波（使用 pitchFreq1）
    private func synthesizeSine(data: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        let freq = baseFreq(useFreq2: false)
        let decayFrames = min(Int(frames), Int(0.08 * sampleRate))
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let env = i < decayFrames ? Float(exp(-Double(i) / (0.03 * sampleRate))) : 0
            data[i] = Float(sin(2.0 * .pi * freq * t)) * env * 0.8
        }
    }

    /// 木魚：短促正弦衰減 + 高次諧波（使用 pitchFreq1）
    private func synthesizeWoodblock(data: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        let freq = baseFreq(useFreq2: false)
        let decayFrames = min(Int(frames), Int(0.06 * sampleRate))
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let env = i < decayFrames ? Float(exp(-Double(i) / (0.02 * sampleRate))) : 0
            let v = Float(sin(2.0 * .pi * freq * t))
                  + Float(sin(2.0 * .pi * freq * 2.76 * t)) * 0.4
                  + Float(sin(2.0 * .pi * freq * 5.40 * t)) * 0.15
            data[i] = v * env * 0.7
        }
    }

    /// 擊板 (Stick Click)：短脈衝 + 高頻點擊感（使用 pitchFreq2）
    private func synthesizeStickClick(data: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        let freq = baseFreq(useFreq2: true)
        let decayFrames = min(Int(frames), Int(0.04 * sampleRate))
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let env = i < decayFrames ? Float(exp(-Double(i) / (0.008 * sampleRate))) : 0
            let v = Float(sin(2.0 * .pi * freq * t))
                  + Float(sin(2.0 * .pi * freq * 3.0 * t)) * 0.5
            data[i] = v * env * 0.9
        }
    }

    /// 小鼓：雜訊 + 正弦 body（使用 pitchFreq2）
    private func synthesizeSnare(data: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        let freq = baseFreq(useFreq2: true)
        let decayFrames = min(Int(frames), Int(0.10 * sampleRate))
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let env = i < decayFrames ? Float(exp(-Double(i) / (0.04 * sampleRate))) : 0
            let body  = Float(sin(2.0 * .pi * freq * t)) * 0.5
            let noise = Float.random(in: -1...1) * 0.5
            data[i] = (body + noise) * env * 0.75
        }
    }

    /// 根據 soundType 與 pitchVariant 取得基頻
    private func baseFreq(useFreq2: Bool) -> Double {
        let idx = max(0, min(4, pitchVariant - 1))
        return useFreq2 ? pitchFreq2[idx] : pitchFreq1[idx]
    }
}
