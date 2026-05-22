import SwiftUI
import StoicKit

/// Dashboard screen.
struct DashboardView: View {
    @Environment(AppState.self) private var app
    @State private var showReport = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle(greeting,
                            subtitle: Date.now.formatted(date: .complete, time: .omitted))

                briefCard

                HStack(alignment: .top, spacing: 16) {
                    goalsCard
                    constitutionCard
                }
                auditCard

                HStack {
                    Button {
                        app.section = .decisions
                    } label: {
                        Label("New decision", systemImage: "brain.head.profile")
                    }
                    .buttonStyle(GradientButtonStyle())
                    Button {
                        showReport = true
                    } label: {
                        Label("Weekly report", systemImage: "doc.text")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showReport) {
            WeeklyReportView().environment(app)
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  return "Good morning."
        case 12..<18: return "Good afternoon."
        default:      return "Good evening."
        }
    }

    private var brief: [String] {
        let total = app.checkins.count
        let productive = app.checkins.filter { $0.quality == .productive }.count
        let ratio = total > 0 ? Int(Double(productive) / Double(total) * 100) : nil
        var recovery: Int?
        if case .connected = app.whoop.state { recovery = app.whoop.vitals.recoveryPercent }
        let pending = app.decisions.filter { ($0.outcome ?? "").isEmpty }.count
        return MorningBrief.compose(BriefInput(
            integrityScore: app.constitution.integrityScore,
            drift: app.constitution.drift,
            recoveryPercent: recovery,
            productiveRatioPercent: ratio,
            pendingOutcomes: pending,
            todayBlockCount: app.timeBlocks.count))
    }

    private var briefCard: some View {
        Card(accent: Theme.cyan) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Morning brief")
                ForEach(Array(brief.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{25B8}")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.cyan)
                            .padding(.top, 4)
                        Text(line)
                            .font(.callout)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
    }

    private var goalsCard: some View {
        Card(accent: Theme.closer) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("Active goals", tint: Theme.closer)
                if app.goals.isEmpty {
                    Text("No goals yet. Add one in the Goals tab.")
                        .font(.callout).foregroundStyle(Theme.textDim)
                } else {
                    ForEach(app.goals) { goal in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.title)
                                .font(.callout.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)
                            HUDBar(value: goal.progress, accent: Theme.closer)
                            Text("\(Int(goal.progress * 100))%  ·  \(goal.timeline)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Theme.textDim)
                        }
                    }
                }
            }
        }
    }

    private var constitutionCard: some View {
        Card(accent: Theme.gold) {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel("Constitution", tint: Theme.gold)
                HStack(spacing: 14) {
                    RingGauge(value: Double(app.constitution.integrityScore) / 100.0,
                              accent: Theme.gold, lineWidth: 7)
                        .frame(width: 66, height: 66)
                        .overlay(
                            Text("\(app.constitution.integrityScore)")
                                .font(.system(size: 21, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Integrity score")
                            .font(.caption).foregroundStyle(Theme.textDim)
                        Text("DRIFT \(app.constitution.drift)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Theme.textDim)
                    }
                }
                Text(app.constitution.narrative.isEmpty
                     ? "Not set." : app.constitution.narrative)
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
                    .lineLimit(3)
                Button("Open Constitution") { app.section = .constitution }
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
                        .font(.callout).foregroundStyle(Theme.textDim)
                } else {
                    let productive = app.checkins.filter { $0.quality == .productive }.count
                    Text("\(app.checkins.count) hours logged  ·  \(productive) productive")
                        .font(.callout).foregroundStyle(Theme.textPrimary)
                    Text("Latest: \(app.checkins[0].activity) — \(app.checkins[0].quality.label)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textDim)
                }
            }
        }
    }
}
