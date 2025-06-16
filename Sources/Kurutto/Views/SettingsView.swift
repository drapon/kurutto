import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("voiceSpeed") private var voiceSpeed: Double = 0.5
    @AppStorage("difficultyLevel") private var difficultyLevel: Int = 1
    @State private var showingResetAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(spacing: 25) {
                    soundSection
                    voiceSection
                    difficultySection
                    dataSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
            }
        }
        .background(Color("BackgroundColor"))
        .alert("データをリセット", isPresented: $showingResetAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("リセット", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("すべてのゲームデータが削除されます。この操作は取り消せません。")
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                appState.currentScreen = .menu
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .bold))
                    Text("もどる")
                        .font(.system(size: 20, weight: .medium))
                }
                .foregroundColor(Color("PrimaryColor"))
            }
            
            Spacer()
            
            Text("せってい")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryTextColor"))
            
            Spacer()
            
            Color.clear
                .frame(width: 100)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var soundSection: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 15) {
                Label("サウンド", systemImage: "speaker.wave.2.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("PrimaryTextColor"))
                
                Toggle(isOn: $soundEnabled) {
                    Text("こうかおん・BGM")
                        .font(.system(size: 20, weight: .medium))
                }
                .tint(Color("PrimaryColor"))
            }
        }
    }
    
    private var voiceSection: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 15) {
                Label("よみあげ", systemImage: "mic.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("PrimaryTextColor"))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("よみあげスピード")
                        .font(.system(size: 20, weight: .medium))
                    
                    HStack {
                        Image(systemName: "tortoise.fill")
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        Slider(value: $voiceSpeed, in: 0.3...0.7, step: 0.1)
                            .tint(Color("PrimaryColor"))
                        
                        Image(systemName: "hare.fill")
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    
                    Text(voiceSpeedText)
                        .font(.system(size: 18))
                        .foregroundColor(Color("SecondaryTextColor"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    private var difficultySection: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 15) {
                Label("なんいど", systemImage: "star.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("PrimaryTextColor"))
                
                Picker("難易度", selection: $difficultyLevel) {
                    Text("かんたん（3さい）").tag(1)
                    Text("ふつう（4さい）").tag(2)
                    Text("むずかしい（5さい）").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .background(Color("SegmentedBackgroundColor"))
                .cornerRadius(8)
            }
        }
    }
    
    private var dataSection: some View {
        SettingCard {
            VStack(alignment: .leading, spacing: 15) {
                Label("データかんり", systemImage: "folder.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("PrimaryTextColor"))
                
                Button(action: {
                    showingResetAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("すべてのデータをリセット")
                    }
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var voiceSpeedText: String {
        switch voiceSpeed {
        case 0.3: return "とても ゆっくり"
        case 0.4: return "ゆっくり"
        case 0.5: return "ふつう"
        case 0.6: return "はやい"
        case 0.7: return "とても はやい"
        default: return "ふつう"
        }
    }
    
    private func resetAllData() {
        UserDefaults.standard.removeObject(forKey: "gameProgress")
        UserDefaults.standard.removeObject(forKey: "highScore")
        UserDefaults.standard.removeObject(forKey: "totalPlayTime")
        
        CoreDataManager.shared.deleteAllData()
        
        appState.currentScreen = .menu
    }
}

struct SettingCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}