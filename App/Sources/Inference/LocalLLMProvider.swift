import Foundation
import MLXLLM
import MLXLMCommon

/// Real on-device inference via MLX (mlx-swift-examples, pinned to 2.29.1).
///
/// All MLX coupling lives in this one file, behind ``InferenceProvider``.
/// On first use the model is downloaded from Hugging Face once, then cached
/// locally; every run after that is fully offline.
actor LocalLLMProvider: InferenceProvider {

    private let modelID: String
    private var container: ModelContainer?

    init(modelID: String) {
        self.modelID = modelID
    }

    func prepare(onProgress: @escaping @Sendable (Double) -> Void) async throws {
        if container != nil {
            onProgress(1.0)
            return
        }
        // Static reference so the LLM model factory (resolved via the ObjC
        // runtime by loadModelContainer) is linked in and registered.
        _ = LLMRegistry.shared
        let loaded = try await loadModelContainer(id: modelID) { progress in
            onProgress(progress.fractionCompleted)
        }
        container = loaded
        onProgress(1.0)
    }

    func complete(system: String,
                  user: String,
                  onToken: @escaping @Sendable (String) -> Void) async throws -> String {

        if container == nil {
            try await prepare { _ in }
        }
        guard let container else { throw InferenceError.modelNotLoaded }

        // Deterministic decoding — temperature 0.
        let parameters = GenerateParameters(maxTokens: 1600, temperature: 0)
        let session = ChatSession(container, generateParameters: parameters)

        // ChatSession resets to a single user turn per call, so the system
        // preamble is folded into the prompt.
        let prompt = system + "\n\n---\n\n" + user

        var full = ""
        for try await chunk in session.streamResponse(to: prompt) {
            full += chunk
            onToken(chunk)
        }

        guard !full.isEmpty else { throw InferenceError.emptyOutput }
        return full
    }
}
