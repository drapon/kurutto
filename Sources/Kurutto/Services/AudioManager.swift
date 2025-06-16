import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    
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
        
        var volume: Float {
            switch self {
            case .tap: return 0.3
            case .correct: return 0.5
            case .incorrect: return 0.3
            case .levelUp: return 0.6
            case .achievement: return 0.7
            }
        }
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
        guard let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "mp3") else {
            print("Sound file not found: \(soundType.rawValue)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = soundType.volume
            player.prepareToPlay()
            audioPlayers[soundType] = player
        } catch {
            print("Failed to load sound \(soundType.rawValue): \(error)")
        }
    }
    
    func playSound(_ soundType: SoundType) {
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        
        DispatchQueue.main.async {
            self.audioPlayers[soundType]?.play()
        }
    }
    
    func playBackgroundMusic() {
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        
        guard let url = Bundle.main.url(forResource: "background", withExtension: "mp3") else {
            print("Background music file not found")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1
            backgroundMusicPlayer?.volume = 0.2
            backgroundMusicPlayer?.play()
        } catch {
            print("Failed to play background music: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
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