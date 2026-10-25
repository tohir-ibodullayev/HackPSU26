import SwiftUI
import UIKit

/// Tokens extracted from the Studyday MHTML mockup (Expo / react-native-web).
enum StudydayTheme {
    static func adaptive(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
    /// Near-black ink used for brand, headlines, and primary CTA.
    static let ink = Color.primary
    /// Soft sage-gray for badges / secondary labels.
    static let sage = Color(red: 112 / 255, green: 131 / 255, blue: 123 / 255)
    /// Muted body copy.
    static let muted = Color.secondary
    /// Brand blue accent (dot, badge pip, interactive).
    static let accent = Color(red: 67 / 255, green: 136 / 255, blue: 237 / 255)
    static let accentBright = Color(red: 84 / 255, green: 141 / 255, blue: 244 / 255)
    /// Soft blue-gray icon wells.
    static let mist = adaptive(UIColor(red: 237 / 255, green: 242 / 255, blue: 246 / 255, alpha: 1), .tertiarySystemBackground)
    static let mistDeep = adaptive(UIColor(red: 236 / 255, green: 241 / 255, blue: 247 / 255, alpha: 1), .tertiarySystemBackground)
    /// Soft green check / success accent from preview card.
    static let softGreen = Color(red: 107 / 255, green: 147 / 255, blue: 131 / 255)
    static let iconBlue = Color(red: 82 / 255, green: 124 / 255, blue: 158 / 255)
    /// Paper surfaces.
    static let paper = adaptive(UIColor(red: 250 / 255, green: 250 / 255, blue: 248 / 255, alpha: 1), .systemBackground)
    static let paperElevated = adaptive(.white, .secondarySystemBackground)
    static let chipFill = adaptive(UIColor(red: 240 / 255, green: 241 / 255, blue: 239 / 255, alpha: 1), .tertiarySystemBackground)
    static let outerWash = adaptive(UIColor(red: 233 / 255, green: 236 / 255, blue: 235 / 255, alpha: 1), .systemBackground)
    static let border = Color(red: 227 / 255, green: 233 / 255, blue: 229 / 255)
    static let borderSoft = Color(red: 231 / 255, green: 233 / 255, blue: 230 / 255)
    static let badgeBorder = Color(red: 201 / 255, green: 213 / 255, blue: 209 / 255)
    static let danger = Color(red: 0.75, green: 0.22, blue: 0.22)

    static let corner: CGFloat = 20
    static let cornerCard: CGFloat = 21
    static let cornerIcon: CGFloat = 24
}

/// Soft mint → sky → warm paper wash from the mockup hero.
struct StudydayBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ZStack {
            StudydayTheme.outerWash
            LinearGradient(
                colors: colorScheme == .dark ? [Color(uiColor: .systemBackground), Color(uiColor: .secondarySystemBackground)] : [
                    Color(red: 233 / 255, green: 244 / 255, blue: 239 / 255),
                    Color(red: 234 / 255, green: 241 / 255, blue: 251 / 255),
                    StudydayTheme.adaptive(UIColor(red: 250 / 255, green: 250 / 255, blue: 248 / 255, alpha: 1), .systemBackground)
                ],
                startPoint: UnitPoint(x: 0.05, y: 0.0),
                endPoint: UnitPoint(x: 0.95, y: 1.0)
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func campusCard() -> some View {
        self.padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StudydayTheme.paperElevated, in: RoundedRectangle(cornerRadius: StudydayTheme.cornerCard))
            .overlay(RoundedRectangle(cornerRadius: StudydayTheme.cornerCard).stroke(StudydayTheme.border, lineWidth: 1))
    }
}
