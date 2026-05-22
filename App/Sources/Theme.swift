import SwiftUI

/// Shared, low-fi styling — a neutral, accessible baseline, not the final look.
enum Theme {
    static let corner: CGFloat = 12
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let closer = Color.green
    static let neutral = Color.secondary
    static let further = Color.orange
}

/// A simple bordered content card.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardBackground,
                        in: RoundedRectangle(cornerRadius: Theme.corner))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner)
                    .stroke(Color.primary.opacity(0.08))
            )
    }
}

/// Large screen heading.
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
                .font(.largeTitle.weight(.semibold))
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

/// A small uppercase section label.
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Placeholder for screens whose deeper logic is still in progress.
struct ComingSoonNote: View {
    let module: String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Label("In progress", systemImage: "hammer")
                    .font(.headline)
                Text("\(module) — the layout is here; the deeper logic is still being built.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
