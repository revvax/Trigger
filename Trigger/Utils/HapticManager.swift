import SwiftUI
#if os(iOS)
import UIKit
#endif

struct HapticManager {
    #if os(iOS)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func success() { notification(.success) }
    static func error()   { notification(.error) }
    static func light()   { impact(.light) }
    static func heavy()   { impact(.heavy) }
    static func rigid()   { impact(.rigid) }
    #else
    static func success() {}
    static func error()   {}
    static func light()   {}
    static func heavy()   {}
    static func rigid()   {}
    #endif
}
