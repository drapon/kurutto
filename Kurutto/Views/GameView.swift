import SwiftUI
import SceneKit

struct GameView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var gameViewModel = GameViewModel()
    @State private var showingResult = false
    @State private var animatingHint = false
    
    var body: some View {
        VStack(spacing: 0) {
            topBar
            
            questionSection
            
            Spacer()
            
            sceneSection
                .overlay(celebrationOverlay)
            
            Spacer()
            
            answerSection
            
            Spacer()
        }
        .onAppear {
            gameViewModel.startNewGame()
            AudioManager.shared.playBackgroundMusic(.game)
        }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: {
                appState.currentScreen = .menu
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("PrimaryColor"))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white))
                    .shadow(radius: 2)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Label("\(gameViewModel.currentScore)", systemImage: "star.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("ScoreColor"))
                
                Label("\(gameViewModel.currentLevel)", systemImage: "flag.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("LevelColor"))
            }
            
            Spacer()
            
            Button(action: {
                gameViewModel.toggleSound()
            }) {
                Image(systemName: gameViewModel.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("PrimaryColor"))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white))
                    .shadow(radius: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    private var questionSection: some View {
        VStack(spacing: 15) {
            Text(gameViewModel.currentQuestion?.questionText ?? "")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryTextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .frame(minHeight: 80)
            
            HStack(spacing: 20) {
                Button(action: {
                    gameViewModel.speakQuestion()
                }) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color("AccentColor"))
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.white))
                        .shadow(radius: 3)
                }
                .bounceEffect(isPressed: false)
                
                if gameViewModel.highlightedAnswers.count >= 2 {
                    Button(action: {
                        gameViewModel.showHint()
                        animatingHint = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            animatingHint = false
                        }
                    }) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color("HintColor"))
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 3)
                    }
                    .pulseEffect(isPulsing: animatingHint)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("QuestionBackgroundColor"))
                .shadow(radius: 5)
        )
        .padding(.horizontal, 20)
    }
    
    private var sceneSection: some View {
        SceneView3D(
            scene: gameViewModel.gameScene,
            selectedNode: .constant(nil),
            onNodeTapped: { nodeName in
                // 3Dシーン内の動物がタップされた時の処理
                if let animal = AnimalType.allCases.first(where: { $0.rawValue == nodeName }) {
                    handleAnswer(animal)
                }
            }
        )
        .frame(height: 350)
        .modifier(SceneViewModifier(cornerRadius: 20, shadow: true))
        .padding(.horizontal, 20)
    }
    
    private var answerSection: some View {
        VStack(spacing: 15) {
            if let options = gameViewModel.currentQuestion?.options {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(options, id: \.self) { animal in
                        AnswerButton(
                            animal: animal,
                            isHighlighted: gameViewModel.highlightedAnswers.contains(animal)
                        ) {
                            handleAnswer(animal)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func handleAnswer(_ answer: AnimalType) {
        HapticManager.light()
        gameViewModel.checkAnswer(answer)
    }
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        if gameViewModel.showingCelebration {
            ParticleView(isActive: true, particleType: .confetti)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }
}

struct AnswerButton: View {
    let animal: AnimalType
    let isHighlighted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: animal.imageName)
                    .font(.system(size: 40))
                    .foregroundColor(isHighlighted ? Color("HighlightColor") : Color("PrimaryColor"))
                
                Text(animal.rawValue)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color("PrimaryTextColor"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: isHighlighted ? Color("HighlightColor").opacity(0.5) : .gray.opacity(0.3), 
                           radius: isHighlighted ? 8 : 4,
                           x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isHighlighted ? Color("HighlightColor") : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}


#Preview {
    GameView()
        .environmentObject(AppState())
}