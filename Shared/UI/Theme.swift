import SwiftUI

/// Colours and fonts shared by the app and the Live Activity.
/// Warm night palette: plum darks, cream text, peach and pink accents.
enum Theme {
    static let background = Color(hex: 0x0F0B12)
    static let card = Color(hex: 0x1A141F)
    static let cardBorder = Color(hex: 0x2C2232)
    static let lockBackground = Color(hex: 0x17111B)

    static let cream = Color(hex: 0xF7EDE2)
    static let muted = Color(hex: 0xA3949C)
    static let peach = Color(hex: 0xFF9F7A)
    static let pink = Color(hex: 0xFF7FA8)
    static let mint = Color(hex: 0x8FE3B0)
    static let danger = Color(hex: 0xFF6B6B)

    static func pixelFont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func roundedFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
