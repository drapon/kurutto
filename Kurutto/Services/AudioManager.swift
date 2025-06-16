import AVFoundation
import UIKit

class AudioManager {
    static let shared = AudioManager()
    
    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var currentBGMType: BGMType?
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    enum SoundType: String, CaseIterable {
        case tap = "tap"
        case correct = "correct"
        case incorrect = "incorrect"
        case levelUp = "levelup"
        case achievement = "achievement"
        case hint = "hint"
        case rotate = "rotate"
        case jump = "jump"
        
        var volume: Float {
            switch self {
            case .tap: return 0.3
            case .correct: return 0.5
            case .incorrect: return 0.3
            case .levelUp: return 0.6
            case .achievement: return 0.7
            case .hint: return 0.4
            case .rotate: return 0.2
            case .jump: return 0.3
            }
        }
        
        // システムサウンドIDをフォールバックとして使用
        var systemSoundID: SystemSoundID? {
            switch self {
            case .tap: return 1104  // キーボードタップ音
            case .correct: return 1025  // 成功音
            case .incorrect: return 1053  // エラー音（柔らかめ）
            case .hint: return 1003  // 通知音
            default: return nil
            }
        }
    }
    
    enum BGMType: String {
        case menu = "menu_bgm"
        case game = "game_bgm"
        case result = "result_bgm"
    }
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        for soundType in SoundType.allCases {
            loadSound(soundType)
        }
    }
    
    private func loadSound(_ soundType: SoundType) {
        // まずカスタムサウンドファイルを探す
        if let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = soundType.volume
                player.prepareToPlay()
                audioPlayers[soundType] = player
                return
            } catch {
                print("Failed to load sound \(soundType.rawValue): \(error)")
            }
        }
        
        // カスタムサウンドがない場合は、プレースホルダーとして何もしない
        // （システムサウンドは playSound メソッドで直接再生）
    }
    
    func playSound(_ soundType: SoundType) {
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        
        DispatchQueue.main.async {
            // カスタムサウンドがある場合は再生
            if let player = self.audioPlayers[soundType] {
                player.play()
            } else if let systemSoundID = soundType.systemSoundID {
                // フォールバックとしてシステムサウンドを使用
                AudioServicesPlaySystemSound(systemSoundID)
            }
        }
    }
    
    func playBackgroundMusic(_ type: BGMType) {
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        
        // 同じBGMが既に再生中の場合は何もしない
        if currentBGMType == type && backgroundMusicPlayer?.isPlaying == true {
            return
        }
        
        // 既存のBGMを停止
        stopBackgroundMusic()
        
        guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "mp3") else {
            print("Background music file not found: \(type.rawValue)")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1
            backgroundMusicPlayer?.volume = 0.2
            backgroundMusicPlayer?.play()
            currentBGMType = type
        } catch {
            print("Failed to play background music: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        currentBGMType = nil
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func resumeBackgroundMusic() {
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        backgroundMusicPlayer?.play()
    }
}

class HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    static func light() {
        impact(.light)
    }
    
    static func medium() {
        impact(.medium)
    }
    
    static func heavy() {
        impact(.heavy)
    }
    
    static func success() {
        notification(.success)
    }
    
    static func error() {
        notification(.error)
    }
    
    static func warning() {
        notification(.warning)
    }
}