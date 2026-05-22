import Foundation

/// Which way an action moved the user relative to their Ideal Self.
public enum AlignmentBand: String, Sendable, Codable {
    case closer, neutral, further

    public var symbol: String {
        switch self {
        case .closer:  return "▲"
        case .neutral: return "—"
        case .further: return "▼"
        }
    }
}

/// A trait name paired with its rubric weight.
public struct TraitWeight: Sendable, Hashable, Codable {
    public let trait: String
    /// 0.0 ... 1.0
    public let weight: Double

    public init(trait: String, weight: Double) {
        self.trait = trait
        self.weight = weight
    }
}

/// Blended Ideal Self scoring.
///
/// Combines a structured rubric computation with qualitative bands. The model
/// supplies per-trait impact ratings in `-1.0 ... 1.0`; this computes the
/// weighted numeric score and the band the UI displays.
public enum IdealSelfScoring {

    /// Clamp a value into a closed range.
    public static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        min(max(value, low), high)
    }

    /// Weighted score of a single action, in `-1.0 ... 1.0`.
    ///
    /// - Parameters:
    ///   - weights: the Ideal Self rubric.
    ///   - impacts: trait name → impact rating in `-1.0 ... 1.0`.
    public static func actionScore(weights: [TraitWeight],
                                   impacts: [String: Double]) -> Double {
        let totalWeight = weights.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        var accumulated = 0.0
        for w in weights {
            let impact = clamp(impacts[w.trait] ?? 0, -1, 1)
            accumulated += w.weight * impact
        }
        return accumulated / totalWeight
    }

    /// Map a score to its qualitative band, with a neutral dead-zone.
    public static func band(for score: Double, deadzone: Double = 0.05) -> AlignmentBand {
        if score > deadzone { return .closer }
        if score < -deadzone { return .further }
        return .neutral
    }

    /// Apply an action score to a running `0 ... 100` trajectory value.
    public static func updatedTrajectory(current: Double,
                                         actionScore: Double,
                                         rate: Double = 5.0) -> Double {
        clamp(current + actionScore * rate, 0, 100)
    }
}
