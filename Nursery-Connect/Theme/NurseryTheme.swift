import SwiftUI

enum NurseryTheme {
    /// Bright, friendly teal — primary actions & tint
    static let accent = Color(red: 0.12, green: 0.62, blue: 0.68)
    /// Lively mint — highlights & success
    static let mint = Color(red: 0.35, green: 0.82, blue: 0.62)
    /// Cheerful sky — diary / learning
    static let diaryTint = Color(red: 0.22, green: 0.58, blue: 0.95)
    /// Warm coral — incidents (visible, not alarming)
    static let incidentTint = Color(red: 1.0, green: 0.52, blue: 0.38)

    static let sunshine = Color(red: 1.0, green: 0.84, blue: 0.35)

    static let pageBackgroundTop = Color(red: 0.88, green: 0.96, blue: 1.0)
    static let pageBackgroundBottom = Color(red: 0.82, green: 0.98, blue: 0.92)

    static let cardBackground = Color.white.opacity(0.96)
    static let cardShadow = Color(red: 0.2, green: 0.45, blue: 0.55).opacity(0.12)

    static var pageBackground: some View {
        LinearGradient(
            colors: [pageBackgroundTop, pageBackgroundBottom, sunshine.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct NurseryCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(NurseryTheme.cardBackground)
                    .shadow(color: NurseryTheme.cardShadow, radius: 10, x: 0, y: 4)
            )
    }
}

extension View {
    func nurseryCard() -> some View {
        modifier(NurseryCardModifier())
    }
}

struct NurseryTapAnimationStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}
