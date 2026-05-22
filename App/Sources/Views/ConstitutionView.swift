import SwiftUI
import Charts
import StoicKit

/// Constitution screen — the numeric core of who the user has defined themselves to be.
struct ConstitutionView: View {
    @Environment(AppState.self) private var app
    @State private var editing = false
    @State private var draft = ConstitutionModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    ScreenTitle("Constitution",
                                subtitle: "Version \(app.constitution.version)")
                    Spacer()
                    Button(editing ? "Save" : "Edit") { toggleEdit() }
                        .buttonStyle(GradientButtonStyle())
                }

                integrityCore
                trajectoryCard
                narrativeCard
                traitsCard
            }
            .padding(24)
        }
    }

    // MARK: - Integrity core

    private var integrityCore: some View {
        Card(accent: Theme.gold) {
            HStack(spacing: 26) {
                RingGauge(value: Double(app.constitution.integrityScore) / 100.0,
                          accent: Theme.gold)
                    .frame(width: 128, height: 128)
                    .overlay(
                        VStack(spacing: -2) {
                            Text("\(app.constitution.integrityScore)")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("INTEGRITY")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(Theme.textDim)
                        }
                    )

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Constitution Core", tint: Theme.gold)
                    Text("How closely who you are tracks who you have defined yourself to be.")
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.branch")
                        Text("DRIFT  \(app.constitution.drift)")
                            .tracking(1)
                    }
                    .font(.system(.callout, design: .monospaced).weight(.semibold))
                    .foregroundStyle(app.constitution.drift > 40 ? Theme.danger : Theme.textDim)
                }
            }
        }
    }

    // MARK: - Trajectory

    private var trajectoryCard: some View {
        Card(accent: Theme.gold) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Integrity trajectory", tint: Theme.gold)
                if app.trajectory.count < 2 {
                    Text("Not enough history yet — the trajectory builds as you decide and log time.")
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                } else {
                    Chart(app.trajectory) { point in
                        AreaMark(x: .value("Date", point.date),
                                 y: .value("Integrity", point.integrityScore))
                            .foregroundStyle(Theme.gold.opacity(0.16))
                            .interpolationMethod(.catmullRom)
                        LineMark(x: .value("Date", point.date),
                                 y: .value("Integrity", point.integrityScore))
                            .foregroundStyle(Theme.gold)
                            .interpolationMethod(.catmullRom)
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 150)
                }
            }
        }
    }

    // MARK: - Narrative

    private var narrativeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("The person you are becoming")
                if editing {
                    TextEditor(text: $draft.narrative)
                        .font(.body)
                        .frame(height: 100)
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.cyanDim.opacity(0.4)))
                } else {
                    Text(app.constitution.narrative.isEmpty
                         ? "Not set." : app.constitution.narrative)
                        .font(.body)
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }

    // MARK: - Traits

    private var traitsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel("Traits  ·  current \u{2192} target")
                if editing {
                    ForEach($draft.traits) { $trait in
                        traitEditor($trait)
                    }
                } else if app.constitution.traits.isEmpty {
                    Text("No traits defined.")
                        .font(.callout).foregroundStyle(Theme.textDim)
                } else {
                    ForEach(app.constitution.traits) { trait in
                        traitRow(trait)
                    }
                }
            }
        }
    }

    private func traitRow(_ trait: ConstitutionTrait) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(trait.name)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(trait.currentLevel) \u{2192} \(trait.targetLevel)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textDim)
            }
            HUDBar(value: Double(trait.currentLevel) / 100.0,
                   accent: trait.currentLevel >= trait.targetLevel ? Theme.ok : Theme.cyan)
        }
    }

    private func traitEditor(_ trait: Binding<ConstitutionTrait>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trait.wrappedValue.name)
                .font(.callout.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
            Stepper("Current  \(trait.wrappedValue.currentLevel)",
                    value: trait.currentLevel, in: 0...100, step: 5)
                .font(.system(.caption, design: .monospaced))
            Stepper("Target   \(trait.wrappedValue.targetLevel)",
                    value: trait.targetLevel, in: 0...100, step: 5)
                .font(.system(.caption, design: .monospaced))
            HUDDivider()
        }
    }

    // MARK: - Edit

    private func toggleEdit() {
        if editing {
            app.saveConstitution(draft)
        } else {
            draft = app.constitution
        }
        editing.toggle()
    }
}
