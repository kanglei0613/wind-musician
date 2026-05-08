import AVFoundation

// MARK: - SoundType

enum SoundType: String {
    case sine       = "SINE"
    case woodblock  = "WOODBLOCK"
    case stickClick = "STICK_CLICK"
    case snare      = "SNARE"
}

// MARK: - MetronomeEngine

/// iOS 節拍器音效引擎
///
/// 使用 AVAudioEngine + AVAudioPlayerNode，以 mach host time 做絕對時間排程。
/// 全程使用同一時間域（hostTime），不混用 sampleTime，確保排程穩定。
class MetronomeEngine {

    // MARK: - 常數

    private let sampleRate: Double = 44100
    private let channelCount: AVAudioChannelCount = 1

    private let pitchFreq1: [Double] = [500, 750, 1000, 1500, 2000]  // SINE / WOODBLOCK
    private let pitchFreq2: [Double] = [375, 500,  750, 1000, 1500]  // STICK_CLICK / SNARE

    // MARK: - 狀態

    private var soundType: SoundType = .sine
    private var pitchVariant: Int = 3
    private var bpm: Int = 120
    private var numerator: Int = 4
    private var denominator: Int = 4
    private var isRunning = false

    // MARK: - AVAudio

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFormat: AVAudioFormat!

    var onBeat: (() -> Void)?

    // MARK: - Mach 時間工具

    /// 將「秒數」轉換為 mach host time 的 tick 差值
    private func secondsToHostTicks(_ seconds: Double) -> UInt64 {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        let nanos = seconds * 1_000_000_000.0
        return UInt64(nanos * Double(info.denom) / Double(info.numer))
    }

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

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[MetronomeEngine] AVAudioSession error: \(error)")
        }
    }

    // MARK: - 公開控制

    func start(bpm: Int, numerator: Int, denominator: Int) {
        self.bpm = bpm
        self.numerator = numerator
        self.denominator = denominator
        guard !isRunning else { return }
        isRunning = true

        do {
            try engine.start()
        } catch {
            print("[MetronomeEngine] engine.start() error: \(error)")
            isRunning = false
            return
        }
        playerNode.play()

        // 第一拍：50ms 後播放（讓引擎穩定，同時保持即時感）
        let lookahead = secondsToHostTicks(0.05)
        let firstBeatHostTime = mach_absolute_time() + lookahead
        scheduleNextBeat(at: firstBeatHostTime)
    }

    func stop() {
        isRunning = false
        playerNode.stop()
        if engine.isRunning { engine.stop() }
    }

    func updateBpm(_ newBpm: Int) {
        bpm = newBpm
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

    // MARK: - 排程（全程 hostTime 域）

    private func scheduleNextBeat(at beatHostTime: UInt64) {
        guard isRunning else { return }

        let intervalSec = (60.0 / Double(bpm)) * (4.0 / Double(denominator))
        let beatDurSec  = min(intervalSec * 0.85, 0.12)
        let beatFrames  = AVAudioFrameCount(beatDurSec * sampleRate)

        let beatTime = AVAudioTime(hostTime: beatHostTime)
        let buffer   = synthesize(frames: beatFrames)

        // 計算下一拍的 hostTime（在排程時預先計算，避免 completion 延遲影響精度）
        let nextBeatHostTime = beatHostTime + secondsToHostTicks(intervalSec)

        playerNode.scheduleBuffer(buffer, at: beatTime, options: []) { [weak self] in
            guard let self = self, self.isRunning else { return }
            DispatchQueue.main.async { self.onBeat?() }
            self.scheduleNextBeat(at: nextBeatHostTime)
        }
    }

    // MARK: - PCM 合成

    private func synthesize(frames: AVAudioFrameCount) -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frames)!
        buffer.frameLength = frames
        let data = buffer.floatChannelData![0]
        switch soundType {
        case .sine:       synthesizeSine(data: data, frames: frames)
        case .woodblock:  synthesizeWoodblock(data: data, frames: frames)
        case .stickClick: synthesizeStickClick(data: data, frames: frames)
        case .snare:      synthesizeSnare(data: data, frames: frames)
        }
        return buffer
    }

    private func synthesizeSine(data: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        let freq = baseFreq(useFreq2: false)
        let decay = 0.03 * sampleRate
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let env = Float(exp(-Double(i) / decay))
            data[i] = Float(sin(2.0 * .pi * freq * t)) * env * 1.0
        }
    }

    private func synthesizeWoodblock(data: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        let freq = baseFreq(useFreq2: false)
        let decay = 0.02 * sampleRate
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let env = Float(exp(-Double(i) / decay))
            let v = Float(sin(2.0 * .pi * freq * t))
                  + Float(sin(2.0 * .pi * freq * 2.76 * t)) * 0.4
                  + Float(sin(2.0 * .pi * freq * 5.40 * t)) * 0.15
            data[i] = v * env * 1.0
        }
    }

    private func synthesizeStickClick(data: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        let freq = baseFreq(useFreq2: true)
        let decay = 0.008 * sampleRate
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let env = Float(exp(-Double(i) / decay))
            let v = Float(sin(2.0 * .pi * freq * t))
                  + Float(sin(2.0 * .pi * freq * 3.0 * t)) * 0.5
            data[i] = v * env * 1.0
        }
    }

    private func synthesizeSnare(data: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        let freq = baseFreq(useFreq2: true)
        let decay = 0.04 * sampleRate
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let env = Float(exp(-Double(i) / decay))
            let body  = Float(sin(2.0 * .pi * freq * t)) * 0.5
            let noise = Float.random(in: -1...1) * 0.5
            data[i] = (body + noise) * env * 1.0
        }
    }

    private func baseFreq(useFreq2: Bool) -> Double {
        let idx = max(0, min(4, pitchVariant - 1))
        return useFreq2 ? pitchFreq2[idx] : pitchFreq1[idx]
    }
}
