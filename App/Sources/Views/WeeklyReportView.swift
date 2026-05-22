import SwiftUI
import StoicKit

/// The weekly drift report — rendered with the gravity of a printed document.
struct WeeklyReportView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEEKLY DRIFT REPORT")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(Theme.gold)
                    Text(Date.now.formatted(date: .complete, time: .omitted))
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.textDim)
                }

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(section.heading)
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(section.body)
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .lineSpacing(3)
                        Rectangle()
                            .fill(Theme.cyanDim.opacity(0.25))
                            .frame(height: 1)
                            .padding(.top, 4)
                    }
                }

                Button("Close") { dismiss() }
                    .buttonStyle(GradientButtonStyle())
            }
            .padding(40)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 560, minHeight: 520)
        .background(Theme.appBackground.ignoresSafeArea())
    }

    private var sections: [ReportSection] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekCheckins = app.checkins.filter { $0.hourStart >= weekAgo }
        let weekDecisions = app.decisions.filter { $0.createdAt >= weekAgo }
        let integrityWeekAgo = app.trajectory
            .filter { $0.date <= weekAgo }
            .max(by: { $0.date < $1.date })?
            .integrityScore

        return WeeklyReport.compose(WeeklyReportInput(
            integrityNow: app.constitution.integrityScore,
            integrityWeekAgo: integrityWeekAgo,
            drift: app.constitution.drift,
            hoursLogged: weekCheckins.count,
            productiveHours: weekCheckins.filter { $0.quality == .productive }.count,
            decisionsMade: weekDecisions.count,
            outcomesLogged: weekDecisions.filter { ($0.outcome ?? "").isEmpty == false }.count))
    }
}
