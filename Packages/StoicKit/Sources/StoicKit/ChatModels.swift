import Foundation

/// One message in the ongoing companion conversation.
public struct ChatMessage: Identifiable, Codable, Sendable, Equatable {

    public enum Role: String, Codable, Sendable {
        case user, assistant
    }

    public var id: UUID
    public var role: Role
    public var text: String
    public var date: Date

    public init(id: UUID = UUID(), role: Role, text: String, date: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.date = date
    }
}
