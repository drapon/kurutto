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
    
    let gameScene = SCNScene()
    private var boardNode: SCNNode?
    private var animalNodes: [AnimalType: SCNNode] = [:]
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        setupScene()
        loadUserPreferences()
    }
    
    func startNewGame() {
        currentScore = 0
        currentLevel = 1
        nextQuestion()
    }
    
    func nextQuestion() {
        highlightedAnswers.removeAll()
        
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
        
        if lastAnswerCorrect {
            currentScore += calculateScore()
            AudioManager.shared.playSound(.correct)
            
            if (currentScore / 500) > currentLevel - 1 {
                currentLevel += 1
            }
        } else {
            AudioManager.shared.playSound(.incorrect)
            highlightedAnswers.insert(answer)
        }
    }
    
    func speakQuestion() {
        guard soundEnabled, let question = currentQuestion else { return }
        
        let utterance = AVSpeechUtterance(string: question.questionText)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = UserDefaults.standard.float(forKey: "voiceSpeed")
        utterance.pitchMultiplier = 1.1
        utterance.volume = 0.9
        
        speechSynthesizer.speak(utterance)
    }
    
    func toggleSound() {
        soundEnabled.toggle()
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        
        if !soundEnabled {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    private func setupScene() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 5, 10)
        cameraNode.look(at: SCNVector3(0, 0, 0), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        gameScene.rootNode.addChildNode(cameraNode)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.light?.intensity = 1000
        lightNode.position = SCNVector3(0, 10, 10)
        gameScene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 500
        gameScene.rootNode.addChildNode(ambientLightNode)
        
        createBoard()
    }
    
    private func createBoard() {
        let boardGeometry = SCNCylinder(radius: 5, height: 0.5)
        boardGeometry.firstMaterial?.diffuse.contents = UIColor(named: "BoardColor") ?? UIColor.systemGray5
        
        boardNode = SCNNode(geometry: boardGeometry)
        boardNode?.position = SCNVector3(0, 0, 0)
        
        if let boardNode = boardNode {
            gameScene.rootNode.addChildNode(boardNode)
        }
        
        createAnimalPositions()
    }
    
    private func createAnimalPositions() {
        let positions: [(x: Float, z: Float)] = [
            (0, -3),      // 前
            (3, 0),       // 右
            (0, 3),       // 後
            (-3, 0),      // 左
            (0, 0),       // 中央
            (0, -1.5)     // 前寄り中央
        ]
        
        for (index, animal) in AnimalType.allCases.enumerated() {
            if index < positions.count {
                let position = positions[index]
                let animalNode = createAnimalNode(for: animal)
                animalNode.position = SCNVector3(position.x, 0.5, position.z)
                animalNodes[animal] = animalNode
                boardNode?.addChildNode(animalNode)
            }
        }
    }
    
    private func createAnimalNode(for animal: AnimalType) -> SCNNode {
        let geometry = SCNBox(width: 1.5, height: 1.5, length: 1.5, chamferRadius: 0.3)
        
        let material = SCNMaterial()
        material.diffuse.contents = getAnimalColor(for: animal)
        geometry.materials = [material]
        
        let node = SCNNode(geometry: geometry)
        node.name = animal.rawValue
        
        let textGeometry = SCNText(string: animal.rawValue, extrusionDepth: 0.1)
        textGeometry.font = UIFont.systemFont(ofSize: 0.5, weight: .bold)
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(-0.5, 0.8, 0.8)
        node.addChildNode(textNode)
        
        return node
    }
    
    private func getAnimalColor(for animal: AnimalType) -> UIColor {
        switch animal {
        case .rabbit: return UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0)
        case .bear: return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .elephant: return UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        case .giraffe: return UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        case .lion: return UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        case .panda: return UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        }
    }
    
    private func updateSceneWithQuestion() {
        guard let _ = currentQuestion else { return }
        
        let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 3)
        boardNode?.runAction(rotateAction)
        
        for (_, node) in animalNodes {
            let jumpAction = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 0.2),
                SCNAction.moveBy(x: 0, y: -0.5, z: 0, duration: 0.2)
            ])
            node.runAction(jumpAction)
        }
    }
    
    private func calculateScore() -> Int {
        var score = 100
        
        if highlightedAnswers.isEmpty {
            score += 30
        }
        
        score += currentLevel * 10
        
        return score
    }
    
    private func loadUserPreferences() {
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
    }
}

struct Question {
    let questionText: String
    let targetAnimal: AnimalType
    let correctAnswer: AnimalType
    let options: [AnimalType]
    let spatialRelation: SpatialRelation
}

enum SpatialRelation: String {
    case left = "ひだり"
    case right = "みぎ"
    case front = "まえ"
    case back = "うしろ"
    case above = "うえ"
    case below = "した"
}

class QuestionGenerator {
    let level: Int
    
    init(level: Int) {
        self.level = level
    }
    
    func generateQuestion() -> Question {
        let animals = AnimalType.allCases.shuffled()
        let targetAnimal = animals[0]
        let correctAnswer = animals[1]
        let options = Array(animals.prefix(4))
        
        let relations: [SpatialRelation] = level == 1 ? [.left, .right] :
                                          level == 2 ? [.left, .right, .front, .back] :
                                          [.left, .right, .front, .back, .above, .below]
        
        let relation = relations.randomElement() ?? .left
        
        let questionText = "\(targetAnimal.rawValue)の \(relation.rawValue)には\nだれが いるかな？"
        
        return Question(
            questionText: questionText,
            targetAnimal: targetAnimal,
            correctAnswer: correctAnswer,
            options: options,
            spatialRelation: relation
        )
    }
}