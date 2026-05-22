import Foundation

// MARK: - Muscle groups

public enum MuscleGroup: String, Codable, Sendable, CaseIterable, Identifiable {
    case chest, back, shoulders, legs, arms, core

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .chest:     return "Chest"
        case .back:      return "Back"
        case .shoulders: return "Shoulders"
        case .legs:      return "Legs"
        case .arms:      return "Arms"
        case .core:      return "Core"
        }
    }
}

// MARK: - Workout models

/// One working set — a weight and a rep count.
public struct WorkoutSet: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var weightKg: Double
    public var reps: Int

    public init(id: UUID = UUID(), weightKg: Double, reps: Int) {
        self.id = id
        self.weightKg = weightKg
        self.reps = reps
    }
}

/// An exercise within a session, with its sets.
public struct LoggedExercise: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var name: String
    public var muscle: MuscleGroup
    public var sets: [WorkoutSet]

    public init(id: UUID = UUID(), name: String, muscle: MuscleGroup, sets: [WorkoutSet] = []) {
        self.id = id
        self.name = name
        self.muscle = muscle
        self.sets = sets
    }
}

/// A complete training session.
public struct WorkoutSession: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var date: Date
    public var exercises: [LoggedExercise]
    public var durationMinutes: Int
    public var notes: String

    public init(id: UUID = UUID(),
                date: Date = Date(),
                exercises: [LoggedExercise],
                durationMinutes: Int = 60,
                notes: String = "") {
        self.id = id
        self.date = date
        self.exercises = exercises
        self.durationMinutes = durationMinutes
        self.notes = notes
    }

    public var totalVolumeKg: Double {
        exercises.flatMap(\.sets).reduce(0) { $0 + $1.weightKg * Double($1.reps) }
    }

    public var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
}

/// A dated body-weight reading.
public struct BodyWeightEntry: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var date: Date
    public var weightKg: Double

    public init(id: UUID = UUID(), date: Date = Date(), weightKg: Double) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
    }
}

// MARK: - Exercise library

public struct Exercise: Identifiable, Sendable, Hashable {
    public let name: String
    public let muscle: MuscleGroup
    public var id: String { name }

    public init(name: String, muscle: MuscleGroup) {
        self.name = name
        self.muscle = muscle
    }
}

/// A built-in catalogue of exercises, used for recommendations by body part.
public enum ExerciseLibrary {
    public static let all: [Exercise] = [
        .init(name: "Barbell Bench Press", muscle: .chest),
        .init(name: "Incline Dumbbell Press", muscle: .chest),
        .init(name: "Chest Fly", muscle: .chest),
        .init(name: "Cable Crossover", muscle: .chest),
        .init(name: "Push-up", muscle: .chest),
        .init(name: "Dips", muscle: .chest),

        .init(name: "Deadlift", muscle: .back),
        .init(name: "Pull-up", muscle: .back),
        .init(name: "Bent-over Row", muscle: .back),
        .init(name: "Lat Pulldown", muscle: .back),
        .init(name: "Seated Cable Row", muscle: .back),
        .init(name: "Face Pull", muscle: .back),

        .init(name: "Overhead Press", muscle: .shoulders),
        .init(name: "Dumbbell Shoulder Press", muscle: .shoulders),
        .init(name: "Lateral Raise", muscle: .shoulders),
        .init(name: "Front Raise", muscle: .shoulders),
        .init(name: "Rear Delt Fly", muscle: .shoulders),
        .init(name: "Shrug", muscle: .shoulders),

        .init(name: "Back Squat", muscle: .legs),
        .init(name: "Front Squat", muscle: .legs),
        .init(name: "Romanian Deadlift", muscle: .legs),
        .init(name: "Leg Press", muscle: .legs),
        .init(name: "Walking Lunge", muscle: .legs),
        .init(name: "Leg Curl", muscle: .legs),
        .init(name: "Calf Raise", muscle: .legs),

        .init(name: "Barbell Curl", muscle: .arms),
        .init(name: "Dumbbell Curl", muscle: .arms),
        .init(name: "Hammer Curl", muscle: .arms),
        .init(name: "Triceps Pushdown", muscle: .arms),
        .init(name: "Skull Crusher", muscle: .arms),
        .init(name: "Close-grip Bench Press", muscle: .arms),

        .init(name: "Plank", muscle: .core),
        .init(name: "Hanging Leg Raise", muscle: .core),
        .init(name: "Cable Crunch", muscle: .core),
        .init(name: "Russian Twist", muscle: .core),
        .init(name: "Ab Wheel Rollout", muscle: .core),
    ]

    public static func forMuscle(_ muscle: MuscleGroup) -> [Exercise] {
        all.filter { $0.muscle == muscle }
    }
}

// MARK: - Training math

public enum GymMath {

    /// Epley estimated one-rep max.
    public static func oneRepMax(weightKg: Double, reps: Int) -> Double {
        guard reps > 0, weightKg > 0 else { return 0 }
        if reps == 1 { return weightKg }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }

    /// Rough calories burned — a MET model for resistance training.
    public static func estimatedCalories(durationMinutes: Int, bodyWeightKg: Double) -> Int {
        guard durationMinutes > 0, bodyWeightKg > 0 else { return 0 }
        let met = 5.5
        let perMinute = met * 3.5 * bodyWeightKg / 200.0
        return Int((perMinute * Double(durationMinutes)).rounded())
    }

    /// Consecutive-day workout streak, counting back from today. The streak
    /// stays alive on a day not yet trained, as long as yesterday was.
    public static func currentStreak(workoutDates: [Date], now: Date = Date()) -> Int {
        let calendar = Calendar.current
        let days = Set(workoutDates.map { calendar.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: now)
        if !days.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }
}
