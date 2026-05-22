import SwiftUI
import StoicKit

/// Onboarding / intake interview.
/// V0 is a 3-step intake; a fuller guided interview is planned.
struct OnboardingView: View {
    @Environment(AppState.self) private var app
    @State private var step = 0
    @State private var narrative = ""
    @State private var selected: Set<String> = ["Composure", "Integrity", "High-agency"]

    private let traits = ["Composure", "Integrity", "High-agency", "Discipline",
                          "Politically smart", "Patience", "Courage", "Calibration"]
    private let totalSteps = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(index <= step ? Color.accentColor
                                                        : Color.secondary.opacity(0.3))
                }
                Spacer()
                Text("Step \(step + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            switch step {
            case 0:  welcomeStep
            case 1:  identityStep
            default: readyStep
            }

            Spacer()

            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                }
                Spacer()
                Button(step == totalSteps - 1 ? "Enter STOIC OS" : "Continue") {
                    advance()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(step == 1 && selected.isEmpty)
            }
        }
        .padding(36)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.appBackground.ignoresSafeArea())
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to STOIC OS")
                .font(.largeTitle.weight(.semibold))
            Text("A private reasoning companion that helps you choose well, account for your time, and become the specific person you decide to be. Everything runs on this Mac.")
                .foregroundStyle(.secondary)
        }
    }

    private var identityStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Who are you trying to become?")
                .font(.title2.weight(.semibold))
            Text("Describe the person you want to be — in your own words. Be specific.")
                .font(.callout)
                .foregroundStyle(.secondary)
            TextEditor(text: $narrative)
                .font(.body)
                .frame(height: 120)
                .padding(6)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.3)))
            Text("Pick the traits that matter most:")
                .font(.callout)
                .foregroundStyle(.secondary)
            FlowChips(options: traits, selected: $selected)
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You're set.")
                .font(.title2.weight(.semibold))
            Text("STOIC OS will measure your decisions and hours against your Constitution. Refine it any time from the Constitution screen.")
                .foregroundStyle(.secondary)
        }
    }

    private func advance() {
        guard step == totalSteps - 1 else {
            step += 1
            return
        }
        let traitModels = selected.map { ConstitutionTrait(name: $0) }
        let model = ConstitutionModel(
            narrative: narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Composed under pressure, principled, and high-agency."
                : narrative,
            traits: traitModels
        )
        app.completeOnboarding(constitution: model)
    }
}

/// A wrapping selectable-chip grid.
struct FlowChips: View {
    let options: [String]
    @Binding var selected: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 8)],
                  alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isOn = selected.contains(option)
                Button {
                    if isOn { selected.remove(option) } else { selected.insert(option) }
                } label: {
                    Text(option)
                        .font(.callout)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .tint(isOn ? .accentColor : .secondary)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }
}
