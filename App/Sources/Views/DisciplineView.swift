import SwiftUI
import StoicKit

/// Discipline screen — the enforcer layer: commitments carry an integrity stake.
struct DisciplineView: View {
    @Environment(AppState.self) private var app

    @State private var showingAdd = false
    @State private var text = ""
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    @State private var breakingId: UUID?
    @State private var breakReason = ""
    @State private var breakDelay = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScreenTitle("Discipline",
                                subtitle: "Commitments you are held to.")
                    Spacer()
                    Button {
                        showingAdd.toggle()
                    } label: {
                        Label("New commitment", systemImage: "plus")
                    }
                    .buttonStyle(GradientButtonStyle())
                }

                if showingAdd { addForm }
                stakeNote

                if activeCommitments.isEmpty {
                    Text("No active commitments. A commitment with a deadline is a promise the system will hold you to.")
                        .font(.callout)
                        .foregroundStyle(Theme.textDim)
                } else {
                    ForEach(activeCommitments) { commitmentRow($0) }
                }

                if !settledCommitments.isEmpty { settledSection }
            }
            .padding(24)
        }
    }

    private var activeCommitments: [Commitment] {
        app.commitments.filter { $0.status == .active }.sorted { $0.deadline < $1.deadline }
    }

    private var settledCommitments: [Commitment] {
        app.commitments.filter { $0.status != .active }
    }

    private var addForm: some View {
        Card(accent: Theme.cyan) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("New commitment")
                TextField("I commit to\u{2026}", text: $text)
                    .textFieldStyle(.roundedBorder)
                DatePicker("Deadline", selection: $deadline)
                    .datePickerStyle(.compact)
                HStack {
                    Spacer()
                    Button("Cancel") { resetAdd() }
                    Button("Commit") {
                        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        app.addCommitment(Commitment(text: text, deadline: deadline))
                        resetAdd()
                    }
                    .buttonStyle(GradientButtonStyle())
                }
            }
        }
    }

    private var stakeNote: some View {
        Card(accent: Theme.gold) {
            Text("Keep a commitment: +3 integrity. Break it — or let the deadline lapse — and the stake is paid: \u{2212}5. The system does not forget.")
                .font(.callout)
                .foregroundStyle(Theme.textDim)
        }
    }

    private func commitmentRow(_ commitment: Commitment) -> some View {
        Card(accent: Theme.danger.opacity(commitment.isOverdue ? 1 : 0.5)) {
            VStack(alignment: .leading, spacing: 10) {
                Text(commitment.text)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text("Deadline " + commitment.deadline.formatted(.relative(presentation: .named)))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(commitment.isOverdue ? Theme.danger : Theme.textDim)

                if breakingId == commitment.id {
                    TextField("Why are you breaking your word?", text: $breakReason)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Cancel") { breakingId = nil }
                        Spacer()
                        Button(breakDelay > 0 ? "Confirm in \(breakDelay)s" : "Confirm break") {
                            app.breakCommitment(commitment, reason: breakReason)
                            breakingId = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.danger)
                        .disabled(breakDelay > 0
                                  || breakReason.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } else {
                    HStack {
                        Button {
                            app.keepCommitment(commitment)
                        } label: {
                            Label("Kept", systemImage: "checkmark.seal")
                        }
                        .buttonStyle(GradientButtonStyle())
                        Button("Break") { startBreak(commitment) }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var settledSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Settled")
            ForEach(settledCommitments) { commitment in
                Card(accent: commitment.status == .kept ? Theme.ok : Theme.danger) {
                    HStack {
                        Image(systemName: commitment.status == .kept
                              ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .foregroundStyle(commitment.status == .kept ? Theme.ok : Theme.danger)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(commitment.text)
                                .font(.callout)
                                .foregroundStyle(Theme.textPrimary)
                                .strikethrough(commitment.status == .broken)
                            if commitment.status == .broken,
                               let reason = commitment.brokenReason, !reason.isEmpty {
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(Theme.danger)
                            }
                        }
                        Spacer()
                        Button {
                            app.deleteCommitment(commitment)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.textDim)
                    }
                }
            }
        }
    }

    private func startBreak(_ commitment: Commitment) {
        breakingId = commitment.id
        breakReason = ""
        breakDelay = 5
        Task {
            for _ in 0..<5 {
                try? await Task.sleep(for: .seconds(1))
                if breakingId == commitment.id { breakDelay -= 1 }
            }
        }
    }

    private func resetAdd() {
        text = ""
        deadline = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        showingAdd = false
    }
}
