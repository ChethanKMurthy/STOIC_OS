import SwiftUI
import StoicKit

/// Time audit screen.
/// V0 supports a manual hourly check-in; background scheduling and hourly
/// notifications are planned.
struct TimeAuditView: View {
    @Environment(AppState.self) private var app
    @State private var activity = ""
    @State private var grade = "B"
    private let grades = ["A", "B", "C", "D", "F"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle("Time Audit",
                            subtitle: "Account for an hour — honestly.")

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Log this hour")
                        TextField("How was this hour spent?", text: $activity)
                        Picker("Quality grade", selection: $grade) {
                            ForEach(grades, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        HStack {
                            Spacer()
                            Button("Save check-in") {
                                guard !activity.isEmpty else { return }
                                app.addCheckin(HourlyCheckin(
                                    hourStart: Date(),
                                    activity: activity,
                                    qualityGrade: grade,
                                    gradeRationale: "Self-graded (V0).",
                                    userConfirmed: true))
                                activity = ""
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(activity.isEmpty)
                        }
                    }
                }

                if !app.checkins.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Logged hours")
                            ForEach(app.checkins.prefix(12)) { checkin in
                                HStack {
                                    Text(checkin.qualityGrade)
                                        .font(.callout.weight(.bold).monospaced())
                                        .frame(width: 28)
                                    Text(checkin.activity).font(.callout)
                                    Spacer()
                                    Text(checkin.hourStart.formatted(date: .omitted, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                ComingSoonNote(module: "Hourly notifications, model-proposed grading, and the daily audit")
            }
            .padding(24)
        }
    }
}
