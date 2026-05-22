import SwiftUI
import StoicKit

/// Dashboard screen.
struct DashboardView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle(greeting,
                            subtitle: Date.now.formatted(date: .complete, time: .omitted))

                HStack(alignment: .top, spacing: 16) {
                    goalsCard
                    idealSelfCard
                }
                auditCard

                Button {
                    app.section = .decisions
                } label: {
                    Label("New decision", systemImage: "brain.head.profile")
                }
                .buttonStyle(GradientButtonStyle())
            }
            .padding(24)
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  return "Good morning."
        case 12..<18: return "Good afternoon."
        default:      return "Good evening."
        }
    }

    private var goalsCard: some View {
        Card(accent: Theme.closer) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("Active goals", tint: Theme.closer)
                if app.goals.isEmpty {
                    Text("No goals yet. Add one in the Goals tab.")
                        .font(.callout).foregroundStyle(.secondary)
                } else {
                    ForEach(app.goals) { goal in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.title).font(.callout.weight(.medium))
                            ProgressView(value: goal.progress)
                            Text("\(Int(goal.progress * 100))% · \(goal.timeline)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var idealSelfCard: some View {
        Card(accent: Theme.pink) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Ideal Self", tint: Theme.pink)
                Text(app.idealSelf.narrative.isEmpty
                     ? "Not set yet."
                     : app.idealSelf.narrative)
                    .font(.callout)
                    .lineLimit(4)
                Divider()
                Text("\(app.idealSelf.traits.count) traits tracked")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Open Ideal Self") { app.section = .idealSelf }
                    .buttonStyle(.link)
            }
        }
    }

    private var auditCard: some View {
        Card(accent: Theme.further) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel("Time audit", tint: Theme.further)
                if app.checkins.isEmpty {
                    Text("No hours logged yet. STOIC OS grades how each hour was spent — start in the Time Audit tab.")
                        .font(.callout).foregroundStyle(.secondary)
                } else {
                    Text("\(app.checkins.count) hours logged.")
                        .font(.callout)
                    Text("Latest: \(app.checkins[0].activity) — grade \(app.checkins[0].qualityGrade)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
