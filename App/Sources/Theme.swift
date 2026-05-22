import SwiftUI

/// Visual theme — a dark, colourful look with real depth.
enum Theme {
    static let corner: CGFloat = 18

    // MARK: - Palette
    static let accent  = Color(red: 0.56, green: 0.47, blue: 1.00)   // violet
    static let accent2 = Color(red: 0.36, green: 0.71, blue: 1.00)   // blue
    static let closer  = Color(red: 0.32, green: 0.86, blue: 0.55)   // green
    static let neutral = Color(red: 0.62, green: 0.64, blue: 0.72)
    static let further = Color(red: 1.00, green: 0.56, blue: 0.32)   // orange
    static let gold    = Color(red: 1.00, green: 0.80, blue: 0.32)
    static let pink    = Color(red: 1.00, green: 0.45, blue: 0.70)

    // MARK: - Gradients
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.05, blue: 0.11),
            Color(red: 0.09, green: 0.07, blue: 0.17),
            Color(red: 0.04, green: 0.08, blue: 0.15)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let accentGradient = LinearGradient(
        colors: [accent, accent2],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static func tintedSurface(_ tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [tint.opacity(0.20), Color.white.opacity(0.02)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let edgeHighlight = LinearGradient(
        colors: [Color.white.opacity(0.35), Color.white.opacity(0.04)],
        startPoint: .top, endPoint: .bottom)
}

/// A raised, glassy content card with depth, a coloured glow, and a hover lift.
struct Card<Content: View>: View {
    private let accent: Color
    private let content: Content
    @State private var hovering = false

    init(accent: Color = Theme.accent, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                        .fill(Theme.tintedSurface(accent))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Theme.edgeHighlight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.55),
                    radius: hovering ? 26 : 16, x: 0, y: hovering ? 16 : 10)
            .shadow(color: accent.opacity(hovering ? 0.40 : 0.15),
                    radius: hovering ? 30 : 16, x: 0, y: 0)
            .scaleEffect(hovering ? 1.012 : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: hovering)
            .onHover { hovering = $0 }
    }
}

/// Large screen heading with gradient text.
struct ScreenTitle: View {
    let text: String
    var subtitle: String?

    init(_ text: String, subtitle: String? = nil) {
        self.text = text
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accentGradient)
                .shadow(color: Theme.accent.opacity(0.35), radius: 12, x: 0, y: 4)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A small, uppercase, accent-coloured section label.
struct SectionLabel: View {
    let text: String
    var tint: Color = Theme.accent

    init(_ text: String, tint: Color = Theme.accent) {
        self.text = text
        self.tint = tint
    }

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.3)
            .foregroundStyle(tint)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A raised, gradient-filled primary button with a press animation.
struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(Theme.accentGradient,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(.white)
            .shadow(color: Theme.accent.opacity(configuration.isPressed ? 0.30 : 0.55),
                    radius: configuration.isPressed ? 5 : 14,
                    x: 0, y: configuration.isPressed ? 2 : 7)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

/// Placeholder for screens whose deeper logic is still in progress.
struct ComingSoonNote: View {
    let module: String

    var body: some View {
        Card(accent: Theme.further) {
            VStack(alignment: .leading, spacing: 6) {
                Label("In progress", systemImage: "hammer.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.further)
                Text("\(module) — the layout is here; the deeper logic is still being built.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
