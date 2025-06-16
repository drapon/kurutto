import SwiftUI

@main
struct KuruttoApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        AudioManager.shared.setupAudioSession()
        
        UserDefaults.standard.register(defaults: [
            "soundEnabled": true,
            "voiceSpeed": 0.5,
            "difficultyLevel": 1
        ])
    }
}

class AppState: ObservableObject {
    @Published var currentScreen: Screen = .menu
    @Published var gameLevel: Int = 1
    @Published var soundEnabled: Bool = true
    
    enum Screen {
        case menu
        case game
        case settings
        case results
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            switch appState.currentScreen {
            case .menu:
                MenuView()
            case .game:
                GameView()
            case .settings:
                SettingsView()
            case .results:
                ResultsView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
    }
}