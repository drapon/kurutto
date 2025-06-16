import SwiftUI

struct MenuView: View {
    @EnvironmentObject var appState: AppState
    @State private var animateTitle = false
    @State private var animateButtons = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            titleSection
            
            Spacer()
            
            animalCircle
            
            Spacer()
            
            buttonSection
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .onAppear {
            startAnimations()
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 10) {
            Text("くるっと")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryColor"))
                .scaleEffect(animateTitle ? 1.0 : 0.8)
                .opacity(animateTitle ? 1.0 : 0.0)
            
            Text("どうぶつたちと いっしょに\nくうかんにんしきを まなぼう！")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(Color("SecondaryTextColor"))
                .multilineTextAlignment(.center)
                .opacity(animateTitle ? 1.0 : 0.0)
        }
    }
    
    private var animalCircle: some View {
        ZStack {
            ForEach(0..<6) { index in
                AnimalIcon(animalType: AnimalType.allCases[index])
                    .frame(width: 80, height: 80)
                    .offset(x: 120 * cos(CGFloat(index) * .pi / 3 + rotationAngle),
                           y: 120 * sin(CGFloat(index) * .pi / 3 + rotationAngle))
            }
        }
        .frame(width: 300, height: 300)
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = .pi * 2
            }
        }
    }
    
    private var buttonSection: some View {
        VStack(spacing: 20) {
            PrimaryButton(title: "あそぶ", icon: "play.fill") {
                withAnimation {
                    appState.currentScreen = .game
                }
            }
            .scaleEffect(animateButtons ? 1.0 : 0.8)
            .opacity(animateButtons ? 1.0 : 0.0)
            
            HStack(spacing: 20) {
                SecondaryButton(title: "せってい", icon: "gearshape.fill") {
                    withAnimation {
                        appState.currentScreen = .settings
                    }
                }
                
                SecondaryButton(title: "きろく", icon: "chart.bar.fill") {
                    withAnimation {
                        appState.currentScreen = .results
                    }
                }
            }
            .scaleEffect(animateButtons ? 1.0 : 0.8)
            .opacity(animateButtons ? 1.0 : 0.0)
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.6)) {
            animateTitle = true
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            animateButtons = true
        }
    }
}

enum AnimalType: String, CaseIterable {
    case rabbit = "うさぎ"
    case bear = "くま"
    case elephant = "ぞう"
    case giraffe = "きりん"
    case lion = "らいおん"
    case panda = "ぱんだ"
    
    var imageName: String {
        switch self {
        case .rabbit: return "hare.fill"
        case .bear: return "pawprint.fill"
        case .elephant: return "elephant.fill"
        case .giraffe: return "giraffe.fill"
        case .lion: return "lion.fill"
        case .panda: return "panda.fill"
        }
    }
}

struct AnimalIcon: View {
    let animalType: AnimalType
    @State private var bounce = false
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
            .overlay(
                Image(systemName: animalType.imageName)
                    .font(.system(size: 40))
                    .foregroundColor(Color("AccentColor"))
            )
            .scaleEffect(bounce ? 1.1 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever()) {
                    bounce = true
                }
            }
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
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
        .buttonStyle(BounceButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
            }
            .foregroundColor(Color("SecondaryButtonTextColor"))
            .frame(width: 120, height: 80)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("SecondaryButtonBorderColor"), lineWidth: 3)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    MenuView()
        .environmentObject(AppState())
}