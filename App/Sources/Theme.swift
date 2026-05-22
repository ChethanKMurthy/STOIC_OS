import SwiftUI

/// HUD command-center visual system — obsidian surfaces, cyan holographics,
/// gold reserved for command-level state. The whole app inherits this through
/// the shared components below.
enum Theme {
    static let corner: CGFloat = 14

    // MARK: - Palette
    static let obsidian    = Color(red: 0.02, green: 0.03, blue: 0.05)
    static let panelFill   = Color(red: 0.06, green: 0.10, blue: 0.13)
    static let cyan        = Color(red: 0.38, green: 0.86, blue: 1.00)
    static let cyanDim     = Color(red: 0.22, green: 0.48, blue: 0.58)
    static let gold        = Color(red: 1.00, green: 0.78, blue: 0.34)
    static let danger      = Color(red: 1.00, green: 0.38, blue: 0.42)
    static let ok          = Color(red: 0.40, green: 0.95, blue: 0.62)
    static let textPrimary = Color(red: 0.87, green: 0.95, blue: 0.99)
    static let textDim     = Color(red: 0.49, green: 0.62, blue: 0.70)

    // Back-compatible aliases used across the app.
    static let accent  = cyan
    static let accent2 = Color(red: 0.55, green: 0.66, blue: 1.00)
    static let closer  = ok
    static let neutral = textDim
    static let further = gold
    static let pink    = Color(red: 1.00, green: 0.46, blue: 0.72)

    // MARK: - Gradients
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.02, green: 0.03, blue: 0.05),
            Color(red: 0.04, green: 0.06, blue: 0.10),
            Color(red: 0.02, green: 0.03, blue: 0.06)
        ],
        startPoint: .top, endPoint: .bottom)

    static let accentGradient = LinearGradient(
        colors: [cyan, accent2],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// L-shaped corner brackets — the signature HUD frame.
struct CornerBrackets: Shape {
    var inset: CGFloat = 5
    var length: CGFloat = 16

    var animatableData: CGFloat {
        get { length }
        set { length = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = rect.insetBy(dx: inset, dy: inset)
        let l = min(length, min(r.width, r.height) / 2)

        path.move(to: CGPoint(x: r.minX, y: r.minY + l))
        path.addLine(to: CGPoint(x: r.minX, y: r.minY))
        path.addLine(to: CGPoint(x: r.minX + l, y: r.minY))

        path.move(to: CGPoint(x: r.maxX - l, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY + l))

        path.move(to: CGPoint(x: r.maxX, y: r.maxY - l))
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.maxX - l, y: r.maxY))

        path.move(to: CGPoint(x: r.minX + l, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY - l))

        return path
    }
}

/// A holographic HUD panel: translucent obsidian fill, a thin glowing border,
/// corner brackets that extend on hover, and a coloured glow.
struct Card<Content: View>: View {
    private let accent: Color
    private let content: Content
    @State private var hovering = false

    init(accent: Color = Theme.cyan, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.panelFill.opacity(0.55))
                    .background(
                        RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(accent.opacity(hovering ? 0.5 : 0.22), lineWidth: 1)
            )
            .overlay(
                CornerBrackets(inset: 5, length: hovering ? 24 : 16)
                    .stroke(accent.opacity(hovering ? 1.0 : 0.7), lineWidth: 1.5)
            )
            .shadow(color: accent.opacity(hovering ? 0.38 : 0.14),
                    radius: hovering ? 20 : 11)
            .animation(.easeOut(duration: 0.25), value: hovering)
            .onHover { hovering = $0 }
    }
}

/// Large screen heading — uppercased, tracked, with a glow and a command marker.
struct ScreenTitle: View {
    let text: String
    var subtitle: String?

    init(_ text: String, subtitle: String? = nil) {
        self.text = text
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 11) {
                Rectangle()
                    .fill(Theme.cyan)
                    .frame(width: 3, height: 26)
                    .shadow(color: Theme.cyan, radius: 6)
                Text(text.uppercased())
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(2)
                    .shadow(color: Theme.cyan.opacity(0.55), radius: 9)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A small monospaced section label with a command marker.
struct SectionLabel: View {
    let text: String
    var tint: Color = Theme.cyan

    init(_ text: String, tint: Color = Theme.cyan) {
        self.text = text
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("\u{25B8}")
                .font(.system(size: 9))
                .foregroundStyle(tint)
            Text(text.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1.7)
                .foregroundStyle(tint)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// A holographic primary button — thin glowing frame that fills when pressed.
struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, design: .rounded).weight(.semibold))
            .tracking(1)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .foregroundStyle(configuration.isPressed ? Theme.obsidian : Theme.cyan)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(configuration.isPressed ? Theme.cyan : Theme.cyan.opacity(0.10))
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Theme.cyan, lineWidth: 1)
                }
            )
            .shadow(color: Theme.cyan.opacity(configuration.isPressed ? 0.25 : 0.5),
                    radius: configuration.isPressed ? 4 : 12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Placeholder for screens whose deeper logic is still in progress.
struct ComingSoonNote: View {
    let module: String

    var body: some View {
        Card(accent: Theme.gold) {
            VStack(alignment: .leading, spacing: 6) {
                Label("SUBSYSTEM PENDING", systemImage: "circle.dotted")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(Theme.gold)
                Text("\(module) — interface online, deeper logic still being built.")
                    .font(.callout)
                    .foregroundStyle(Theme.textDim)
            }
        }
    }
}
