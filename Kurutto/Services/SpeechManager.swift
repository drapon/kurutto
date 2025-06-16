import AVFoundation
import SwiftUI

class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    
    // 子供向けの音声設定
    private let voiceIdentifier = "com.apple.ttsbundle.siri_female_ja-JP_premium"
    private let defaultRate: Float = 0.45  // ゆっくりめ
    private let defaultPitch: Float = 1.15  // 少し高め
    private let defaultVolume: Float = 0.9
    
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    func speak(_ text: String, rate: Float? = nil, completion: (() -> Void)? = nil) {
        // 既に話している場合は停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // 日本語の音声を設定
        if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            // フォールバック
            utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        }
        
        // 音声パラメータの設定
        utterance.rate = rate ?? UserDefaults.standard.float(forKey: "voiceSpeed", defaultValue: defaultRate)
        utterance.pitchMultiplier = defaultPitch
        utterance.volume = defaultVolume
        
        // 発話前後の間を設定
        utterance.preUtteranceDelay = 0.2
        utterance.postUtteranceDelay = 0.3
        
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
        
        synthesizer.speak(utterance)
    }
    
    func speakQuestion(_ question: String) {
        // 問題文を読み上げる際の特別な処理
        let modifiedText = question
            .replacingOccurrences(of: "？", with: "?")  // 疑問符を統一
            .replacingOccurrences(of: "！", with: "!")  // 感嘆符を統一
        
        speak(modifiedText, rate: defaultRate - 0.05)  // 問題文は更にゆっくり
    }
    
    func speakEncouragement() {
        let encouragements = [
            "がんばって！",
            "もうすこしだよ！",
            "よく かんがえて みて！",
            "だいじょうぶ、できるよ！",
            "あともう ちょっと！"
        ]
        
        if let message = encouragements.randomElement() {
            speak(message, rate: defaultRate + 0.05)  // 励ましは少し速め
        }
    }
    
    func speakCorrectAnswer() {
        let praises = [
            "せいかい！ すごいね！",
            "やったね！ よくできました！",
            "すばらしい！ そのちょうし！",
            "えらい！ よく わかったね！",
            "パーフェクト！ さすがだね！"
        ]
        
        if let message = praises.randomElement() {
            speak(message, rate: defaultRate + 0.1)  // 褒め言葉は元気よく
        }
    }
    
    func speakIncorrectAnswer() {
        let encouragements = [
            "おしい！ もういちど やってみよう！",
            "ちがったね。でも だいじょうぶ！",
            "あれれ？ もういちど かんがえてみよう！",
            "ざんねん！ でも つぎは できるよ！"
        ]
        
        if let message = encouragements.randomElement() {
            speak(message, rate: defaultRate)
        }
    }
    
    func speakHint(_ hint: String) {
        speak(hint, rate: defaultRate - 0.1)  // ヒントは更にゆっくり
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}

// UserDefaults extension for default values
extension UserDefaults {
    func float(forKey key: String, defaultValue: Float) -> Float {
        if object(forKey: key) != nil {
            return float(forKey: key)
        }
        return defaultValue
    }
}