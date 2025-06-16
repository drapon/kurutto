import SwiftUI
import SceneKit
import AVFoundation

class GameViewModel: ObservableObject {
    @Published var currentQuestion: Question?
    @Published var currentScore: Int = 0
    @Published var currentLevel: Int = 1
    @Published var soundEnabled: Bool = true
    @Published var highlightedCards: Set<Int> = []
    @Published var lastAnswerCorrect: Bool = false
    @Published var sceneManager = SceneManager()
    @Published var showingHint: Bool = false
    @Published var hintCount: Int = 0
    @Published var showingCelebration: Bool = false
    @Published var questionGenerator: QuestionGenerator?
    @Published var currentAnimalView: AnimalType?
    
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
        setupQuestionGenerator()
    }
    
    func setupQuestionGenerator() {
        questionGenerator = QuestionGenerator(level: currentLevel)
        // SceneManagerに選択された動物を設定
        if let selectedAnimals = questionGenerator?.selectedAnimals {
            sceneManager.setSelectedAnimals(selectedAnimals)
        }
    }
    
    func startNewGame() {
        currentScore = 0
        currentLevel = 1
        setupQuestionGenerator()
        updateSceneForDifficulty()
        nextQuestion()
    }
    
    func updateSceneForDifficulty() {
        let gridSize = getGridSizeForLevel()
        sceneManager.updateForDifficulty(gridSize: gridSize)
    }
    
    func getGridSizeForLevel() -> Int {
        switch currentLevel {
        case 1: return 3    // 3x3 = 9枚
        case 2: return 4    // 4x4 = 16枚
        default: return 5   // 5x5 = 25枚
        }
    }
    
    func nextQuestion() {
        highlightedCards.removeAll()
        hintCount = 0
        showingHint = false
        hintTimer?.invalidate()
        currentAnimalView = nil
        sceneManager.resetCameraView()
        
        // 新しい問題を生成
        currentQuestion = questionGenerator?.generateQuestion()
        
        updateSceneWithQuestion()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.speakQuestion()
        }
    }
    
    func checkCardAnswer(_ cardIndex: Int) {
        guard let question = currentQuestion else { return }
        
        lastAnswerCorrect = cardIndex == question.correctCardIndex
        totalQuestions += 1
        
        if lastAnswerCorrect {
            correctAnswers += 1
            currentStreak += 1
            currentScore += calculateScore()
            AudioManager.shared.playSound(.correct)
            HapticManager.success()
            
            // 正解のカードをハイライト
            highlightCard(cardIndex)
            
            // 正解時の音声フィードバック
            speechManager.speakCorrectAnswer()
            
            // セレブレーション表示
            showingCelebration = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.showingCelebration = false
            }
            
            // レベルアップチェック
            if shouldLevelUp() {
                currentLevel += 1
                AudioManager.shared.playSound(.levelUp)
                setupQuestionGenerator()
                updateSceneForDifficulty()
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
            highlightedCards.insert(cardIndex)
            
            // 不正解時の音声フィードバック
            speechManager.speakIncorrectAnswer()
            
            // ヒントタイマーを開始
            startHintTimer()
        }
    }
    
    func shouldLevelUp() -> Bool {
        // 5問連続正解でレベルアップ
        return currentStreak >= 5 && currentLevel < 3
    }
    
    func highlightCard(_ index: Int) {
        sceneManager.highlightCard(at: index)
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
        
        // 正解のカードを点滅させる
        sceneManager.highlightCard(at: question.correctCardIndex)
        
        // ヒントメッセージを読み上げ
        let hintMessage = generateHintMessage(for: question)
        speechManager.speakHint(hintMessage)
        
        // ヒント表示後、一定時間でアニメーションを停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.showingHint = false
        }
    }
    
    private func generateHintMessage(for question: Question) -> String {
        switch question.spatialRelation {
        case .fromFront, .fromRight, .fromLeft, .fromBack:
            return "ひかっている カードから かぞえてみよう！"
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
        case .gridPosition:
            return "\(question.targetAnimal.displayName)の いちから かぞえてみよう！"
        }
    }
    
    private func startHintTimer() {
        hintTimer?.invalidate()
        
        hintTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            if !self.lastAnswerCorrect && self.highlightedCards.count >= 2 {
                self.speechManager.speakEncouragement()
            }
        }
    }
    
    private func updateSceneWithQuestion() {
        guard let question = currentQuestion else { return }
        
        // グリッド位置特定問題では点滅カードを使用しない
        if question.spatialRelation != .gridPosition && question.highlightedCardIndex >= 0 {
            sceneManager.highlightCard(at: question.highlightedCardIndex)
        }
        
        // ターゲット動物をハイライト
        sceneManager.highlightAnimal(question.targetAnimal)
        
        // ボードを回転（視覚的な興味を引くため）
        sceneManager.rotateBoard()
    }
    
    func switchToAnimalView(_ animal: AnimalType) {
        currentAnimalView = animal
        sceneManager.switchToAnimalView(animal: animal)
    }
    
    func resetToDefaultView() {
        currentAnimalView = nil
        sceneManager.resetCameraView()
    }
    
    // スワイプジェスチャーハンドラー
    func handleSwipe(direction: SwipeDirection) {
        guard let selectedAnimals = questionGenerator?.selectedAnimals else { return }
        
        switch direction {
        case .up:
            if let topAnimal = selectedAnimals.first(where: { questionGenerator?.animalPositions[$0] == 0 }) {
                switchToAnimalView(topAnimal)
            }
        case .right:
            if let rightAnimal = selectedAnimals.first(where: { questionGenerator?.animalPositions[$0] == 1 }) {
                switchToAnimalView(rightAnimal)
            }
        case .down:
            if let bottomAnimal = selectedAnimals.first(where: { questionGenerator?.animalPositions[$0] == 2 }) {
                switchToAnimalView(bottomAnimal)
            }
        case .left:
            if let leftAnimal = selectedAnimals.first(where: { questionGenerator?.animalPositions[$0] == 3 }) {
                switchToAnimalView(leftAnimal)
            }
        }
    }
    
    private func calculateScore() -> Int {
        var score = 100
        
        if highlightedCards.isEmpty {
            score += 30  // ノーミスボーナス
        }
        
        if hintCount == 0 {
            score += 20  // ノーヒントボーナス
        }
        
        score += currentLevel * 10  // レベルボーナス
        
        score -= hintCount * 10  // ヒントペナルティ
        
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

enum SwipeDirection {
    case up, down, left, right
}