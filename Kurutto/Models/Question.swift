import Foundation

struct Question {
    let id = UUID()
    let questionText: String
    let targetAnimal: AnimalType
    let targetPosition: Int // 動物の位置（0-3）
    let correctCardIndex: Int // 正解のカードのインデックス
    let highlightedCardIndex: Int // 点滅するカードのインデックス
    let options: [Int] // カードインデックスの選択肢
    let spatialRelation: SpatialRelation
    let difficulty: Difficulty
    let gridSize: Int // 3x3=9, 4x4=16, 5x5=25
    let ordinalRow: Int? // 前後方向の序数（1,2,3...）
    let ordinalCol: Int? // 左右方向の序数（1,2,3...）
    
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
    
    // グリッド内での位置を表す新しいケース
    case fromFront = "まえから"
    case fromRight = "みぎから"
    case fromLeft = "ひだりから"
    case fromBack = "うしろから"
    
    // 2方向の組み合わせ（グリッド位置特定用）
    case gridPosition = "グリッドの位置"
    
    var isBasic: Bool {
        switch self {
        case .left, .right, .front, .back:
            return true
        case .frontLeft, .frontRight, .backLeft, .backRight:
            return false
        case .fromFront, .fromRight, .fromLeft, .fromBack, .gridPosition:
            return true
        }
    }
    
