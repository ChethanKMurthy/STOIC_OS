import Foundation

public enum CommitmentStatus: String, Sendable, Codable {
    case active, kept, broken
}

/// A commitment with a deadline. Breaking it — or letting it lapse — costs
/// Integrity. That stake is what makes STOIC OS an enforcer, not an advisor.
public struct Commitment: Identifiable, Sendable, Codable {
    public var id: UUID
    public var text: String
    public var deadline: Date
    public var status: CommitmentStatus
    public var createdAt: Date
    public var brokenReason: String?

    public init(id: UUID = UUID(),
                text: String,
                deadline: Date,
                status: CommitmentStatus = .active,
                createdAt: Date = Date(),
                brokenReason: String? = nil) {
        self.id = id
        self.text = text
        self.deadline = deadline
        self.status = status
        self.createdAt = createdAt
        self.brokenReason = brokenReason
    }

    public var isOverdue: Bool {
        status == .active && deadline < Date()
    }
}
