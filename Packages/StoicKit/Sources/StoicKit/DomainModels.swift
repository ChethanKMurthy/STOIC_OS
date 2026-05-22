import Foundation

// MARK: - Ideal Self

/// One weighted trait of the user's designed Ideal Self.
public struct IdealSelfTrait: Identifiable, Sendable, Hashable, Codable {
    public var id: UUID
    public var name: String
    /// Relative importance, 0.0 ... 1.0.
    public var weight: Double
    /// Aspirational level, 1 ... 5.
    public var targetLevel: Int

    public init(id: UUID = UUID(), name: String, weight: Double, targetLevel: Int = 4) {
        self.id = id
        self.name = name
        self.weight = weight
        self.targetLevel = targetLevel
    }
}

/// The user-designed "ideal individual" — hybrid free-text narrative + rubric.
public struct IdealSelfModel: Identifiable, Sendable, Codable {
    public var id: UUID
    public var version: Int
    public var narrative: String
    public var traits: [IdealSelfTrait]
    public var createdAt: Date

    public init(id: UUID = UUID(),
                version: Int = 1,
                narrative: String = "",
                traits: [IdealSelfTrait] = [],
                createdAt: Date = Date()) {
        self.id = id
        self.version = version
        self.narrative = narrative
        self.traits = traits
        self.createdAt = createdAt
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

    public init(id: UUID = UUID(),
                title: String,
                timeline: String = "",
                baseline: String = "",
                progress: Double = 0,
                createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.timeline = timeline
        self.baseline = baseline
        self.progress = progress
        self.createdAt = createdAt
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

// MARK: - Time Audit

public struct HourlyCheckin: Identifiable, Sendable, Codable {
    public var id: UUID
    public var hourStart: Date
    public var activity: String
    /// e.g. "A", "B+", "C" — proposed by the model, confirmed by the user.
    public var qualityGrade: String
    public var gradeRationale: String
    public var userConfirmed: Bool

    public init(id: UUID = UUID(),
                hourStart: Date,
                activity: String,
                qualityGrade: String = "",
                gradeRationale: String = "",
                userConfirmed: Bool = false) {
        self.id = id
        self.hourStart = hourStart
        self.activity = activity
        self.qualityGrade = qualityGrade
        self.gradeRationale = gradeRationale
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
