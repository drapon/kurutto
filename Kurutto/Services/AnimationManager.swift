import SwiftUI
import SceneKit

class AnimationManager {
    static let shared = AnimationManager()
    
    private init() {}
    
    // MARK: - SwiftUI Animations
    
    /// ボタンのバウンスアニメーション
    static func bounceAnimation() -> Animation {
        Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)
    }
    
    /// フェードインアニメーション
    static func fadeIn(duration: Double = 0.3, delay: Double = 0) -> Animation {
        Animation.easeOut(duration: duration).delay(delay)
    }
    
    /// スケールアニメーション
    static func scaleAnimation(from: CGFloat = 0.8, to: CGFloat = 1.0, duration: Double = 0.3) -> Animation {
        Animation.easeInOut(duration: duration)
    }
    
    /// 回転アニメーション
    static func rotationAnimation(duration: Double = 1.0) -> Animation {
        Animation.linear(duration: duration).repeatForever(autoreverses: false)
    }
    
    // MARK: - SceneKit Animations
    
    /// 動物のジャンプアニメーション
    func animalJumpAnimation(height: CGFloat = 0.5, duration: TimeInterval = 0.4) -> SCNAction {
        let moveUp = SCNAction.moveBy(x: 0, y: height, z: 0, duration: duration / 2)
        moveUp.timingMode = .easeOut
        
        let moveDown = SCNAction.moveBy(x: 0, y: -height, z: 0, duration: duration / 2)
        moveDown.timingMode = .easeIn
        
        return SCNAction.sequence([moveUp, moveDown])
    }
    
    /// 動物の回転ジャンプアニメーション（正解時）
    func animalCelebrationAnimation() -> SCNAction {
        let jump = animalJumpAnimation(height: 0.8, duration: 0.5)
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 0.5)
        let group = SCNAction.group([jump, rotate])
        
        return SCNAction.sequence([
            group,
            SCNAction.wait(duration: 0.2),
            animalJumpAnimation(height: 0.3, duration: 0.3)
        ])
    }
    
    /// ボードの回転アニメーション
    func boardRotationAnimation(angle: CGFloat = CGFloat.pi * 2, duration: TimeInterval = 3.0) -> SCNAction {
        let rotation = SCNAction.rotateBy(x: 0, y: angle, z: 0, duration: duration)
        rotation.timingMode = .easeInEaseOut
        return rotation
    }
    
    /// パルスアニメーション（ヒント用）
    func pulseAnimation(scale: CGFloat = 1.2, duration: TimeInterval = 0.6) -> SCNAction {
        let scaleUp = SCNAction.scale(to: scale, duration: duration / 2)
        scaleUp.timingMode = .easeInEaseOut
        
        let scaleDown = SCNAction.scale(to: 1.0, duration: duration / 2)
        scaleDown.timingMode = .easeInEaseOut
        
        return SCNAction.repeatForever(SCNAction.sequence([scaleUp, scaleDown]))
    }
    
    /// 揺れアニメーション（不正解時）
    func shakeAnimation(intensity: CGFloat = 0.1, duration: TimeInterval = 0.5) -> SCNAction {
        let numberOfShakes = 4
        let shakeDuration = duration / TimeInterval(numberOfShakes * 2)
        
        var actions: [SCNAction] = []
        
        for i in 0..<numberOfShakes {
            let angle = intensity * (i % 2 == 0 ? 1 : -1)
            let rotate = SCNAction.rotateBy(x: 0, y: 0, z: angle, duration: shakeDuration)
            actions.append(rotate)
            
            let rotateBack = SCNAction.rotateBy(x: 0, y: 0, z: -angle, duration: shakeDuration)
            actions.append(rotateBack)
        }
        
        return SCNAction.sequence(actions)
    }
    
    /// フェードイン・アウトアニメーション
    func fadeAnimation(fadeIn: Bool, duration: TimeInterval = 0.3) -> SCNAction {
        if fadeIn {
            return SCNAction.fadeIn(duration: duration)
        } else {
            return SCNAction.fadeOut(duration: duration)
        }
    }
    
    /// カメラのズームアニメーション
    func cameraZoomAnimation(to position: SCNVector3, duration: TimeInterval = 1.0) -> SCNAction {
        let move = SCNAction.move(to: position, duration: duration)
        move.timingMode = .easeInEaseOut
        return move
    }
}

