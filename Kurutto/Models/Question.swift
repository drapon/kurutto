import Foundation

struct Question {
    let id = UUID()
    let questionText: String
    let targetAnimal: AnimalType
    let correctAnswer: AnimalType
    let options: [AnimalType]
    let spatialRelation: SpatialRelation
    let difficulty: Difficulty
    
    var relationType: SpatialRelation {
        return spatialRelation
    }
    
    enum Difficulty: Int {
        case easy = 1    // 3歳向け
        case medium = 2  // 4歳向け
        case hard = 3    // 5歳向け
    }
}

enum SpatialRelation: String, CaseIterable {
    case left = "ひだり"
    case right = "みぎ"
    case front = "まえ"
    case back = "うしろ"
    case frontLeft = "ひだりまえ"
    case frontRight = "みぎまえ"
    case backLeft = "ひだりうしろ"
    case backRight = "みぎうしろ"
    
    var isBasic: Bool {
        switch self {
        case .left, .right:
            return true
        case .front, .back:
            return false
        case .frontLeft, .frontRight, .backLeft, .backRight:
            return false
        }
    }
    
    var difficulty: Question.Difficulty {
        switch self {
        case .left, .right:
            return .easy
        case .front, .back:
            return .medium
        case .frontLeft, .frontRight, .backLeft, .backRight:
            return .hard
        }
    }
}

class QuestionGenerator {
    let level: Int
    private var previousQuestions: [Question] = []
    private let maxHistorySize = 5
    
    init(level: Int) {
        self.level = level
    }
    
    func generateQuestion() -> Question {
        let difficulty = getDifficultyForLevel()
        let availableRelations = getAvailableRelations(for: difficulty)
        
        // 動物の配置を決定（円形配置を考慮）
        let animalPositions = arrangeAnimalsInCircle()
        
        // ターゲット動物を選択
        let targetAnimal = selectTargetAnimal(from: animalPositions)
        
        // 空間関係を選択
        let relation = selectRelation(from: availableRelations)
        
        // 正解を計算
        let correctAnswer = calculateCorrectAnswer(
            target: targetAnimal,
            relation: relation,
            positions: animalPositions
        )
        
        // 選択肢を生成（正解を含む4つ）
        let options = generateOptions(
            correctAnswer: correctAnswer,
            allAnimals: Array(animalPositions.keys)
        )
        
        // 問題文を生成
        let questionText = generateQuestionText(
            target: targetAnimal,
            relation: relation,
            difficulty: difficulty
        )
        
        let question = Question(
            questionText: questionText,
            targetAnimal: targetAnimal,
            correctAnswer: correctAnswer,
            options: options,
            spatialRelation: relation,
            difficulty: difficulty
        )
        
        // 履歴に追加
        previousQuestions.append(question)
        if previousQuestions.count > maxHistorySize {
            previousQuestions.removeFirst()
        }
        
        return question
    }
    
    private func getDifficultyForLevel() -> Question.Difficulty {
        switch level {
        case 1: return .easy
        case 2: return .medium
        case 3...: return .hard
        default: return .easy
        }
    }
    
    private func getAvailableRelations(for difficulty: Question.Difficulty) -> [SpatialRelation] {
        switch difficulty {
        case .easy:
            return [.left, .right]
        case .medium:
            return [.left, .right, .front, .back]
        case .hard:
            return SpatialRelation.allCases
        }
    }
    
    private func arrangeAnimalsInCircle() -> [AnimalType: Int] {
        var positions: [AnimalType: Int] = [:]
        let animals = AnimalType.allCases.shuffled()
        
        for (index, animal) in animals.enumerated() {
            positions[animal] = index
        }
        
        return positions
    }
    
    private func selectTargetAnimal(from positions: [AnimalType: Int]) -> AnimalType {
        // 前回の問題で使った動物を避ける
        let recentTargets = previousQuestions.suffix(2).map { $0.targetAnimal }
        let availableAnimals = positions.keys.filter { !recentTargets.contains($0) }
        
        return availableAnimals.randomElement() ?? AnimalType.allCases.randomElement()!
    }
    
    private func selectRelation(from relations: [SpatialRelation]) -> SpatialRelation {
        // 前回と同じ関係を避ける
        let recentRelations = previousQuestions.suffix(2).map { $0.spatialRelation }
        let availableRelations = relations.filter { !recentRelations.contains($0) }
        
        return availableRelations.randomElement() ?? relations.randomElement()!
    }
    
    private func calculateCorrectAnswer(
        target: AnimalType,
        relation: SpatialRelation,
        positions: [AnimalType: Int]
    ) -> AnimalType {
        guard let targetPosition = positions[target] else {
            return AnimalType.allCases.randomElement()!
        }
        
        let totalAnimals = positions.count
        var answerPosition: Int
        
        switch relation {
        case .right:
            answerPosition = (targetPosition + 1) % totalAnimals
        case .left:
            answerPosition = (targetPosition - 1 + totalAnimals) % totalAnimals
        case .front:
            answerPosition = (targetPosition + totalAnimals / 2) % totalAnimals
        case .back:
            answerPosition = targetPosition  // 自分の後ろは自分の位置（円形なので）
        case .frontRight:
            answerPosition = (targetPosition + 2) % totalAnimals
        case .frontLeft:
            answerPosition = (targetPosition - 2 + totalAnimals) % totalAnimals
        case .backRight:
            answerPosition = (targetPosition + totalAnimals - 2) % totalAnimals
        case .backLeft:
            answerPosition = (targetPosition + 2) % totalAnimals
        }
        
        // ポジションから動物を見つける
        for (animal, position) in positions {
            if position == answerPosition {
                return animal
            }
        }
        
        return AnimalType.allCases.randomElement()!
    }
    
    private func generateOptions(
        correctAnswer: AnimalType,
        allAnimals: [AnimalType]
    ) -> [AnimalType] {
        var options = [correctAnswer]
        let otherAnimals = allAnimals.filter { $0 != correctAnswer }.shuffled()
        
        // 残りの3つを追加
        for animal in otherAnimals {
            if options.count >= 4 { break }
            options.append(animal)
        }
        
        // 足りない場合は重複を許可
        while options.count < 4 {
            if let randomAnimal = otherAnimals.randomElement() {
                options.append(randomAnimal)
            }
        }
        
        return options.shuffled()
    }
    
    private func generateQuestionText(
        target: AnimalType,
        relation: SpatialRelation,
        difficulty: Question.Difficulty
    ) -> String {
        switch difficulty {
        case .easy:
            return "\(target.rawValue)の \(relation.rawValue)には\nだれが いるかな？"
        case .medium:
            return "\(target.rawValue)の \(relation.rawValue)を\nみてみよう！\nだれが いるかな？"
        case .hard:
            if relation.rawValue.contains("まえ") || relation.rawValue.contains("うしろ") {
                return "\(target.rawValue)から みて\n\(relation.rawValue)には\nだれが いるかな？"
            } else {
                return "\(target.rawValue)の \(relation.rawValue)には\nだれが いるかな？"
            }
        }
    }
}