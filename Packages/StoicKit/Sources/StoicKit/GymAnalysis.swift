import Foundation

/// Training intelligence — progressive overload, strength scoring, balance,
/// and body-weight projection. Pure functions over logged sessions.
public enum GymAnalysis {

    /// Best estimated 1RM ever recorded for an exercise.
    public static func bestOneRepMax(exercise name: String,
                                     in sessions: [WorkoutSession]) -> Double {
        var best = 0.0
        for session in sessions {
            for logged in session.exercises where logged.name == name {
                for set in logged.sets {
                    best = max(best, GymMath.oneRepMax(weightKg: set.weightKg, reps: set.reps))
                }
            }
        }
        return best
    }

    /// The heaviest set from the most recent session containing the exercise —
    /// used to pre-fill the logger so every session has a target to beat.
    public static func lastTopSet(exercise name: String,
                                  in sessions: [WorkoutSession]) -> WorkoutSet? {
        for session in sessions.sorted(by: { $0.date > $1.date }) {
            let sets = session.exercises.filter { $0.name == name }.flatMap(\.sets)
            if let top = sets.max(by: { $0.weightKg < $1.weightKg }) {
                return top
            }
        }
        return nil
    }

    /// Every exercise logged, with its best estimated 1RM, strongest first.
    public static func personalRecords(
        in sessions: [WorkoutSession]) -> [(exercise: String, oneRepMax: Double)] {
        var names = Set<String>()
        for session in sessions {
            for exercise in session.exercises { names.insert(exercise.name) }
        }
        return names
            .map { (exercise: $0, oneRepMax: bestOneRepMax(exercise: $0, in: sessions)) }
            .filter { $0.oneRepMax > 0 }
            .sorted { $0.oneRepMax > $1.oneRepMax }
    }

    /// Sets logged per muscle group within the last `days` days.
    public static func weeklyVolume(in sessions: [WorkoutSession],
                                    days: Int = 7,
                                    now: Date = Date()) -> [MuscleGroup: Int] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        var counts: [MuscleGroup: Int] = [:]
        for session in sessions where session.date >= cutoff {
            for logged in session.exercises {
                counts[logged.muscle, default: 0] += logged.sets.count
            }
        }
        return counts
    }

    // MARK: - Strength score

    /// 1RM-to-bodyweight standards for the main lifts.
    /// Each tier list is [novice, intermediate, advanced, elite].
    private static let standards: [String: [Double]] = [
        "Barbell Bench Press": [0.75, 1.0, 1.5, 2.0],
        "Back Squat":          [1.0, 1.5, 2.0, 2.5],
        "Deadlift":            [1.25, 1.75, 2.5, 3.0],
        "Overhead Press":      [0.5, 0.75, 1.0, 1.25],
    ]

    /// A 0...100 strength score — the user's main lifts against bodyweight
    /// standards. Nil until there is at least one logged main lift.
    public static func strengthScore(sessions: [WorkoutSession],
                                     bodyWeightKg: Double) -> Int? {
        guard bodyWeightKg > 0 else { return nil }
        var subScores: [Double] = []
        for (lift, tiers) in standards {
            let best = bestOneRepMax(exercise: lift, in: sessions)
            guard best > 0 else { continue }
            subScores.append(scoreRatio(best / bodyWeightKg, tiers: tiers))
        }
        guard !subScores.isEmpty else { return nil }
        return Int((subScores.reduce(0, +) / Double(subScores.count)).rounded())
    }

    /// Maps a bodyweight ratio onto 0...100 across the four standard tiers.
    private static func scoreRatio(_ ratio: Double, tiers: [Double]) -> Double {
        let marks = [0.0] + tiers
        let values = [0.0, 25.0, 50.0, 75.0, 100.0]
        guard let first = marks.first, let last = marks.last else { return 0 }
        if ratio <= first { return 0 }
        if ratio >= last { return 100 }
        for index in 1..<marks.count where ratio < marks[index] {
            let lower = marks[index - 1]
            let upper = marks[index]
            let fraction = (ratio - lower) / (upper - lower)
            return values[index - 1] + fraction * (values[index] - values[index - 1])
        }
        return 100
    }

    // MARK: - Body-weight projection

    /// Projects days-to-target from the body-weight trend. Nil without enough
    /// data, or when the trend is not moving toward the target.
    public static func daysToTarget(_ entries: [BodyWeightEntry], target: Double) -> Int? {
        let sorted = entries.sorted { $0.date < $1.date }
        guard sorted.count >= 2, target > 0,
              let first = sorted.first, let last = sorted.last else { return nil }
        let dayspan = last.date.timeIntervalSince(first.date) / 86_400
        guard dayspan >= 1 else { return nil }
        let ratePerDay = (last.weightKg - first.weightKg) / dayspan
        let remaining = target - last.weightKg
        guard remaining != 0 else { return 0 }
        guard ratePerDay != 0, (remaining > 0) == (ratePerDay > 0) else { return nil }
        return Int((remaining / ratePerDay).rounded())
    }
}
