import SwiftUI
import SceneKit

struct GameView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var gameViewModel = GameViewModel()
    @State private var showingResult = false
    
    var body: some View {
        VStack(spacing: 0) {
            topBar
            
            questionSection
            
            Spacer()
            
            sceneSection
            
            Spacer()
            
            answerSection
            
            Spacer()
        }
        .onAppear {
            gameViewModel.startNewGame()
        }
        .sheet(isPresented: $showingResult) {
            ResultOverlay(
                isCorrect: gameViewModel.lastAnswerCorrect,
                onContinue: {
                    showingResult = false
                    gameViewModel.nextQuestion()
                }
            )
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
        SceneView(
            scene: gameViewModel.gameScene,
            options: [.allowsCameraControl, .autoenablesDefaultLighting]
        )
        .frame(height: 300)
        .background(Color.clear)
        .cornerRadius(20)
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
        gameViewModel.checkAnswer(answer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingResult = true
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

struct ResultOverlay: View {
    let isCorrect: Bool
    let onContinue: () -> Void
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if isCorrect {
                VStack(spacing: 20) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 100))
                        .foregroundColor(Color("SuccessColor"))
                        .scaleEffect(showAnimation ? 1.2 : 0.8)
                        .rotationEffect(.degrees(showAnimation ? 360 : 0))
                    
                    Text("せいかい！")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color("SuccessColor"))
                    
                    Text("よくできました！")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundColor(Color("SecondaryTextColor"))
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "face.smiling.fill")
                        .font(.system(size: 100))
                        .foregroundColor(Color("TryAgainColor"))
                        .scaleEffect(showAnimation ? 1.1 : 0.9)
                    
                    Text("おしい！")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color("TryAgainColor"))
                    
                    Text("もういちど かんがえてみよう")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(Color("SecondaryTextColor"))
                }
            }
            
            Spacer()
            
            PrimaryButton(title: "つぎへ", icon: "arrow.right") {
                onContinue()
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.95))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                showAnimation = true
            }
            
            if isCorrect {
                HapticManager.success()
            } else {
                HapticManager.light()
            }
        }
    }
}

#Preview {
    GameView()
        .environmentObject(AppState())
}