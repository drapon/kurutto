import SwiftUI

// ボタンのバウンスエフェクト
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// バウンスエフェクトモディファイア
extension View {
    func bounceEffect(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
    }
    
    func pulseEffect(isPulsing: Bool) -> some View {
        self
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(isPulsing ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: isPulsing)
    }
}