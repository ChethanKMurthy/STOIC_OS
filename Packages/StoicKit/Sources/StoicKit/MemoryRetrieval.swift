import Foundation

/// Ranks past decisions by relevance to a new situation — keyword overlap
/// fused with recency via Reciprocal Rank Fusion.
///
/// The reasoning engine uses the result as grounding, so advice draws on the
/// user's own history rather than starting cold each time.
public enum MemoryRetrieval {

    public static func relevant(to situation: String,
                                from decisions: [DecisionRecord],
                                limit: Int = 4) -> [DecisionRecord] {
        guard !decisions.isEmpty else { return [] }

        let queryTerms = terms(of: situation)

        let byKeyword: [UUID] = decisions
            .map { (id: $0.id, score: queryTerms.intersection(terms(of: $0.situation)).count) }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .map { $0.id }

        let byRecency: [UUID] = decisions
            .sorted { $0.createdAt > $1.createdAt }
            .map { $0.id }

        let fused = RetrievalFusion.fuse([byKeyword, byRecency], limit: limit)
        let byId = Dictionary(decisions.map { ($0.id, $0) },
                              uniquingKeysWith: { first, _ in first })
        return fused.compactMap { byId[$0] }
    }

    /// Significant lowercased word stems from a piece of text.
    private static func terms(of text: String) -> Set<String> {
        Set(text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 3 })
    }
}
