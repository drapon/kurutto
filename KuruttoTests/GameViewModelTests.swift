import XCTest
import Combine
@testable import Kurutto

class GameViewModelTests: XCTestCase {
    
    var viewModel: GameViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        viewModel = GameViewModel()
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        cancellables = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() throws {
        XCTAssertEqual(viewModel.currentScore, 0)
        XCTAssertEqual(viewModel.currentLevel, 1)
        XCTAssertTrue(viewModel.soundEnabled)
        XCTAssertTrue(viewModel.highlightedAnswers.isEmpty)
        XCTAssertFalse(viewModel.lastAnswerCorrect)
        XCTAssertFalse(viewModel.showingHint)
        XCTAssertEqual(viewModel.hintCount, 0)
        XCTAssertFalse(viewModel.showingCelebration)
    }
    
    // MARK: - Game Flow Tests
    
    func testStartNewGame() throws {
        // Set some values
        viewModel.currentScore = 100
        viewModel.currentLevel = 3
        
        // Start new game
        viewModel.startNewGame()
        
        // Verify reset
        XCTAssertEqual(viewModel.currentScore, 0)
        XCTAssertEqual(viewModel.currentLevel, 1)
        XCTAssertNotNil(viewModel.currentQuestion)
    }
    
    func testNextQuestion() throws {
        // Setup
        viewModel.highlightedAnswers = [.rabbit, .bear]
        viewModel.hintCount = 2
        viewModel.showingHint = true
        
        // Generate next question
        viewModel.nextQuestion()
        
        // Verify reset
        XCTAssertTrue(viewModel.highlightedAnswers.isEmpty)
        XCTAssertEqual(viewModel.hintCount, 0)
        XCTAssertFalse(viewModel.showingHint)
        XCTAssertNotNil(viewModel.currentQuestion)
    }
    
    // MARK: - Answer Checking Tests
    
    func testCorrectAnswer() throws {
        viewModel.startNewGame()
        
        guard let question = viewModel.currentQuestion else {
            XCTFail("No question generated")
            return
        }
        
        let initialScore = viewModel.currentScore
        
        // Answer correctly
        viewModel.checkAnswer(question.correctAnswer)
        
        // Verify
        XCTAssertTrue(viewModel.lastAnswerCorrect)
        XCTAssertGreaterThan(viewModel.currentScore, initialScore)
        XCTAssertTrue(viewModel.showingCelebration)
    }
    
    func testIncorrectAnswer() throws {
        viewModel.startNewGame()
        
        guard let question = viewModel.currentQuestion else {
            XCTFail("No question generated")
            return
        }
        
        // Find an incorrect answer
        let incorrectAnswer = question.options.first { $0 != question.correctAnswer }!
        
        // Answer incorrectly
        viewModel.checkAnswer(incorrectAnswer)
        
        // Verify
        XCTAssertFalse(viewModel.lastAnswerCorrect)
        XCTAssertTrue(viewModel.highlightedAnswers.contains(incorrectAnswer))
    }
    
    // MARK: - Hint System Tests
    
    func testHintButtonAppearsAfterTwoMistakes() throws {
        viewModel.startNewGame()
        
        guard let question = viewModel.currentQuestion else {
            XCTFail("No question generated")
            return
        }
        
        // Find incorrect answers
        let incorrectAnswers = question.options.filter { $0 != question.correctAnswer }
        
        // First mistake
        viewModel.checkAnswer(incorrectAnswers[0])
        XCTAssertEqual(viewModel.highlightedAnswers.count, 1)
        
        // Second mistake
        viewModel.checkAnswer(incorrectAnswers[1])
        XCTAssertEqual(viewModel.highlightedAnswers.count, 2)
        
        // Hint should be available now (checked in UI by highlightedAnswers.count >= 2)
    }
    
    func testShowHint() throws {
        viewModel.startNewGame()
        
        let initialHintCount = viewModel.hintCount
        
        // Show hint
        viewModel.showHint()
        
        // Verify
        XCTAssertEqual(viewModel.hintCount, initialHintCount + 1)
        XCTAssertTrue(viewModel.showingHint)
    }
    
    // MARK: - Score Calculation Tests
    
    func testScoreWithoutHints() throws {
        viewModel.startNewGame()
        
        guard let question = viewModel.currentQuestion else {
            XCTFail("No question generated")
            return
        }
        
        viewModel.hintCount = 0
        viewModel.highlightedAnswers = []
        
        // Answer correctly without hints or mistakes
        viewModel.checkAnswer(question.correctAnswer)
        
        // Score should include bonuses
        // Base: 100 + No mistakes: 30 + No hints: 20 + Level bonus: 10 = 160
        XCTAssertGreaterThanOrEqual(viewModel.currentScore, 160)
    }
    
    func testScoreWithHints() throws {
        viewModel.startNewGame()
        
        guard let question = viewModel.currentQuestion else {
            XCTFail("No question generated")
            return
        }
        
        viewModel.hintCount = 2
        
        // Answer correctly with hints
        viewModel.checkAnswer(question.correctAnswer)
        
        // Score should be reduced by hint penalties
        // Base score minus hint penalties
        XCTAssertGreaterThan(viewModel.currentScore, 0)
    }
    
    // MARK: - Level Progression Tests
    
    func testLevelUp() throws {
        viewModel.startNewGame()
        
        // Simulate scoring enough points to level up
        viewModel.currentScore = 490
        
        guard let question = viewModel.currentQuestion else {
            XCTFail("No question generated")
            return
        }
        
        let initialLevel = viewModel.currentLevel
        
        // Answer correctly to push score over 500
        viewModel.checkAnswer(question.correctAnswer)
        
        // Should level up
        XCTAssertEqual(viewModel.currentLevel, initialLevel + 1)
    }
    
    // MARK: - Sound Toggle Tests
    
    func testToggleSound() throws {
        let initialSoundState = viewModel.soundEnabled
        
        viewModel.toggleSound()
        
        XCTAssertEqual(viewModel.soundEnabled, !initialSoundState)
        XCTAssertEqual(UserDefaults.standard.bool(forKey: "soundEnabled"), !initialSoundState)
    }
    
    // MARK: - Publisher Tests
    
    func testCurrentScorePublisher() throws {
        let expectation = XCTestExpectation(description: "Score updated")
        
        viewModel.$currentScore
            .dropFirst() // Skip initial value
            .sink { score in
                XCTAssertGreaterThan(score, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.startNewGame()
        if let question = viewModel.currentQuestion {
            viewModel.checkAnswer(question.correctAnswer)
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Performance Tests

extension GameViewModelTests {
    
    func testQuestionGenerationPerformance() throws {
        measure {
            for _ in 0..<100 {
                viewModel.nextQuestion()
            }
        }
    }
    
    func testAnswerCheckingPerformance() throws {
        viewModel.startNewGame()
        
        guard let question = viewModel.currentQuestion else {
            XCTFail("No question generated")
            return
        }
        
        measure {
            for _ in 0..<100 {
                viewModel.checkAnswer(question.correctAnswer)
            }
        }
    }
}