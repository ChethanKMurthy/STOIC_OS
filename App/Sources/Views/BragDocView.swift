import SwiftUI
import StoicKit

/// Brag document screen.
struct BragDocView: View {
    @Environment(AppState.self) private var app
    @State private var showingAdd = false
    @State private var win = ""
    @State private var metric = ""
    @State private var stakeholders = ""
    @State private var outcome = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScreenTitle("Brag Document",
                                subtitle: "Evidence for your next promotion conversation.")
                    Button {
                        showingAdd.toggle()
                    } label: {
                        Label("Log a win", systemImage: "plus")
                    }
                }

                if showingAdd { addForm }

                if app.bragEntries.isEmpty {
                    Text("No wins logged yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(app.bragEntries) { entry in entryCard(entry) }
                }
            }
            .padding(24)
        }
    }

    private var addForm: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("New win")
                TextField("What did you accomplish?", text: $win)
                TextField("Metric (e.g. 4.1s → 2.4s p95)", text: $metric)
                TextField("Stakeholders", text: $stakeholders)
                TextField("Business outcome", text: $outcome)
                HStack {
                    Spacer()
                    Button("Cancel") { reset() }
                    Button("Add win") {
                        guard !win.isEmpty else { return }
                        app.addBragEntry(BragEntry(win: win, metric: metric,
                                                   stakeholders: stakeholders, outcome: outcome))
                        reset()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func entryCard(_ entry: BragEntry) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.win).font(.headline)
                    Spacer()
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !entry.metric.isEmpty { labelled("Metric", entry.metric) }
                if !entry.stakeholders.isEmpty { labelled("Stakeholders", entry.stakeholders) }
                if !entry.outcome.isEmpty { labelled("Outcome", entry.outcome) }
            }
        }
    }

    private func labelled(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(key + ":").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(value).font(.caption)
        }
    }

    private func reset() {
        win = ""; metric = ""; stakeholders = ""; outcome = ""; showingAdd = false
    }
}
