import Foundation

// MARK: - Constitution

/// One weighted, numeric trait of the user's Constitution.
public struct ConstitutionTrait: Identifiable, Sendable, Hashable, Codable {
    public var id: UUID
    public var name: String
    /// Relative importance, 0.0 ... 1.0.
    public var weight: Double
    /// Where the user is now, 0 ... 100.
    public var currentLevel: Int
    /// Where the user intends to be, 0 ... 100.
    public var targetLevel: Int

    public init(id: UUID = UUID(),
                name: String,
                weight: Double = 1.0,
                currentLevel: Int = 25,
                targetLevel: Int = 85) {
        self.id = id
        self.name = name
        self.weight = weight
        self.currentLevel = currentLevel
        self.targetLevel = targetLevel
    }
}

/// The user's Constitution — their stated identity, in their own words plus a
/// numeric rubric of traits.
public struct ConstitutionModel: Identifiable, Sendable, Codable {
    public var id: UUID
    public var version: Int
    public var narrative: String
    public var traits: [ConstitutionTrait]
    public var createdAt: Date

    public init(id: UUID = UUID(),
                version: Int = 1,
                narrative: String = "",
                traits: [ConstitutionTrait] = [],
                createdAt: Date = Date()) {
        self.id = id
        self.version = version
        self.narrative = narrative
        self.traits = traits
        self.createdAt = createdAt
    }

    /// Weighted alignment of current vs target across the rubric, 0 ... 100.
    public var integrityScore: Int {
        ConstitutionScoring.integrityScore(traits: traits)
    }

    /// Measured divergence from the Constitution, 0 ... 100.
    public var drift: Int {
        ConstitutionScoring.drift(traits: traits)
    }
}

// MARK: - Goals & Tasks

public struct Goal: Identifiable, Sendable, Codable {
    public var id: UUID
    public var title: String
    public var timeline: String
    public var baseline: String
    /// 0.0 ... 1.0
    public var progress: Double
    public var createdAt: Date
    /// Reading and activities, set when the goal is decomposed.
    public var readingSuggestions: [String]?

    public init(id: UUID = UUID(),
                title: String,
                timeline: String = "",
                baseline: String = "",
                progress: Double = 0,
                createdAt: Date = Date(),
                readingSuggestions: [String]? = nil) {
        self.id = id
        self.title = title
        self.timeline = timeline
        self.baseline = baseline
        self.progress = progress
        self.createdAt = createdAt
        self.readingSuggestions = readingSuggestions
    }
}

public enum TaskStatus: String, Sendable, Codable, CaseIterable {
    case pending, done, deferred, skipped
}

public struct MicroTask: Identifiable, Sendable, Codable {
    public var id: UUID
    public var goalId: UUID?
    public var title: String
    public var scheduledDay: Date?
    public var status: TaskStatus

    public init(id: UUID = UUID(),
                goalId: UUID? = nil,
                title: String,
                scheduledDay: Date? = nil,
                status: TaskStatus = .pending) {
        self.id = id
        self.goalId = goalId
        self.title = title
        self.scheduledDay = scheduledDay
        self.status = status
    }
}

/// A scheduled block on the daily timetable.
public struct TimeBlock: Identifiable, Sendable, Codable {
    public var id: UUID
    public var title: String
    /// Hour the block starts, 0 ... 23.
    public var startHour: Int
    /// Length in hours, >= 1.
    public var durationHours: Int
    public var done: Bool

    public init(id: UUID = UUID(),
                title: String,
                startHour: Int,
                durationHours: Int = 1,
                done: Bool = false) {
        self.id = id
        self.title = title
        self.startHour = startHour
        self.durationHours = durationHours
        self.done = done
    }
}

// MARK: - Time Audit

/// How an hour was spent. V0 grades on a two-value scale.
public enum TimeQuality: String, Sendable, Codable, CaseIterable {
    case productive
    case unproductive

    public var label: String {
        switch self {
        case .productive:   return "Productive"
        case .unproductive: return "Unproductive"
        }
    }
}

public struct HourlyCheckin: Identifiable, Sendable, Codable {
    public var id: UUID
    public var hourStart: Date
    public var activity: String
    public var quality: TimeQuality
    public var note: String
    public var userConfirmed: Bool

    public init(id: UUID = UUID(),
                hourStart: Date,
                activity: String,
                quality: TimeQuality = .productive,
                note: String = "",
                userConfirmed: Bool = false) {
        self.id = id
        self.hourStart = hourStart
        self.activity = activity
        self.quality = quality
        self.note = note
        self.userConfirmed = userConfirmed
    }
}

// MARK: - Corporate Navigator

public struct BragEntry: Identifiable, Sendable, Codable {
    public var id: UUID
    public var date: Date
    public var win: String
    public var metric: String
    public var stakeholders: String
    public var outcome: String

    public init(id: UUID = UUID(),
                date: Date = Date(),
                win: String,
                metric: String = "",
                stakeholders: String = "",
                outcome: String = "") {
        self.id = id
        self.date = date
        self.win = win
        self.metric = metric
        self.stakeholders = stakeholders
        self.outcome = outcome
    }
}

// MARK: - Decisions

/// A persisted reasoning session. `outputJSON` holds an encoded ``DecisionOutput``.
public struct DecisionRecord: Identifiable, Sendable, Codable {
    public var id: UUID
    public var createdAt: Date
    public var situation: String
    public var isPast: Bool
    public var outputJSON: String
    public var outcome: String?

    public init(id: UUID = UUID(),
                createdAt: Date = Date(),
                situation: String,
                isPast: Bool,
                outputJSON: String,
                outcome: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.situation = situation
        self.isPast = isPast
        self.outputJSON = outputJSON
        self.outcome = outcome
    }
}
