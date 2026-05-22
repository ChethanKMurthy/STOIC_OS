import Foundation
import StoicKit

/// Events streamed from a reasoning session to the UI.
enum ReasoningEvent: Sendable {
    case modelLoading(Double)
    case token(String)
    case finished(DecisionOutput)
    case failed(String)
}

/// Events streamed from a goal-decomposition session to the UI.
enum PlanEvent: Sendable {
    case modelLoading(Double)
    case finished(GoalPlanOutput)
    case failed(String)
}

/// Orchestrates a decision session.
///
/// V0 implements a simplified loop: build prompt → stream completion → extract
/// and decode structured JSON. A fuller agentic loop (plan → retrieve →
/// critique → screen) is planned.
final class ReasoningEngine: Sendable {

    private let provider: any InferenceProvider

    init(provider: any InferenceProvider) {
        self.provider = provider
    }

    /// Run a decision session, streaming progress and the final result.
    /// `context` carries extra grounding (e.g. the user's current physiology).
    func decide(situation: String, isPast: Bool, context: [String] = []) -> AsyncStream<ReasoningEvent> {
        AsyncStream { continuation in
            let task = Task {
                do {
                    try await provider.prepare { fraction in
                        continuation.yield(.modelLoading(fraction))
                    }

                    let system = PromptBuilder.systemPreamble()
                    let user = PromptBuilder.decisionPrompt(situation: situation,
                                                            isPast: isPast,
                                                            retrievedContext: context)

                    let raw = try await provider.complete(system: system, user: user) { delta in
                        continuation.yield(.token(delta))
                    }

                    let output = try JSONExtractor.decode(DecisionOutput.self, from: raw)
                    continuation.yield(.finished(output))
                } catch is CancellationError {
                    // silent — the UI cancelled
                } catch {
                    continuation.yield(.failed(error.localizedDescription))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Decompose a goal into milestones, micro-tasks, and reading suggestions.
    func plan(goal: String, timeline: String, baseline: String) -> AsyncStream<PlanEvent> {
        AsyncStream { continuation in
            let task = Task {
                do {
                    try await provider.prepare { fraction in
                        continuation.yield(.modelLoading(fraction))
                    }
                    let system = PromptBuilder.systemPreamble()
                    let user = PromptBuilder.goalPlanPrompt(goal: goal,
                                                            timeline: timeline,
                                                            baseline: baseline)
                    let raw = try await provider.complete(system: system, user: user) { _ in }
                    let output = try JSONExtractor.decode(GoalPlanOutput.self, from: raw)
                    continuation.yield(.finished(output))
                } catch is CancellationError {
                    // silent — cancelled
                } catch {
                    continuation.yield(.failed(error.localizedDescription))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Pulls the first balanced JSON object out of model text and decodes it.
/// Models often wrap JSON in prose or fences; this is tolerant of that.
enum JSONExtractor {

    static func decode<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        guard let json = firstJSONObject(in: text) else {
            throw SessionError.malformedJSON("no JSON object found in model output")
        }
        guard let data = json.data(using: .utf8) else {
            throw SessionError.malformedJSON("could not encode extracted JSON")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw SessionError.malformedJSON(String(describing: error))
        }
    }

    /// Returns the substring of the first top-level `{ ... }`, string-aware.
    static func firstJSONObject(in text: String) -> String? {
        guard let start = text.firstIndex(of: "{") else { return nil }
        var depth = 0
        var inString = false
        var escaped = false
        var index = start

        while index < text.endIndex {
            let character = text[index]
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else {
                switch character {
                case "\"": inString = true
                case "{":  depth += 1
                case "}":
                    depth -= 1
                    if depth == 0 {
                        return String(text[start...index])
                    }
                default: break
                }
            }
            index = text.index(after: index)
        }
        return nil
    }
}
