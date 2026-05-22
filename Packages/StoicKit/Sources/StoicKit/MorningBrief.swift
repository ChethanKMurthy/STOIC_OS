import Foundation

/// Inputs the morning brief fuses into a single readout.
public struct BriefInput: Sendable {
    public var integrityScore: Int
    public var drift: Int
    public var recoveryPercent: Int?
    public var productiveRatioPercent: Int?
    public var pendingOutcomes: Int
    public var todayBlockCount: Int

    public init(integrityScore: Int,
                drift: Int,
                recoveryPercent: Int?,
                productiveRatioPercent: Int?,
                pendingOutcomes: Int,
                todayBlockCount: Int) {
        self.integrityScore = integrityScore
        self.drift = drift
        self.recoveryPercent = recoveryPercent
        self.productiveRatioPercent = productiveRatioPercent
        self.pendingOutcomes = pendingOutcomes
        self.todayBlockCount = todayBlockCount
    }
}

/// Composes a blunt daily readout in the product's voice.
///
/// Deterministic — no model required, so it is instant and works offline. It
/// fuses physiology, identity, time, and open loops into the shape of the day.
public enum MorningBrief {

    public static func compose(_ input: BriefInput) -> [String] {
        var lines: [String] = []

        if let recovery = input.recoveryPercent {
            switch recovery {
            case 67...:
                lines.append("Recovery \(recovery)%. The body is ready — take on the demanding work today.")
            case 34..<67:
                lines.append("Recovery \(recovery)%. Moderate. Decide and train, but do not overreach.")
            default:
                lines.append("Recovery \(recovery)%. Depleted. Protect recovery; defer the heavy decisions.")
            }
        }

        if input.drift > 50 {
            lines.append("Integrity \(input.integrityScore), drift \(input.drift). You are well off the person you defined — this is the gap to close today.")
        } else if input.drift > 25 {
            lines.append("Integrity \(input.integrityScore), drift \(input.drift). Holding, not closing.")
        } else {
            lines.append("Integrity \(input.integrityScore), drift \(input.drift). Close to your Constitution — hold the line.")
        }

        if let ratio = input.productiveRatioPercent {
            if ratio < 50 {
                lines.append("Logged hours are \(ratio)% productive. More than half your tracked time is leaking.")
            } else {
                lines.append("Logged hours are \(ratio)% productive.")
            }
        }

        if input.todayBlockCount == 0 {
            lines.append("Nothing on the timetable. An unplanned day is a day that plans you.")
        } else {
            lines.append("\(input.todayBlockCount) block\(input.todayBlockCount == 1 ? "" : "s") scheduled today.")
        }

        if input.pendingOutcomes > 0 {
            let plural = input.pendingOutcomes == 1 ? "" : "s"
            lines.append("\(input.pendingOutcomes) past decision\(plural) still awaiting an outcome. Close the loop — log what happened.")
        }

        return lines
    }
}
