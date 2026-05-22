import Foundation

/// A milestone on the path to a goal.
public struct Milestone: Identifiable, Sendable, Codable, Equatable {
    public var id: UUID
    public var goalId: UUID
    public var title: String
    public var targetDate: String
    public var done: Bool

    public init(id: UUID = UUID(),
                goalId: UUID,
                title: String,
                targetDate: String = "",
                done: Bool = false) {
        self.id = id
        self.goalId = goalId
        self.title = title
        self.targetDate = targetDate
        self.done = done
    }
}

/// One milestone in a model-produced goal plan.
public struct PlanItem: Codable, Sendable, Equatable {
    public var title: String
    public var targetDate: String

    private enum CodingKeys: String, CodingKey { case title, targetDate }

    public init(title: String, targetDate: String = "") {
        self.title = title
        self.targetDate = targetDate
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try c.decode(String.self, forKey: .title)
        self.targetDate = (try? c.decode(String.self, forKey: .targetDate)) ?? ""
    }
}

/// The structured output of a goal-decomposition session.
public struct GoalPlanOutput: Codable, Sendable, Equatable {
    public var milestones: [PlanItem]
    public var microTasks: [String]
    public var readingAndActivities: [String]

    public init(milestones: [PlanItem],
                microTasks: [String],
                readingAndActivities: [String]) {
        self.milestones = milestones
        self.microTasks = microTasks
        self.readingAndActivities = readingAndActivities
    }
}
