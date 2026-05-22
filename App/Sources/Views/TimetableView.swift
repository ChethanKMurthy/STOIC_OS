import SwiftUI

/// Daily timetable screen.
/// V0 renders the layout; the planner and calendar sync are planned.
struct TimetableView: View {
    private let sample: [(String, String, String)] = [
        ("09:00", "Deep work — focused block", "Goal"),
        ("11:00", "Reading", "Activity"),
        ("14:00", "1:1 prep", "Corp Navigator"),
        ("16:00", "Exercise", "Goal")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle("Timetable",
                            subtitle: Date.now.formatted(date: .abbreviated, time: .omitted))

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Today")
                        ForEach(sample, id: \.0) { row in
                            HStack(spacing: 12) {
                                Text(row.0)
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 52, alignment: .leading)
                                Rectangle().frame(width: 3).foregroundStyle(.tint)
                                Text(row.1).font(.callout)
                                Spacer()
                                Text(row.2)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                ComingSoonNote(module: "Daily timetable generation, re-planning, and calendar sync")
            }
            .padding(24)
        }
    }
}
