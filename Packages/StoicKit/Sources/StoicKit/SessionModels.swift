import Foundation

/// The structured output of a decision session — the contract the reasoning
/// model must emit as JSON, decoded straight into these types.
public struct DecisionOutput: Codable, Sendable, Equatable {
    public var realQuestion: String
    public var options: [DecisionOption]
    public var recommendation: Recommendation
    public var steps: [String]
    public var consequences: Consequences
    public var diplomaticApproach: String
    public var counterArgument: String
    public var namedRationalization: String?
    public var constitutionImpact: ConstitutionImpact
    public var dontDoThis: [String]

    public init(realQuestion: String,
                options: [DecisionOption],
                recommendation: Recommendation,
                steps: [String],
                consequences: Consequences,
                diplomaticApproach: String,
                counterArgument: String,
                namedRationalization: String?,
                constitutionImpact: ConstitutionImpact,
                dontDoThis: [String]) {
        self.realQuestion = realQuestion
        self.options = options
        self.recommendation = recommendation
        self.steps = steps
        self.consequences = consequences
        self.diplomaticApproach = diplomaticApproach
        self.counterArgument = counterArgument
        self.namedRationalization = namedRationalization
        self.constitutionImpact = constitutionImpact
        self.dontDoThis = dontDoThis
    }
}

public struct DecisionOption: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var label: String
    public var assessment: String
    public var blocked: Bool

    private enum CodingKeys: String, CodingKey { case label, assessment, blocked }

    public init(label: String, assessment: String, blocked: Bool = false) {
        self.id = UUID()
        self.label = label
        self.assessment = assessment
        self.blocked = blocked
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.label = try c.decode(String.self, forKey: .label)
        self.assessment = try c.decode(String.self, forKey: .assessment)
        self.blocked = (try? c.decode(Bool.self, forKey: .blocked)) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(label, forKey: .label)
        try c.encode(assessment, forKey: .assessment)
        try c.encode(blocked, forKey: .blocked)
    }
}

public struct Recommendation: Codable, Sendable, Equatable {
    public var choice: String
    public var condition: String?

    public init(choice: String, condition: String? = nil) {
        self.choice = choice
        self.condition = condition
    }
}

/// The three consequence dimensions, produced in a single reasoning pass.
public struct Consequences: Codable, Sendable, Equatable {
    public var mentalHealth: String
    public var character: String
    public var identity: String

    public init(mentalHealth: String, character: String, identity: String) {
        self.mentalHealth = mentalHealth
        self.character = character
        self.identity = identity
    }
}

public struct ConstitutionImpact: Codable, Sendable, Equatable {
    /// "closer", "neutral", or "further".
    public var direction: String
    public var summary: String

    public init(direction: String, summary: String) {
        self.direction = direction
        self.summary = summary
    }
}

public enum SessionError: Error, Sendable, LocalizedError {
    case emptyModelOutput
    case malformedJSON(String)

    public var errorDescription: String? {
        switch self {
        case .emptyModelOutput:
            return "The model returned no output."
        case .malformedJSON(let detail):
            return "Could not parse the model's response: \(detail)"
        }
    }
}
