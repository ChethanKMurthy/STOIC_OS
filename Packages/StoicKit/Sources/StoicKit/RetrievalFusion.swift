import Foundation

/// Reciprocal Rank Fusion for hybrid memory retrieval.
///
/// Merges several independently-ranked result lists (semantic, keyword,
/// recency) into one ranking. Deterministic: ties break by first appearance.
public enum RetrievalFusion {

    /// Fuse ranked lists into a single ranking, best first.
    ///
    /// - Parameters:
    ///   - lists: ranked ID lists, each best-first.
    ///   - k: RRF damping constant (60 is the standard default).
    public static func fuse<ID: Hashable & Sendable>(_ lists: [[ID]],
                                                      k: Double = 60) -> [ID] {
        var score: [ID: Double] = [:]
        var firstSeen: [ID: Int] = [:]
        var order = 0

        for list in lists {
            for (index, id) in list.enumerated() {
                score[id, default: 0] += 1.0 / (k + Double(index + 1))
                if firstSeen[id] == nil {
                    firstSeen[id] = order
                    order += 1
                }
            }
        }

        return score.keys.sorted { lhs, rhs in
            let ls = score[lhs] ?? 0
            let rs = score[rhs] ?? 0
            if ls != rs { return ls > rs }
            return (firstSeen[lhs] ?? 0) < (firstSeen[rhs] ?? 0)
        }
    }

    /// Fuse and trim to a maximum count (the context-window budget).
    public static func fuse<ID: Hashable & Sendable>(_ lists: [[ID]],
                                                      k: Double = 60,
                                                      limit: Int) -> [ID] {
        Array(fuse(lists, k: k).prefix(max(0, limit)))
    }
}
