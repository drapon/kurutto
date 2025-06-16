import SwiftUI

struct MenuView: View {
    @EnvironmentObject var appState: AppState
    @State private var animateTitle = false
    @State private var showingAbout = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            Spacer()
            
            menuButtons
            
            Spacer()
            
            footerSection
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animateTitle = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                
                Button(action: {
                    showingAbout = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Color("PrimaryColor"))
                }
                .sheet(isPresented: $showingAbout) {
                    SettingsView()
                }
            }
            
            Text("くるっと")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryColor"))
                .scaleEffect(animateTitle ? 1.0 : 0.8)
                .opacity(animateTitle ? 1.0 : 0.6)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateTitle)
                .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("楽しく学ぼう 空間認識！")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(Color("SecondaryTextColor"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var menuButtons: some View {
        VStack(spacing: 20) {
            PrimaryButton(
                title: "あそぶ",
                icon: "play.fill"
            ) {
                appState.currentScreen = .game
            }
            
            HStack(spacing: 20) {
                SecondaryButton(
                    title: "設定",
                    icon: "gearshape.fill"
                ) {
                    appState.currentScreen = .settings
                }
                
                SecondaryButton(
                    title: "成績",
                    icon: "chart.bar.fill"
                ) {
                    appState.currentScreen = .results
                }
                
                SecondaryButton(
                    title: "ヘルプ",
                    icon: "questionmark.circle.fill"
                ) {
                    appState.currentScreen = .tutorial
                }
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 10) {
            Text("推奨年齢: 3歳〜5歳")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("SecondaryTextColor"))
            
            Text("Version 1.0")
                .font(.system(size: 14))
                .foregroundColor(Color("SecondaryTextColor").opacity(0.7))
        }
        .padding(.bottom, 20)
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(width: 280, height: 80)
            .background(Color("PrimaryButtonColor"))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
            }
            .foregroundColor(Color("SecondaryButtonTextColor"))
            .frame(width: 105, height: 80)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("SecondaryButtonBorderColor"), lineWidth: 3)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    MenuView()
        .environmentObject(AppState())
}