import Foundation

/// A crisis support resource.
public struct SafetyResource: Sendable, Hashable {
    public let name: String
    public let contact: String

    public init(name: String, contact: String) {
        self.name = name
        self.contact = contact
    }
}

/// Acute-distress detection.
///
/// STOIC OS is a supportive reasoning companion, not a clinical service. When a
/// session shows acute distress, the product steps out of its blunt posture and
/// surfaces help resources instead of reasoning the situation through.
public enum SafetyCheck {

    private static let crisisPhrases = [
        "kill myself", "killing myself", "suicide", "suicidal",
        "end my life", "ending my life", "take my own life",
        "want to die", "wish i was dead", "wish i were dead",
        "better off dead", "no reason to live", "don't want to live",
        "do not want to live", "hurt myself", "harm myself",
        "self harm", "self-harm", "cut myself"
    ]

    /// True if the text shows acute-distress signals.
    public static func isCrisis(_ text: String) -> Bool {
        let lower = text.lowercased()
        return crisisPhrases.contains { lower.contains($0) }
    }

    public static let resources: [SafetyResource] = [
        .init(name: "US & Canada — 988 Suicide & Crisis Lifeline",
              contact: "Call or text 988"),
        .init(name: "UK & Ireland — Samaritans",
              contact: "Call 116 123, free, any time"),
        .init(name: "Find a helpline anywhere",
              contact: "findahelpline.com"),
        .init(name: "If you are in immediate danger",
              contact: "Contact your local emergency number, or someone you trust, now.")
    ]

    public static let supportiveMessage =
        "What you're describing sounds heavy, and it deserves more than a reasoning "
        + "engine. Please reach out to a person — a professional, or someone you "
        + "trust. You do not have to carry this alone."
}
