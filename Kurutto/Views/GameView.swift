import SwiftUI
import SceneKit

struct GameView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var gameViewModel = GameViewModel()
    @State private var showingResult = false
    @State private var animatingHint = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            topBar
            
            questionSection
            
            Spacer()
            
            sceneSection
                .overlay(celebrationOverlay)
            
            Spacer()
            
            controlSection
            
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
                .font(.system(size: 28, weight: .bold, design: .rounded))
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
                
                if gameViewModel.highlightedCards.count >= 2 && 
                   gameViewModel.currentQuestion?.spatialRelation != .gridPosition {
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
                // カードがタップされた時の処理
                if nodeName.hasPrefix("card_"),
                   let indexString = nodeName.split(separator: "_").last,
                   let index = Int(indexString) {
                    handleCardTap(index)
                }
            }
        )
        .frame(height: 350)
        .modifier(SceneViewModifier(cornerRadius: 20, shadow: true))
        .padding(.horizontal, 20)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    isDragging = false
                    handleSwipe(value.translation)
                    dragOffset = .zero
                }
        )
        .overlay(
            swipeIndicator
                .opacity(gameViewModel.currentAnimalView == nil ? 0.7 : 0)
        )
    }
    
    private var swipeIndicator: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "hand.draw")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("スワイプして動物の視点に切り替え")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
            .cornerRadius(20)
            .padding(.bottom, 10)
        }
    }
    
    private var controlSection: some View {
        VStack(spacing: 15) {
            if let question = gameViewModel.currentQuestion {
                // カードの選択肢を表示
                HStack(spacing: 10) {
                    ForEach(question.options, id: \.self) { cardIndex in
                        CardOptionButton(
                            cardIndex: cardIndex,
                            isHighlighted: gameViewModel.highlightedCards.contains(cardIndex),
                            gridSize: question.gridSize
                        ) {
                            handleCardTap(cardIndex)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // 視点リセットボタン
            if gameViewModel.currentAnimalView != nil {
                Button(action: {
                    gameViewModel.resetToDefaultView()
                }) {
                    Label("通常視点に戻る", systemImage: "arrow.uturn.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(25)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.bottom, 20)
    }
    
    private func handleCardTap(_ cardIndex: Int) {
        HapticManager.light()
        gameViewModel.checkCardAnswer(cardIndex)
    }
    
    private func handleSwipe(_ translation: CGSize) {
        let threshold: CGFloat = 50
        
        if abs(translation.width) > abs(translation.height) {
            // 横スワイプ
            if translation.width > threshold {
                gameViewModel.handleSwipe(direction: .right)
            } else if translation.width < -threshold {
                gameViewModel.handleSwipe(direction: .left)
            }
        } else {
            // 縦スワイプ
            if translation.height > threshold {
                gameViewModel.handleSwipe(direction: .down)
            } else if translation.height < -threshold {
                gameViewModel.handleSwipe(direction: .up)
            }
        }
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

struct CardOptionButton: View {
    let cardIndex: Int
    let isHighlighted: Bool
    let gridSize: Int
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                // カードの位置を表示（例：2行3列）
                let row = cardIndex / gridSize + 1
                let col = cardIndex % gridSize + 1
                
                Text("\(row)-\(col)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(isHighlighted ? Color("HighlightColor") : Color("PrimaryColor"))
                
                Image(systemName: "square.fill")
                    .font(.system(size: 30))
                    .foregroundColor(isHighlighted ? Color("HighlightColor") : Color("PrimaryColor").opacity(0.3))
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: isHighlighted ? Color("HighlightColor").opacity(0.5) : .gray.opacity(0.3), 
                           radius: isHighlighted ? 8 : 4,
                           x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isHighlighted ? Color("HighlightColor") : Color.clear, lineWidth: 3)
            )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}


#Preview {
    GameView()
        .environmentObject(AppState())
}