import XCTest
@testable import Kurutto

class QuestionTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Question Generation Tests
    
    func testQuestionTextGeneration() throws {
        let question = Question(
            questionText: "うさぎの みぎには だれがいる？",
            targetAnimal: .rabbit,
            targetPosition: 0,
            correctCardIndex: 1,
            highlightedCardIndex: 0,
            options: [1, 2, 3, 4],
            spatialRelation: .right,
            difficulty: .easy,
            gridSize: 3
        )
        
        XCTAssertEqual(question.questionText, "うさぎの みぎには だれがいる？")
        XCTAssertEqual(question.targetAnimal, .rabbit)
        XCTAssertEqual(question.correctCardIndex, 1)
        XCTAssertEqual(question.spatialRelation, .right)
    }
    
    func testQuestionHasUniqueID() throws {
        let question1 = Question(
            questionText: "Test 1",
            targetAnimal: .rabbit,
            targetPosition: 0,
            correctCardIndex: 1,
            highlightedCardIndex: 0,
            options: [],
            spatialRelation: .left,
            difficulty: .easy,
            gridSize: 3
        )
        
        let question2 = Question(
            questionText: "Test 2",
            targetAnimal: .bear,
            targetPosition: 1,
            correctCardIndex: 2,
            highlightedCardIndex: 1,
            options: [],
            spatialRelation: .right,
            difficulty: .easy,
            gridSize: 3
        )
        
        XCTAssertNotEqual(question1.id, question2.id)
    }
    
    func testQuestionRelationType() throws {
        let question = Question(
            questionText: "Test",
            targetAnimal: .rabbit,
            targetPosition: 0,
            correctCardIndex: 1,
            highlightedCardIndex: 0,
            options: [],
            spatialRelation: .left,
            difficulty: .easy,
            gridSize: 3
        )
        
        XCTAssertEqual(question.relationType, .left)
        XCTAssertEqual(question.spatialRelation, question.relationType)
    }
    
    // MARK: - Difficulty Tests
    
    func testDifficultyLevels() throws {
        XCTAssertEqual(Question.Difficulty.easy.rawValue, 1)
        XCTAssertEqual(Question.Difficulty.medium.rawValue, 2)
        XCTAssertEqual(Question.Difficulty.hard.rawValue, 3)
    }
    
    // MARK: - Spatial Relation Tests
    
    func testBasicSpatialRelations() throws {
        XCTAssertTrue(SpatialRelation.left.isBasic)
        XCTAssertTrue(SpatialRelation.right.isBasic)
        XCTAssertTrue(SpatialRelation.front.isBasic)
        XCTAssertTrue(SpatialRelation.back.isBasic)
        
        XCTAssertFalse(SpatialRelation.frontLeft.isBasic)
        XCTAssertFalse(SpatialRelation.frontRight.isBasic)
        XCTAssertFalse(SpatialRelation.backLeft.isBasic)
        XCTAssertFalse(SpatialRelation.backRight.isBasic)
    }
    
    func testSpatialRelationRawValues() throws {
        XCTAssertEqual(SpatialRelation.left.rawValue, "ひだり")
        XCTAssertEqual(SpatialRelation.right.rawValue, "みぎ")
        XCTAssertEqual(SpatialRelation.front.rawValue, "まえ")
        XCTAssertEqual(SpatialRelation.back.rawValue, "うしろ")
        XCTAssertEqual(SpatialRelation.frontLeft.rawValue, "ひだりまえ")
        XCTAssertEqual(SpatialRelation.frontRight.rawValue, "みぎまえ")
        XCTAssertEqual(SpatialRelation.backLeft.rawValue, "ひだりうしろ")
        XCTAssertEqual(SpatialRelation.backRight.rawValue, "みぎうしろ")
    }
}

// MARK: - QuestionGenerator Tests

class QuestionGeneratorTests: XCTestCase {
    
    func testQuestionGeneratorCreatesValidQuestion() throws {
        let generator = QuestionGenerator(level: 1)
        let question = generator.generateQuestion()
        
        XCTAssertNotNil(question)
        XCTAssertFalse(question.questionText.isEmpty)
        XCTAssertEqual(question.options.count, 4)
        XCTAssertTrue(question.options.contains(question.correctAnswer))
    }
    
    func testLevel1OnlyBasicRelations() throws {
        let generator = QuestionGenerator(level: 1)
        
        // Generate multiple questions to test
        for _ in 0..<10 {
            let question = generator.generateQuestion()
            XCTAssertTrue(question.spatialRelation.isBasic,
                         "Level 1 should only generate basic spatial relations")
        }
    }
    
    func testLevel2IncludesAllRelations() throws {
        let generator = QuestionGenerator(level: 2)
        var hasAdvancedRelation = false
        
        // Generate multiple questions to find advanced relations
        for _ in 0..<20 {
            let question = generator.generateQuestion()
            if !question.spatialRelation.isBasic {
                hasAdvancedRelation = true
                break
            }
        }
        
        XCTAssertTrue(hasAdvancedRelation,
                     "Level 2 should include advanced spatial relations")
    }
    
    func testOptionsDoNotContainDuplicates() throws {
        let generator = QuestionGenerator(level: 1)
        
        for _ in 0..<10 {
            let question = generator.generateQuestion()
            let uniqueOptions = Set(question.options)
            XCTAssertEqual(question.options.count, uniqueOptions.count,
                          "Options should not contain duplicates")
        }
    }
    
    func testCorrectCardIndexCalculation() throws {
        // Test specific card position calculation
        let generator = QuestionGenerator(level: 1)
        let question = generator.generateQuestion()
        
        // カードインデックスが適切な範囲内にあることを確認
        XCTAssertTrue(question.correctCardIndex >= 0)
        XCTAssertTrue(question.correctCardIndex < question.gridSize * question.gridSize)
        XCTAssertTrue(question.highlightedCardIndex >= 0)
        XCTAssertTrue(question.highlightedCardIndex < question.gridSize * question.gridSize)
    }
}

// MARK: - AnimalType Tests

class AnimalTypeTests: XCTestCase {
    
    func testAnimalTypeCount() throws {
        XCTAssertEqual(AnimalType.allCases.count, 6)
    }
    
    func testAnimalTypeRawValues() throws {
        XCTAssertEqual(AnimalType.rabbit.rawValue, "うさぎ")
        XCTAssertEqual(AnimalType.bear.rawValue, "くま")
        XCTAssertEqual(AnimalType.elephant.rawValue, "ぞう")
        XCTAssertEqual(AnimalType.giraffe.rawValue, "きりん")
        XCTAssertEqual(AnimalType.lion.rawValue, "らいおん")
        XCTAssertEqual(AnimalType.panda.rawValue, "ぱんだ")
    }
    
    func testAnimalTypeDisplayName() throws {
        for animal in AnimalType.allCases {
            XCTAssertEqual(animal.displayName, animal.rawValue)
        }
    }
    
    func testAnimalTypeImageNames() throws {
        XCTAssertEqual(AnimalType.rabbit.imageName, "hare.fill")
        XCTAssertEqual(AnimalType.bear.imageName, "pawprint.fill")
        XCTAssertEqual(AnimalType.elephant.imageName, "tortoise.fill")
        XCTAssertEqual(AnimalType.giraffe.imageName, "bird.fill")
        XCTAssertEqual(AnimalType.lion.imageName, "cat.fill")
        XCTAssertEqual(AnimalType.panda.imageName, "leaf.fill")
    }
}