// MARK: - View Extensions for Animations

extension View {
    /// バウンスエフェクトを適用
    func bounceEffect(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(AnimationManager.bounceAnimation(), value: isPressed)
    }
    
    /// パルスエフェクトを適用
    func pulseEffect(isPulsing: Bool) -> some View {
        self.scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(
                isPulsing ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
    }
    
    /// 回転エフェクトを適用
    func rotationEffect(isRotating: Bool, duration: Double = 1.0) -> some View {
        self.rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                isRotating ? AnimationManager.rotationAnimation(duration: duration) : .default,
                value: isRotating
            )
    }
    
    /// シェイクエフェクトを適用
    func shakeEffect(shake: Bool) -> some View {
        self.offset(x: shake ? -5 : 0)
            .animation(
                shake ? Animation.default.repeatCount(3, autoreverses: true).speed(3) : .default,
                value: shake
            )
    }
}

// MARK: - Particle Effects

struct ParticleEffect: ViewModifier {
    let isActive: Bool
    let particleType: ParticleType
    
    enum ParticleType {
        case confetti
        case stars
        case hearts
    }
    
    func body(content: Content) -> some View {
        content.overlay(
            ParticleView(isActive: isActive, particleType: particleType)
                .allowsHitTesting(false)
        )
    }
}

struct ParticleView: View {
    let isActive: Bool
    let particleType: ParticleEffect.ParticleType
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var scale: CGFloat
        var rotation: Double
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particleShape(for: particleType)
                        .fill(particleColor)
                        .frame(width: 20, height: 20)
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                        .opacity(particle.opacity)
                        .position(particle.position)
                }
            }
            .onAppear {
                if isActive {
                    createParticles(in: geometry.size)
                }
            }
            .onChange(of: isActive) { newValue in
                if newValue {
                    createParticles(in: geometry.size)
                } else {
                    particles.removeAll()
                }
            }
        }
    }
    
    private func particleShape(for type: ParticleEffect.ParticleType) -> some Shape {
        switch type {
        case .confetti:
            return AnyShape(Rectangle())
        case .stars:
            return AnyShape(Star())
        case .hearts:
            return AnyShape(Heart())
        }
    }
    
    private var particleColor: Color {
        [Color.red, Color.yellow, Color.green, Color.blue, Color.purple, Color.orange].randomElement() ?? Color.yellow
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<30).map { _ in
            Particle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                velocity: CGVector(
                    dx: CGFloat.random(in: -100...100),
                    dy: CGFloat.random(in: 200...400)
                ),
                scale: CGFloat.random(in: 0.5...1.5),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
        }
        
        animateParticles()
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            if particles.isEmpty {
                timer.invalidate()
                return
            }
            
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.dx * 0.016
                particles[i].position.y += particles[i].velocity.dy * 0.016
                particles[i].velocity.dy += 500 * 0.016 // gravity
                particles[i].rotation += 5
                particles[i].opacity -= 0.01
                
                if particles[i].opacity <= 0 {
                    particles.remove(at: i)
                    break
                }
            }
        }
    }
}

// Custom Shapes
struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = rect.width / 2
        let rc = r * 0.5
        var path = Path()
        
        for i in 0..<5 {
            let angle = (CGFloat(i) * .pi * 2 / 5) - .pi / 2
            let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
            
            let angle2 = angle + .pi / 5
            let pt2 = CGPoint(x: center.x + cos(angle2) * rc, y: center.y + sin(angle2) * rc)
            path.addLine(to: pt2)
        }
        
        path.closeSubpath()
        return path
    }
}

struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width / 2, y: height / 4))
        
        path.addCurve(
            to: CGPoint(x: 0, y: height / 2),
            control1: CGPoint(x: width / 2, y: 0),
            control2: CGPoint(x: 0, y: height / 4)
        )
        
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: 0, y: height * 3 / 4),
            control2: CGPoint(x: width / 2, y: height)
        )
        
        path.addCurve(
            to: CGPoint(x: width, y: height / 2),
            control1: CGPoint(x: width / 2, y: height),
            control2: CGPoint(x: width, y: height * 3 / 4)
        )
        
        path.addCurve(
            to: CGPoint(x: width / 2, y: height / 4),
            control1: CGPoint(x: width, y: height / 4),
            control2: CGPoint(x: width / 2, y: 0)
        )
        
        return path
    }
}

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}