    var difficulty: Question.Difficulty {
        switch self {
        case .left, .right:
            return .easy
        case .front, .back, .fromFront, .fromRight, .fromLeft, .fromBack, .gridPosition:
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
    let selectedAnimals: [AnimalType] // 4匹のランダムな動物
    let animalPositions: [AnimalType: Int] // 動物の位置マッピング
    
    init(level: Int) {
        self.level = level
        // 6匹から4匹をランダムに選択
        self.selectedAnimals = AnimalType.allCases.shuffled().prefix(4).map { $0 }
        // 位置を割り当て（0: 上, 1: 右, 2: 下, 3: 左）
        var positions: [AnimalType: Int] = [:]
        for (index, animal) in selectedAnimals.enumerated() {
            positions[animal] = index
        }
        self.animalPositions = positions
    }
    
    func generateQuestion() -> Question {
        let difficulty = getDifficultyForLevel()
        let gridSize = getGridSizeForDifficulty(difficulty)
        
        // ターゲット動物を選択
        let targetAnimal = selectTargetAnimal()
        let targetPosition = animalPositions[targetAnimal]!
        
        // グリッド位置を特定する質問を生成
        let relation = SpatialRelation.gridPosition
        
        // 序数を決定（1〜gridSize）
        let ordinalRow = Int.random(in: 1...gridSize)
        let ordinalCol = Int.random(in: 1...gridSize)
        
        // 正解のカードインデックスを計算（2方向の組み合わせ）
        let correctCardIndex = calculateGridPosition(
            targetPosition: targetPosition,
            ordinalRow: ordinalRow,
            ordinalCol: ordinalCol,
            gridSize: gridSize
        )
        
        // 点滅するカードは使わない（グリッド位置特定問題では不要）
        let highlightedCardIndex = -1
        
        // 選択肢を生成（正解を含む4つのカードインデックス）
        let options = generateCardOptions(
            correctAnswer: correctCardIndex,
            gridSize: gridSize,
            highlightedCard: highlightedCardIndex
        )
        
        // 問題文を生成（2方向を組み合わせた質問）
        let questionText = generateGridQuestionText(
            target: targetAnimal,
            ordinalRow: ordinalRow,
            ordinalCol: ordinalCol,
            targetPosition: targetPosition
        )
        
        let question = Question(
            questionText: questionText,
            targetAnimal: targetAnimal,
            targetPosition: targetPosition,
            correctCardIndex: correctCardIndex,
            highlightedCardIndex: highlightedCardIndex,
            options: options,
            spatialRelation: relation,
            difficulty: difficulty,
            gridSize: gridSize,
            ordinalRow: ordinalRow,
            ordinalCol: ordinalCol
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
    
    private func getGridSizeForDifficulty(_ difficulty: Question.Difficulty) -> Int {
        switch difficulty {
        case .easy: return 3    // 3x3 = 9枚
        case .medium: return 4  // 4x4 = 16枚
        case .hard: return 5    // 5x5 = 25枚
        }
    }
    
    private func getAvailableRelations(for difficulty: Question.Difficulty) -> [SpatialRelation] {
        // すべての難易度でグリッド位置特定問題を使用
        return [.gridPosition]
    }
    
    private func selectTargetAnimal() -> AnimalType {
        // 前回の問題で使った動物を避ける
        let recentTargets = previousQuestions.suffix(2).map { $0.targetAnimal }
        let availableAnimals = selectedAnimals.filter { !recentTargets.contains($0) }
        
        return availableAnimals.randomElement() ?? selectedAnimals.randomElement()!
    }
    
    private func selectRelation(from relations: [SpatialRelation]) -> SpatialRelation {
        // 前回と同じ関係を避ける
        let recentRelations = previousQuestions.suffix(2).map { $0.spatialRelation }
        let availableRelations = relations.filter { !recentRelations.contains($0) }
        
        return availableRelations.randomElement() ?? relations.randomElement()!
    }
    
    private func calculateCorrectCardIndex(
        targetPosition: Int,
        highlightedCard: Int,
        relation: SpatialRelation,
        gridSize: Int
    ) -> Int {
        // グリッド内でのカードの行と列を計算
        let cardRow = highlightedCard / gridSize
        let cardCol = highlightedCard % gridSize
        
        // 動物の向きに基づいて相対位置を計算
        // 0: 上, 1: 右, 2: 下, 3: 左
        switch targetPosition {
        case 0: // 上向き（デフォルト）
            return calculateRelativePosition(cardRow: cardRow, cardCol: cardCol, relation: relation, gridSize: gridSize, rotation: 0)
        case 1: // 右向き
            return calculateRelativePosition(cardRow: cardRow, cardCol: cardCol, relation: relation, gridSize: gridSize, rotation: 1)
        case 2: // 下向き
            return calculateRelativePosition(cardRow: cardRow, cardCol: cardCol, relation: relation, gridSize: gridSize, rotation: 2)
        case 3: // 左向き
            return calculateRelativePosition(cardRow: cardRow, cardCol: cardCol, relation: relation, gridSize: gridSize, rotation: 3)
        default:
            return highlightedCard
        }
    }
    
    private func calculateRelativePosition(cardRow: Int, cardCol: Int, relation: SpatialRelation, gridSize: Int, rotation: Int) -> Int {
        var row = cardRow
        var col = cardCol
        
        // 質問タイプに応じて位置を計算
        switch relation {
        case .fromFront:
            // 「前から◯番目」の場合
            let ordinal = Int.random(in: 1...min(3, gridSize))
            return generateOrdinalQuestion(from: "front", ordinal: ordinal, gridSize: gridSize, rotation: rotation)
        case .fromRight:
            // 「右から◯番目」の場合
            let ordinal = Int.random(in: 1...min(3, gridSize))
            return generateOrdinalQuestion(from: "right", ordinal: ordinal, gridSize: gridSize, rotation: rotation)
        case .fromLeft:
            let ordinal = Int.random(in: 1...min(3, gridSize))
            return generateOrdinalQuestion(from: "left", ordinal: ordinal, gridSize: gridSize, rotation: rotation)
        case .fromBack:
            let ordinal = Int.random(in: 1...min(3, gridSize))
            return generateOrdinalQuestion(from: "back", ordinal: ordinal, gridSize: gridSize, rotation: rotation)
        default:
            // 通常の相対位置関係
            switch relation {
            case .right:
                col = (col + 1) % gridSize
            case .left:
                col = (col - 1 + gridSize) % gridSize
            case .front:
                row = (row - 1 + gridSize) % gridSize
            case .back:
                row = (row + 1) % gridSize
            case .frontRight:
                row = (row - 1 + gridSize) % gridSize
                col = (col + 1) % gridSize
            case .frontLeft:
                row = (row - 1 + gridSize) % gridSize
                col = (col - 1 + gridSize) % gridSize
            case .backRight:
                row = (row + 1) % gridSize
                col = (col + 1) % gridSize
            case .backLeft:
                row = (row + 1) % gridSize
                col = (col - 1 + gridSize) % gridSize
            default:
                break
            }
        }
        
        return row * gridSize + col
    }
    
    private func generateOrdinalQuestion(from direction: String, ordinal: Int, gridSize: Int, rotation: Int) -> Int {
        // 動物の回転を考慮して方向を調整
        let adjustedDirection = adjustDirection(direction, rotation: rotation)
        
        // 序数に基づいてカードインデックスを返す
        switch adjustedDirection {
        case "front":
            return (ordinal - 1) * gridSize + Int.random(in: 0..<gridSize)
        case "back":
            return (gridSize - ordinal) * gridSize + Int.random(in: 0..<gridSize)
        case "right":
            return Int.random(in: 0..<gridSize) * gridSize + (gridSize - ordinal)
        case "left":
            return Int.random(in: 0..<gridSize) * gridSize + (ordinal - 1)
        default:
            return 0
        }
    }
    
    private func adjustDirection(_ direction: String, rotation: Int) -> String {
        let directions = ["front", "right", "back", "left"]
        guard let index = directions.firstIndex(of: direction) else { return direction }
        let adjustedIndex = (index + rotation) % 4
        return directions[adjustedIndex]
    }
    
    private func calculateGridPosition(
        targetPosition: Int,
        ordinalRow: Int,
        ordinalCol: Int,
        gridSize: Int
    ) -> Int {
        // 動物の向きに基づいて座標を調整
        var row: Int
        var col: Int
        
        switch targetPosition {
        case 0: // 上向き（デフォルト）
            row = ordinalRow - 1
            col = ordinalCol - 1
        case 1: // 右向き（90度回転）
            row = ordinalCol - 1
            col = gridSize - ordinalRow
        case 2: // 下向き（180度回転）
            row = gridSize - ordinalRow
            col = gridSize - ordinalCol
        case 3: // 左向き（270度回転）
            row = gridSize - ordinalCol
            col = ordinalRow - 1
        default:
            row = ordinalRow - 1
            col = ordinalCol - 1
        }
        
        // 境界チェック
        row = max(0, min(row, gridSize - 1))
        col = max(0, min(col, gridSize - 1))
        
        return row * gridSize + col
    }
    
    private func generateGridQuestionText(
        target: AnimalType,
        ordinalRow: Int,
        ordinalCol: Int,
        targetPosition: Int
    ) -> String {
        let rowText = getOrdinalText(ordinalRow)
        let colText = getOrdinalText(ordinalCol)
        
        // 動物の向きに基づいて方向の表現を調整
        let (frontBackText, leftRightText) = getDirectionTexts(targetPosition: targetPosition)
        
        return "\(target.rawValue)から みて\n\(frontBackText) \(rowText)、\n\(leftRightText) \(colText)の\nカードは どれかな？"
    }
    
    private func getDirectionTexts(targetPosition: Int) -> (String, String) {
        switch targetPosition {
        case 0: // 上向き
            return ("まえから", "ひだりから")
        case 1: // 右向き
            return ("まえから", "みぎから")
        case 2: // 下向き
            return ("うしろから", "みぎから")
        case 3: // 左向き
            return ("うしろから", "ひだりから")
        default:
            return ("まえから", "ひだりから")
        }
    }
    
    private func generateCardOptions(
        correctAnswer: Int,
        gridSize: Int,
        highlightedCard: Int
    ) -> [Int] {
        var options = [correctAnswer]
        let totalCards = gridSize * gridSize
        
        // 点滅カードの周辺から選択肢を生成
        var nearbyCards: [Int] = []
        let row = highlightedCard / gridSize
        let col = highlightedCard % gridSize
        
        // 周囲8方向のカードを候補に
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let newRow = row + dr
                let newCol = col + dc
                if newRow >= 0 && newRow < gridSize && newCol >= 0 && newCol < gridSize {
                    let cardIndex = newRow * gridSize + newCol
                    if cardIndex != correctAnswer {
                        nearbyCards.append(cardIndex)
                    }
                }
            }
        }
        
        // 近隣カードから選択肢を追加
        nearbyCards.shuffle()
        for card in nearbyCards {
            if options.count >= 4 { break }
            if !options.contains(card) {
                options.append(card)
            }
        }
        
        // 足りない場合はランダムに追加
        while options.count < 4 {
            let randomCard = Int.random(in: 0..<totalCards)
            if !options.contains(randomCard) {
                options.append(randomCard)
            }
        }
        
        return options.shuffled()
    }
    
    private func generateQuestionText(
        target: AnimalType,
        relation: SpatialRelation,
        difficulty: Question.Difficulty
    ) -> String {
        switch relation {
        case .fromFront, .fromRight, .fromLeft, .fromBack:
            // 序数質問（「前から◯番目」など）
            let ordinal = Int.random(in: 1...3)
            let ordinalText = getOrdinalText(ordinal)
            return "\(target.rawValue)から みて\n\(relation.rawValue) \(ordinalText)の\nカードは どれかな？"
        case .gridPosition:
            // グリッド位置の質問はgenerateGridQuestionTextで処理される
            return ""
        default:
            // 通常の相対位置質問
            switch difficulty {
            case .easy:
                return "\(target.rawValue)の \(relation.rawValue)の\nカードは どれかな？"
            case .medium:
                return "\(target.rawValue)から みて\n\(relation.rawValue)の カードを\nタップしてね！"
            case .hard:
                return "\(target.rawValue)から みて\n\(relation.rawValue)には\nどのカードが あるかな？"
            }
        }
    }
    
    private func getOrdinalText(_ ordinal: Int) -> String {
        switch ordinal {
        case 1: return "1ばんめ"
        case 2: return "2ばんめ"
        case 3: return "3ばんめ"
        default: return "\(ordinal)ばんめ"
        }
    }
}

// MARK: - AnimalType Definition
enum AnimalType: String, CaseIterable {
    case rabbit = "うさぎ"
    case bear = "くま"
    case elephant = "ぞう"
    case giraffe = "きりん"
    case lion = "らいおん"
    case panda = "ぱんだ"
    
    var displayName: String {
        return rawValue
    }
    
    var imageName: String {
        switch self {
        case .rabbit:
            return "hare.fill"
        case .bear:
            return "pawprint.fill"
        case .elephant:
            return "tortoise.fill"
        case .giraffe:
            return "bird.fill"
        case .lion:
            return "cat.fill"
        case .panda:
            return "leaf.fill"
        }
    }
}