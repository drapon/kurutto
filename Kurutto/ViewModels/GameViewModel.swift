import SwiftUI
import SceneKit
import AVFoundation

class GameViewModel: ObservableObject {
    @Published var currentQuestion: Question?
    @Published var currentScore: Int = 0
    @Published var currentLevel: Int = 1
    @Published var soundEnabled: Bool = true
    @Published var highlightedAnswers: Set<AnimalType> = []
    @Published var lastAnswerCorrect: Bool = false
    @Published var sceneManager = SceneManager()
    @Published var showingHint: Bool = false
    @Published var hintCount: Int = 0
    @Published var showingCelebration: Bool = false
    
    private let speechManager = SpeechManager.shared
    private let animationManager = AnimationManager.shared
    private var correctAnswers: Int = 0
    private var totalQuestions: Int = 0
    private var currentStreak: Int = 0
    private var hintTimer: Timer?
    
    var gameScene: SCNScene {
        sceneManager.scene
    }
    
    init() {
        loadUserPreferences()
    }
    
    func startNewGame() {
        currentScore = 0
        currentLevel = 1
        nextQuestion()
    }
    
    func nextQuestion() {
        highlightedAnswers.removeAll()
        hintCount = 0
        showingHint = false
        hintTimer?.invalidate()
        
        let questionGenerator = QuestionGenerator(level: currentLevel)
        currentQuestion = questionGenerator.generateQuestion()
        
        updateSceneWithQuestion()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.speakQuestion()
        }
    }
    
    func checkAnswer(_ answer: AnimalType) {
        guard let question = currentQuestion else { return }
        
        lastAnswerCorrect = answer == question.correctAnswer
        totalQuestions += 1
        
        if lastAnswerCorrect {
            correctAnswers += 1
            currentStreak += 1
            currentScore += calculateScore()
            AudioManager.shared.playSound(.correct)
            HapticManager.success()
            
            // 正解の動物をハイライト
            sceneManager.highlightAnimal(answer)
            
            // 正解時の音声フィードバック
            speechManager.speakCorrectAnswer()
            
            // 正解時のアニメーション
            if let animalNode = sceneManager.scene.rootNode.childNode(withName: answer.rawValue, recursively: true) {
                animalNode.runAction(animationManager.animalCelebrationAnimation())
            }
            
            // セレブレーション表示
            showingCelebration = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.showingCelebration = false
            }
            
            if (currentScore / 500) > currentLevel - 1 {
                currentLevel += 1
                AudioManager.shared.playSound(.levelUp)
            }
            
            // 統計情報を更新
            updateStatistics()
            
            // 次の問題へ
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.nextQuestion()
            }
        } else {
            currentStreak = 0
            AudioManager.shared.playSound(.incorrect)
            HapticManager.error()
            highlightedAnswers.insert(answer)
            
            // 不正解時の音声フィードバック
            speechManager.speakIncorrectAnswer()
            
            // 間違えた動物を一時的にハイライト
            sceneManager.highlightAnimal(answer)
            if let animalNode = sceneManager.scene.rootNode.childNode(withName: answer.rawValue, recursively: true) {
                animalNode.runAction(animationManager.shakeAnimation())
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.sceneManager.removeHighlight(answer)
            }
            
            // ヒントタイマーを開始
            startHintTimer()
        }
    }
    
    func speakQuestion() {
        guard soundEnabled, let question = currentQuestion else { return }
        speechManager.speakQuestion(question.questionText)
    }
    
    func toggleSound() {
        soundEnabled.toggle()
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        
        if !soundEnabled {
            speechManager.stop()
        }
    }
    
    func showHint() {
        guard let question = currentQuestion else { return }
        
        hintCount += 1
        showingHint = true
        
        AudioManager.shared.playSound(.hint)
        
        // 正解の動物にパルスアニメーションを適用
        if let correctNode = sceneManager.scene.rootNode.childNode(withName: question.correctAnswer.rawValue, recursively: true) {
            correctNode.runAction(animationManager.pulseAnimation())
        }
        
        // ヒントメッセージを読み上げ
        let hintMessage = generateHintMessage(for: question)
        speechManager.speakHint(hintMessage)
        
        // ヒント表示後、一定時間でアニメーションを停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.showingHint = false
            if let correctNode = self.sceneManager.scene.rootNode.childNode(withName: question.correctAnswer.rawValue, recursively: true) {
                correctNode.removeAllActions()
            }
        }
    }
    
    private func generateHintMessage(for question: Question) -> String {
        switch question.relationType {
        case .left:
            return "\(question.targetAnimal.displayName)の ひだりがわを みてみよう！"
        case .right:
            return "\(question.targetAnimal.displayName)の みぎがわを みてみよう！"
        case .front:
            return "\(question.targetAnimal.displayName)の まえを みてみよう！"
        case .back:
            return "\(question.targetAnimal.displayName)の うしろを みてみよう！"
        case .frontLeft:
            return "\(question.targetAnimal.displayName)の ひだりまえを みてみよう！"
        case .frontRight:
            return "\(question.targetAnimal.displayName)の みぎまえを みてみよう！"
        case .backLeft:
            return "\(question.targetAnimal.displayName)の ひだりうしろを みてみよう！"
        case .backRight:
            return "\(question.targetAnimal.displayName)の みぎうしろを みてみよう！"
        }
    }
    
    private func startHintTimer() {
        hintTimer?.invalidate()
        
        hintTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            if !self.lastAnswerCorrect && self.highlightedAnswers.count >= 2 {
                self.speechManager.speakEncouragement()
            }
        }
    }
    
    
    private func updateSceneWithQuestion() {
        guard let _ = currentQuestion else { return }
        
        sceneManager.rotateBoard()
        sceneManager.animateAnimals()
        
        // ヒントのためのハイライトをクリア
        for animal in AnimalType.allCases {
            sceneManager.removeHighlight(animal)
        }
    }
    
    private func calculateScore() -> Int {
        var score = 100
        
        if highlightedAnswers.isEmpty {
            score += 30
        }
        
        if hintCount == 0 {
            score += 20
        }
        
        score += currentLevel * 10
        
        score -= hintCount * 10
        
        return max(score, 10)
    }
    
    private func loadUserPreferences() {
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
    }
    
    private func updateStatistics() {
        UserDefaults.standard.set(currentScore, forKey: "lastScore")
        
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        if currentScore > highScore {
            UserDefaults.standard.set(currentScore, forKey: "highScore")
        }
        
        let maxStreak = UserDefaults.standard.integer(forKey: "maxStreak")
        if currentStreak > maxStreak {
            UserDefaults.standard.set(currentStreak, forKey: "maxStreak")
        }
        
        let maxLevel = UserDefaults.standard.integer(forKey: "maxLevel")
        if currentLevel > maxLevel {
            UserDefaults.standard.set(currentLevel, forKey: "maxLevel")
        }
        
        UserDefaults.standard.set(totalQuestions, forKey: "totalQuestions")
        UserDefaults.standard.set(correctAnswers, forKey: "correctAnswers")
    }
}


