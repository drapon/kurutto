import SwiftUI

struct ParticleView: View {
    let isActive: Bool
    let particleType: ParticleType
    
    enum ParticleType {
        case confetti
        case stars
        case sparkles
    }
    
    var body: some View {
        if isActive {
            ZStack {
                ForEach(0..<20, id: \.self) { i in
                    ParticleShape(type: particleType)
                        .foregroundColor(randomColor())
                        .frame(width: 10, height: 10)
                        .offset(x: randomX(), y: randomY())
                        .opacity(isActive ? 1 : 0)
                        .animation(
                            Animation.easeOut(duration: 2.0)
                                .delay(Double(i) * 0.1),
                            value: isActive
                        )
                }
            }
        }
    }
    
    private func randomColor() -> Color {
        let colors: [Color] = [.red, .green, .blue, .yellow, .purple, .orange, .pink]
        return colors.randomElement() ?? .blue
    }
    
    private func randomX() -> CGFloat {
        CGFloat.random(in: -200...200)
    }
    
    private func randomY() -> CGFloat {
        CGFloat.random(in: -300...300)
    }
}

struct ParticleShape: View {
    let type: ParticleView.ParticleType
    
    var body: some View {
        switch type {
        case .confetti:
            Rectangle()
                .frame(width: 8, height: 8)
        case .stars:
            Image(systemName: "star.fill")
                .font(.system(size: 12))
        case .sparkles:
            Image(systemName: "sparkle")
                .font(.system(size: 10))
        }
    }
}

#Preview {
    ParticleView(isActive: true, particleType: .confetti)
}