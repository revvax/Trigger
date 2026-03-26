import SwiftUI

extension Color {
    // Primary orange — energetic, ADHD-friendly
    static let triggerOrange     = Color(red: 1.00, green: 0.42, blue: 0.00) // #FF6B00
    static let triggerOrangeLight = Color(red: 1.00, green: 0.55, blue: 0.10) // #FF8C1A

    // Backgrounds
    static let triggerBG         = Color(red: 0.10, green: 0.10, blue: 0.10) // #1A1A1A
    static let triggerCard       = Color(red: 0.15, green: 0.15, blue: 0.15) // #262626
    static let triggerCardBorder = Color(red: 0.22, green: 0.22, blue: 0.22) // #383838

    // Text
    static let triggerDarkWhite  = Color(red: 0.94, green: 0.91, blue: 0.87) // #F0E8DE
    static let triggerLightGray  = Color(red: 0.55, green: 0.55, blue: 0.55) // #8C8C8C
    static let triggerMediumGray = Color(red: 0.28, green: 0.28, blue: 0.28) // #474747

    // Semantic
    static let triggerSuccess    = Color(red: 0.20, green: 0.80, blue: 0.40) // #33CC66
    static let triggerDanger     = Color(red: 0.90, green: 0.25, blue: 0.25) // #E64040
}

// MARK: - Gradients
extension LinearGradient {
    static var triggerOrangeGradient: LinearGradient {
        LinearGradient(
            colors: [Color.triggerOrange, Color.triggerOrangeLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var triggerCardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.triggerCard, Color(red: 0.18, green: 0.18, blue: 0.18)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
