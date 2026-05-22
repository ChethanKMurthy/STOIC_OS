import Foundation

/// Which way an action moved the user relative to their Constitution.
public enum AlignmentBand: String, Sendable, Codable {
    case closer, neutral, further

    public var symbol: String {
        switch self {
        case .closer:  return "\u{25B2}"
        case .neutral: return "\u{2014}"
        case .further: return "\u{25BC}"
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

/// Numeric Constitution scoring.
///
/// Produces the Integrity Score, drift, per-action scores, and bands — the
/// truthful instrumentation behind the Constitution.
public enum ConstitutionScoring {

    /// Clamp a value into a closed range.
    public static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        min(max(value, low), high)
    }

    /// Weighted alignment of current vs target levels across the rubric, 0 ... 100.
    public static func integrityScore(traits: [ConstitutionTrait]) -> Int {
        let totalWeight = traits.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        var accumulated = 0.0
        for trait in traits {
            let ratio = trait.targetLevel > 0
                ? Double(trait.currentLevel) / Double(trait.targetLevel)
                : 1.0
            accumulated += trait.weight * min(ratio, 1.0)
        }
        return Int((accumulated / totalWeight * 100).rounded())
    }

    /// Measured divergence from the Constitution, 0 ... 100 (0 = fully aligned).
    public static func drift(traits: [ConstitutionTrait]) -> Int {
        100 - integrityScore(traits: traits)
    }

    /// Apply a behavioural nudge to every trait's current level — a decision
    /// verdict or a logged hour moving the Constitution. Clamped to 0 ... 100.
    public static func nudged(_ traits: [ConstitutionTrait], by delta: Int) -> [ConstitutionTrait] {
        traits.map { trait in
            var updated = trait
            updated.currentLevel = max(0, min(100, updated.currentLevel + delta))
            return updated
        }
    }

    /// Weighted score of a single action, in `-1.0 ... 1.0`.
    ///
    /// - Parameters:
    ///   - weights: the Constitution rubric.
    ///   - impacts: trait name -> impact rating in `-1.0 ... 1.0`.
    public static func actionScore(weights: [TraitWeight],
                                   impacts: [String: Double]) -> Double {
        let totalWeight = weights.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        var accumulated = 0.0
        for weight in weights {
            let impact = clamp(impacts[weight.trait] ?? 0, -1, 1)
            accumulated += weight.weight * impact
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
