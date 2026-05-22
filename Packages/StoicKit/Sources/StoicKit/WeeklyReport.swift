import Foundation

/// One section of the weekly drift report.
public struct ReportSection: Identifiable, Sendable, Equatable {
    public let id: Int
    public let heading: String
    public let body: String

    public init(id: Int, heading: String, body: String) {
        self.id = id
        self.heading = heading
        self.body = body
    }
}

/// Inputs for the weekly drift report.
public struct WeeklyReportInput: Sendable {
    public var integrityNow: Int
    public var integrityWeekAgo: Int?
    public var drift: Int
    public var hoursLogged: Int
    public var productiveHours: Int
    public var decisionsMade: Int
    public var outcomesLogged: Int

    public init(integrityNow: Int,
                integrityWeekAgo: Int?,
                drift: Int,
                hoursLogged: Int,
                productiveHours: Int,
                decisionsMade: Int,
                outcomesLogged: Int) {
        self.integrityNow = integrityNow
        self.integrityWeekAgo = integrityWeekAgo
        self.drift = drift
        self.hoursLogged = hoursLogged
        self.productiveHours = productiveHours
        self.decisionsMade = decisionsMade
        self.outcomesLogged = outcomesLogged
    }
}

/// Composes the weekly drift report — the document that does not flatter.
public enum WeeklyReport {

    public static func compose(_ input: WeeklyReportInput) -> [ReportSection] {
        var sections: [ReportSection] = []

        var integrity = "Your Constitution stands at \(input.integrityNow) integrity, \(input.drift) drift."
        if let was = input.integrityWeekAgo {
            let delta = input.integrityNow - was
            if delta > 2 {
                integrity += " Up \(delta) over the week — you closed ground on the person you defined."
            } else if delta < -2 {
                integrity += " Down \(-delta) over the week. You drifted. That is the fact, not a feeling."
            } else {
                integrity += " Essentially flat over the week. Flat is not holding — it is stalling."
            }
        }
        sections.append(ReportSection(id: 0, heading: "Integrity", body: integrity))

        let time: String
        if input.hoursLogged == 0 {
            time = "You logged no hours this week. A week you did not measure is a week you cannot answer for."
        } else {
            let ratio = Int((Double(input.productiveHours) / Double(input.hoursLogged) * 100).rounded())
            time = "\(input.hoursLogged) hours logged, \(ratio)% productive. "
                + (ratio < 60
                   ? "Most of your measured time did not serve you."
                   : "A defensible week on time.")
        }
        sections.append(ReportSection(id: 1, heading: "Time", body: time))

        let decisions: String
        if input.decisionsMade == 0 {
            decisions = "No decisions were run through STOIC OS this week."
        } else {
            decisions = "\(input.decisionsMade) decisions made, \(input.outcomesLogged) with a recorded outcome. "
                + (input.outcomesLogged < input.decisionsMade
                   ? "Decisions without outcomes teach you nothing. Close the loop."
                   : "Every decision closed — this is how the system learns you.")
        }
        sections.append(ReportSection(id: 2, heading: "Decisions", body: decisions))

        let verdict: String
        if input.drift > 50 {
            verdict = "You are well off the person you said you would be. This is the week to decide whether that person was ever real, or change what you are doing."
        } else if input.drift > 25 {
            verdict = "You are holding a gap. Holding a gap, week after week, is how a stated identity quietly becomes a lie. Close it."
        } else {
            verdict = "You are close to your Constitution. The work now is simply not to drift back."
        }
        sections.append(ReportSection(id: 3, heading: "The verdict", body: verdict))

        return sections
    }
}
