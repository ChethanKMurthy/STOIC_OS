import SwiftUI
import StoicKit

/// Goals screen.
struct GoalsView: View {
    @Environment(AppState.self) private var app
    @State private var showingAdd = false
    @State private var title = ""
    @State private var timeline = ""
    @State private var baseline = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScreenTitle("Goals")
                    Button {
                        showingAdd.toggle()
                    } label: {
                        Label("New Goal", systemImage: "plus")
                    }
                }

                if showingAdd { addForm }

                if app.goals.isEmpty {
                    Text("No goals yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(app.goals) { goal in goalCard(goal) }
                }

                ComingSoonNote(module: "Goal breakdown into milestones and micro-tasks")
            }
            .padding(24)
        }
    }

    private var addForm: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("New goal")
                TextField("Goal — who do you want to become / what to achieve", text: $title)
                TextField("Timeline (e.g. by Dec 2026)", text: $timeline)
                TextField("Where you are now (baseline)", text: $baseline)
                HStack {
                    Spacer()
                    Button("Cancel") { reset() }
                    Button("Add goal") {
                        guard !title.isEmpty else { return }
                        app.addGoal(Goal(title: title, timeline: timeline, baseline: baseline))
                        reset()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func goalCard(_ goal: Goal) -> some View {
        Card(accent: Theme.closer) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button {
                        app.deleteGoal(goal)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.danger)
                    .help("Delete goal")
                }
                HStack {
                    HUDBar(value: goal.progress, accent: Theme.closer)
                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textDim)
                }
                if !goal.timeline.isEmpty {
                    Text(goal.timeline).font(.caption).foregroundStyle(Theme.textDim)
                }
                if !goal.baseline.isEmpty {
                    Text("Baseline: \(goal.baseline)")
                        .font(.caption).foregroundStyle(Theme.textDim)
                }
            }
        }
    }

    private func reset() {
        title = ""; timeline = ""; baseline = ""; showingAdd = false
    }
}
