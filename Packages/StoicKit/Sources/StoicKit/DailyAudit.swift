import Foundation

/// Inputs for the end-of-day audit.
public struct DailyAuditInput: Sendable {
    public var hoursLogged: Int
    public var productiveHours: Int
    public var integrityScore: Int
    public var drift: Int

    public init(hoursLogged: Int,
                productiveHours: Int,
                integrityScore: Int,
                drift: Int) {
        self.hoursLogged = hoursLogged
        self.productiveHours = productiveHours
        self.integrityScore = integrityScore
        self.drift = drift
    }
}

/// Composes the end-of-day audit — a blunt retrospective on the day's hours.
public enum DailyAudit {

    public static func compose(_ input: DailyAuditInput) -> [String] {
        guard input.hoursLogged > 0 else {
            return ["No hours logged today. You cannot audit what you did not record."]
        }

        var lines: [String] = []
        let unproductive = max(0, input.hoursLogged - input.productiveHours)
        let ratio = Int((Double(input.productiveHours) / Double(input.hoursLogged) * 100).rounded())

        let hourWord = input.hoursLogged == 1 ? "hour" : "hours"
        lines.append("\(input.hoursLogged) \(hourWord) logged — \(input.productiveHours) productive, \(unproductive) unproductive (\(ratio)%).")

        if ratio < 50 {
            lines.append("Most of your tracked day leaked. That is the headline — not the work you did do.")
        } else if ratio < 75 {
            lines.append("A passable day, not a sharp one. Passable compounds into average.")
        } else {
            lines.append("A sharp day. This is the standard — hold it.")
        }

        lines.append("Constitution stands at \(input.integrityScore) integrity, \(input.drift) drift.")
        return lines
    }
}
