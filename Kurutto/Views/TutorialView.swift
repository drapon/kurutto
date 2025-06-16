import SwiftUI
import SceneKit

struct TutorialView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var sceneManager: SceneManager?
    @State private var selectedAnimal: AnimalType?
    @State private var showingCompletionAnimation = false
    
    private let speechManager = SpeechManager.shared
    private let animationManager = AnimationManager.shared
    
    let tutorialSteps: [TutorialStep] = [
        TutorialStep(
            title: "くるっとへようこそ！",
            description: "いっしょに あそびかたを まなぼう！",
            instruction: "つぎへ ボタンを おしてね",
            highlightElement: .nextButton
        ),
        TutorialStep(
            title: "どうぶつたちの せかい",
            description: "まるいボードに どうぶつたちが ならんでいるよ",
            instruction: "ボードを ゆびで まわしてみよう！",
            highlightElement: .scene
        ),
        TutorialStep(
            title: "もんだいを きいてみよう",
            description: "スピーカーボタンを おすと もんだいが きけるよ",
            instruction: "スピーカーボタンを おしてみて！",
            highlightElement: .speakerButton
        ),
        TutorialStep(
            title: "どうぶつを えらぼう",
            description: "もんだいの こたえだと おもう どうぶつを タップしよう",
            instruction: "どうぶつボタンを おしてみて！",
            highlightElement: .animalButtons
        ),
        TutorialStep(
            title: "ヒントをつかおう",
            description: "わからないときは ヒントボタンが でてくるよ",
            instruction: "2かい まちがえると ヒントが つかえるよ！",
            highlightElement: .hintButton
        ),
        TutorialStep(
            title: "さあ、はじめよう！",
            description: "じゅんびは できたかな？",
            instruction: "メニューに もどって ゲームを はじめよう！",
            highlightElement: .menuButton
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ヘッダー
                tutorialHeader
                
                // コンテンツ
                tutorialContent
                
                // ナビゲーション
                navigationButtons
            }
            
            // 完了アニメーション
            if showingCompletionAnimation {
                completionOverlay
            }
        }
        .onAppear {
            // SceneManagerを非同期で初期化
            DispatchQueue.main.async {
                if sceneManager == nil {
                    sceneManager = SceneManager()
                }
            }
            speakCurrentStep()
        }
    }
    
    private var tutorialHeader: some View {
        HStack {
            Text("チュートリアル")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryTextColor"))
            
            Spacer()
            
            // 進捗インジケーター
            HStack(spacing: 8) {
                ForEach(0..<tutorialSteps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color("PrimaryColor") : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .scaleEffect(index == currentStep ? 1.2 : 1.0)
                        .animation(.spring(), value: currentStep)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    
    private var tutorialContent: some View {
        VStack(spacing: 20) {
            // タイトルと説明
            VStack(spacing: 15) {
                Text(tutorialSteps[currentStep].title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color("PrimaryColor"))
                    .multilineTextAlignment(.center)
                
                Text(tutorialSteps[currentStep].description)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(Color("SecondaryTextColor"))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(currentStep)
            
            // デモエリア
            demoArea
            
            // 指示テキスト
            Text(tutorialSteps[currentStep].instruction)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(Color("AccentColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color("AccentColor").opacity(0.1))
                )
                .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var demoArea: some View {
        switch tutorialSteps[currentStep].highlightElement {
        case .scene:
            Group {
                if let sceneManager = sceneManager {
                    SceneView3D(
                        scene: sceneManager.scene,
                        selectedNode: .constant(nil),
                        onNodeTapped: { _ in }
                    )
                } else {
                    // ローディング中のプレースホルダー
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2)
                }
            }
            .frame(height: 300)
            .modifier(SceneViewModifier(cornerRadius: 20, shadow: true))
            .padding(.horizontal, 20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("PrimaryColor"), lineWidth: 3)
                    .padding(.horizontal, 20)
            )
            .pulseEffect(isPulsing: true)
            
        case .animalButtons:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(Array(AnimalType.allCases.prefix(4)), id: \.self) { animal in
                    DemoAnswerButton(animal: animal) {
                        selectedAnimal = animal
                        HapticManager.light()
                    }
                }
            }
            .padding(.horizontal, 40)
            
        case .speakerButton:
            Button(action: {
                speechManager.speak("これは れんしゅうの もんだいです")
            }) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color("AccentColor"))
                    .frame(width: 100, height: 100)
                    .background(Circle().fill(Color.white))
                    .shadow(radius: 5)
            }
            .pulseEffect(isPulsing: true)
            
        case .hintButton:
            Button(action: {
                speechManager.speak("ヒントです！ あかいところを みてね")
            }) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color("HintColor"))
                    .frame(width: 100, height: 100)
                    .background(Circle().fill(Color.white))
                    .shadow(radius: 5)
            }
            .pulseEffect(isPulsing: true)
            
        default:
            // プレースホルダー
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color("PrimaryColor").opacity(0.3))
                )
                .padding(.horizontal, 40)
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            if currentStep > 0 {
                SecondaryButton(title: "もどる", icon: "chevron.left") {
                    withAnimation(.spring()) {
                        currentStep -= 1
                        speakCurrentStep()
                    }
                }
            }
            
            Spacer()
            
            if currentStep < tutorialSteps.count - 1 {
                PrimaryButton(
                    title: "つぎへ",
                    icon: "chevron.right",
                    highlighted: tutorialSteps[currentStep].highlightElement == .nextButton
                ) {
                    withAnimation(.spring()) {
                        currentStep += 1
                        speakCurrentStep()
                    }
                }
            } else {
                PrimaryButton(
                    title: "メニューへ",
                    icon: "house.fill",
                    highlighted: tutorialSteps[currentStep].highlightElement == .menuButton
                ) {
                    completeTutorial()
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "star.fill")
                    .font(.system(size: 100))
                    .foregroundColor(Color("SuccessColor"))
                    .rotationEffect(.degrees(showingCompletionAnimation ? 720 : 0))
                    .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: showingCompletionAnimation)
                
                Text("よくできました！")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("チュートリアル かんりょう！")
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .scaleEffect(showingCompletionAnimation ? 1.0 : 0.5)
            .opacity(showingCompletionAnimation ? 1.0 : 0.0)
        }
        .modifier(ParticleEffect(isActive: showingCompletionAnimation, particleType: .stars))
    }
    
    private func speakCurrentStep() {
        let step = tutorialSteps[currentStep]
        let message = "\(step.title) \(step.description)"
        speechManager.speak(message, rate: 0.4)
    }
    
    private func completeTutorial() {
        showingCompletionAnimation = true
        HapticManager.success()
        speechManager.speak("チュートリアル かんりょう！ よくできました！")
        
        // チュートリアル完了をUserDefaultsに保存
        UserDefaults.standard.set(true, forKey: "tutorialCompleted")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            appState.currentScreen = .menu
        }
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let instruction: String
    let highlightElement: HighlightElement
}

enum HighlightElement {
    case nextButton
    case scene
    case speakerButton
    case animalButtons
    case hintButton
    case menuButton
}

struct DemoAnswerButton: View {
    let animal: AnimalType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: animal.imageName)
                    .font(.system(size: 40))
                    .foregroundColor(Color("PrimaryColor"))
                
                Text(animal.displayName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color("PrimaryTextColor"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(radius: 4)
            )
        }
        .pulseEffect(isPulsing: true)
    }
}

extension PrimaryButton {
    init(title: String, icon: String? = nil, highlighted: Bool = false, action: @escaping () -> Void) {
        self.init(title: title, icon: icon, action: action)
    }
}

#Preview {
    TutorialView()
        .environmentObject(AppState())
}