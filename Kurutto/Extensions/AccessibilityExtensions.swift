import SwiftUI
import UIKit

// MARK: - Accessibility Identifiers

enum AccessibilityIdentifier {
    // Menu
    static let playButton = "menu_play_button"
    static let tutorialButton = "menu_tutorial_button"
    static let settingsButton = "menu_settings_button"
    static let resultsButton = "menu_results_button"
    
    // Game
    static let questionText = "game_question_text"
    static let speakButton = "game_speak_button"
    static let hintButton = "game_hint_button"
    static let scoreLabel = "game_score_label"
    static let levelLabel = "game_level_label"
    static let animalButton = "game_animal_button"
    static let sceneView = "game_scene_view"
    
    // Settings
    static let soundToggle = "settings_sound_toggle"
    static let voiceSpeedSlider = "settings_voice_speed_slider"
    static let difficultyPicker = "settings_difficulty_picker"
}

// MARK: - SwiftUI Accessibility Extensions

extension View {
    func accessibilityAddTraits(if condition: Bool, _ traits: AccessibilityTraits) -> some View {
        if condition {
            return AnyView(self.accessibilityAddTraits(traits))
        } else {
            return AnyView(self)
        }
    }
    
    func accessibilityElement(children: AccessibilityChildBehavior = .ignore,
                            label: String? = nil,
                            value: String? = nil,
                            hint: String? = nil,
                            identifier: String? = nil) -> some View {
        self
            .accessibilityElement(children: children)
            .if(label != nil) { view in
                view.accessibilityLabel(label!)
            }
            .if(value != nil) { view in
                view.accessibilityValue(value!)
            }
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .if(identifier != nil) { view in
                view.accessibilityIdentifier(identifier!)
            }
    }
    
    func gameAccessibilityLabel(_ text: String) -> some View {
        self.accessibilityLabel(text)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Accessibility Helpers

struct AccessibilityHelper {
    
    // MARK: - VoiceOver Support
    
    static func announceForVoiceOver(_ message: String, delay: TimeInterval = 0.1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(
                notification: .announcement,
                argument: message
            )
        }
    }
    
    static func announceScreenChange(_ message: String) {
        UIAccessibility.post(
            notification: .screenChanged,
            argument: message
        )
    }
    
    // MARK: - Accessibility Labels
    
    static func animalButtonLabel(for animal: AnimalType, isHighlighted: Bool) -> String {
        var label = animal.displayName
        if isHighlighted {
            label += "、まちがえました"
        }
        return label
    }
    
    static func questionLabel(_ questionText: String) -> String {
        return "もんだい: " + questionText
    }
    
    static func scoreLabel(_ score: Int) -> String {
        return "とくてん: \(score)てん"
    }
    
    static func levelLabel(_ level: Int) -> String {
        return "レベル: \(level)"
    }
    
    static func hintButtonLabel(isShowing: Bool) -> String {
        if isShowing {
            return "ヒントをかくす"
        } else {
            return "ヒントをひょうじ"
        }
    }
    
    // MARK: - Accessibility Hints
    
    static func animalButtonHint() -> String {
        return "タップして このどうぶつを えらびます"
    }
    
    static func speakButtonHint() -> String {
        return "タップして もんだいを よみあげます"
    }
    
    static func sceneViewHint() -> String {
        return "ゆびで なぞって ボードを かいてんできます"
    }
}

// MARK: - Accessible Custom Views

struct AccessibleAnimalButton: View {
    let animal: AnimalType
    let isHighlighted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: animal.imageName)
                    .font(.system(size: 40))
                    .foregroundColor(isHighlighted ? Color("HighlightColor") : Color("PrimaryColor"))
                
                Text(animal.displayName)
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
        .accessibilityElement(
            label: AccessibilityHelper.animalButtonLabel(for: animal, isHighlighted: isHighlighted),
            hint: AccessibilityHelper.animalButtonHint(),
            identifier: "\(AccessibilityIdentifier.animalButton)_\(animal.rawValue)"
        )
        .accessibilityAddTraits(.isButton)
    }
}

struct AccessibleQuestionView: View {
    let questionText: String
    let onSpeak: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text(questionText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryTextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .frame(minHeight: 80)
                .accessibilityElement(
                    label: AccessibilityHelper.questionLabel(questionText),
                    identifier: AccessibilityIdentifier.questionText
                )
                .accessibilityAddTraits(.isHeader)
            
            Button(action: onSpeak) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color("AccentColor"))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.white))
                    .shadow(radius: 3)
            }
            .accessibilityElement(
                label: "もんだいを よみあげる",
                hint: AccessibilityHelper.speakButtonHint(),
                identifier: AccessibilityIdentifier.speakButton
            )
        }
    }
}

// MARK: - Dynamic Type Support

struct ScaledFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    
    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight, design: design))
    }
    
    private var scaledSize: CGFloat {
        let userFontSize = UIApplication.shared.preferredContentSizeCategory
        let multiplier = fontSizeMultiplier(for: userFontSize)
        return size * multiplier
    }
    
    private func fontSizeMultiplier(for category: UIContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall: return 0.8
        case .small: return 0.85
        case .medium: return 0.9
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.4
        case .accessibilityLarge: return 1.5
        case .accessibilityExtraLarge: return 1.6
        case .accessibilityExtraExtraLarge: return 1.7
        case .accessibilityExtraExtraExtraLarge: return 1.8
        default: return 1.0
        }
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.modifier(ScaledFont(size: size, weight: weight, design: design))
    }
}

// MARK: - Reduce Motion Support

struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let reducedAnimation: Animation?
    
    func body(content: Content) -> some View {
        content.animation(reduceMotion ? reducedAnimation : animation)
    }
}

extension View {
    func adaptiveAnimation(_ animation: Animation?, reduced: Animation? = .linear(duration: 0.1)) -> some View {
        self.modifier(ReducedMotionModifier(animation: animation, reducedAnimation: reduced))
    }
}

// MARK: - High Contrast Support

struct HighContrastColorModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    let standardColor: Color
    let highContrastColor: Color
    
    func body(content: Content) -> some View {
        content.foregroundColor(colorSchemeContrast == .increased ? highContrastColor : standardColor)
    }
}

extension View {
    func adaptiveColor(standard: Color, highContrast: Color) -> some View {
        self.modifier(HighContrastColorModifier(standardColor: standard, highContrastColor: highContrast))
    }
}