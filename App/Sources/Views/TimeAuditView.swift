import SwiftUI
import StoicKit

/// Time audit screen.
/// V0 supports a manual hourly check-in; background scheduling and hourly
/// notifications are planned.
struct TimeAuditView: View {
    @Environment(AppState.self) private var app
    @State private var activity = ""
    @State private var quality: TimeQuality = .productive

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle("Time Audit",
                            subtitle: "Account for an hour — honestly.")

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel("Log this hour")
                        TextField("How was this hour spent?", text: $activity)
                            .textFieldStyle(.roundedBorder)
                        Picker("Quality", selection: $quality) {
                            ForEach(TimeQuality.allCases, id: \.self) { value in
                                Text(value.label).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        HStack {
                            Spacer()
                            Button("Save check-in") {
                                guard !activity.isEmpty else { return }
                                app.addCheckin(HourlyCheckin(
                                    hourStart: Date(),
                                    activity: activity,
                                    quality: quality,
                                    userConfirmed: true))
                                activity = ""
                            }
                            .buttonStyle(GradientButtonStyle())
                            .disabled(activity.isEmpty)
                        }
                    }
                }

                if !app.checkins.isEmpty {
                    auditCard
                    ratioCard
                    loggedCard
                }

                ComingSoonNote(module: "Always-on hourly prompts when the app is fully closed (needs the background helper)")
            }
            .padding(24)
        }
    }

    private var auditCard: some View {
        let today = app.checkins.filter { Calendar.current.isDateInToday($0.hourStart) }
        let productive = today.filter { $0.quality == .productive }.count
        let lines = DailyAudit.compose(DailyAuditInput(
            hoursLogged: today.count,
            productiveHours: productive,
            integrityScore: app.constitution.integrityScore,
            drift: app.constitution.drift))
        return Card(accent: Theme.gold) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("End-of-day audit", tint: Theme.gold)
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{25B8}")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.gold)
                            .padding(.top, 4)
                        Text(line)
                            .font(.callout)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
    }

    private var ratioCard: some View {
        let total = app.checkins.count
        let productive = app.checkins.filter { $0.quality == .productive }.count
        let ratio = total > 0 ? Double(productive) / Double(total) : 0
        return Card(accent: Theme.closer) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Productive ratio", tint: Theme.closer)
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(ratio * 100))%")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(productive) / \(total) hours")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textDim)
                }
                HUDBar(value: ratio, accent: Theme.closer)
            }
        }
    }

    private var loggedCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Logged hours")
                ForEach(app.checkins.prefix(12)) { checkin in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(checkin.quality == .productive ? Theme.closer : Theme.danger)
                            .frame(width: 8, height: 8)
                        Text(checkin.activity)
                            .font(.callout)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(checkin.quality.label)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(checkin.quality == .productive
                                             ? Theme.closer : Theme.danger)
                    }
                }
            }
        }
    }
}
