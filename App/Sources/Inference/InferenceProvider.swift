import Foundation

/// The seam between the reasoning engine and a concrete inference backend.
///
/// V0 ships one implementation — ``LocalLLMProvider`` (real on-device MLX).
/// This protocol is also the boundary where the inference engine can later be
/// extracted into its own service.
protocol InferenceProvider: Sendable {

    /// Load the model if needed, reporting download/load progress (0...1).
    func prepare(onProgress: @escaping @Sendable (Double) -> Void) async throws

    /// Run a completion. `onToken` is called with each streamed text delta;
    /// the full text is returned.
    func complete(system: String,
                  user: String,
                  onToken: @escaping @Sendable (String) -> Void) async throws -> String
}

enum InferenceError: LocalizedError {
    case modelNotLoaded
    case emptyOutput

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "The local model is not loaded."
        case .emptyOutput:    return "The model produced no output."
        }
    }
}
