import SwiftUI

enum AppTheme {
    // MARK: - Colors
    static let background     = Color(hex: "#08080d")
    static let surface        = Color(hex: "#111118")
    static let card           = Color(hex: "#181822")
    static let gold           = Color(hex: "#d4a853")
    static let goldDim        = Color(hex: "#b8943f")
    static let textPrimary    = Color(hex: "#eae6df")
    static let textDim        = Color(hex: "#7a7680")
    static let accent         = Color(hex: "#e84545")
    static let green          = Color(hex: "#4ecb71")

    // MARK: - Fonts
    static func arabic(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Tajawal", size: size).weight(weight)
    }

    static func english(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Playfair Display", size: size).weight(weight)
    }

    // MARK: - Radius
    static let radius: CGFloat = 14
    static let radiusSmall: CGFloat = 10

    // MARK: - Gradients
    static let goldGradient = LinearGradient(
        colors: [gold, Color(hex: "#f0d48a"), goldDim],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color from Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
