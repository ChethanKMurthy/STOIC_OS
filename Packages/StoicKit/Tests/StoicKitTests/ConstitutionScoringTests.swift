import XCTest
@testable import StoicKit

final class ConstitutionScoringTests: XCTestCase {

    private let rubric: [TraitWeight] = [
        .init(trait: "Composure", weight: 1.0),
        .init(trait: "Integrity", weight: 1.0),
        .init(trait: "Discipline", weight: 0.5)
    ]

    // MARK: - Action scoring

    func testPositiveActionScoresCloser() {
        let score = ConstitutionScoring.actionScore(
            weights: rubric,
            impacts: ["Composure": 0.8, "Integrity": 0.6, "Discipline": 0.4]
        )
        XCTAssertGreaterThan(score, 0)
        XCTAssertEqual(ConstitutionScoring.band(for: score), .closer)
    }

    func testNegativeActionScoresFurther() {
        let score = ConstitutionScoring.actionScore(
            weights: rubric,
            impacts: ["Discipline": -1.0]
        )
        XCTAssertLessThan(score, 0)
        XCTAssertEqual(ConstitutionScoring.band(for: score), .further)
    }

    func testEmptyRubricIsNeutral() {
        let score = ConstitutionScoring.actionScore(weights: [], impacts: ["X": 1.0])
        XCTAssertEqual(score, 0)
        XCTAssertEqual(ConstitutionScoring.band(for: score), .neutral)
    }

    func testImpactIsClampedToUnitRange() {
        let clamped = ConstitutionScoring.actionScore(
            weights: [.init(trait: "T", weight: 1.0)],
            impacts: ["T": 9.0]
        )
        XCTAssertEqual(clamped, 1.0, accuracy: 0.0001)
    }

    func testTrajectoryStaysWithinBounds() {
        XCTAssertEqual(ConstitutionScoring.updatedTrajectory(current: 99, actionScore: 1.0), 100)
        XCTAssertEqual(ConstitutionScoring.updatedTrajectory(current: 1, actionScore: -1.0), 0)
    }

    // MARK: - Integrity score & drift

    func testIntegrityScoreFullAlignment() {
        let traits = [ConstitutionTrait(name: "A", weight: 1, currentLevel: 80, targetLevel: 80)]
        XCTAssertEqual(ConstitutionScoring.integrityScore(traits: traits), 100)
    }

    func testIntegrityScoreHalfway() {
        let traits = [ConstitutionTrait(name: "A", weight: 1, currentLevel: 40, targetLevel: 80)]
        XCTAssertEqual(ConstitutionScoring.integrityScore(traits: traits), 50)
    }

    func testIntegrityScoreCapsWhenCurrentExceedsTarget() {
        let traits = [ConstitutionTrait(name: "A", weight: 1, currentLevel: 100, targetLevel: 50)]
        XCTAssertEqual(ConstitutionScoring.integrityScore(traits: traits), 100)
    }

    func testDriftIsInverseOfIntegrity() {
        let traits = [ConstitutionTrait(name: "A", weight: 1, currentLevel: 40, targetLevel: 80)]
        XCTAssertEqual(ConstitutionScoring.drift(traits: traits), 50)
    }

    func testEmptyConstitutionScoresZero() {
        XCTAssertEqual(ConstitutionScoring.integrityScore(traits: []), 0)
    }

    func testWeightingFavoursHeavierTraits() {
        let traits = [
            ConstitutionTrait(name: "Big", weight: 1.0, currentLevel: 90, targetLevel: 90),
            ConstitutionTrait(name: "Small", weight: 0.1, currentLevel: 0, targetLevel: 90)
        ]
        XCTAssertGreaterThan(ConstitutionScoring.integrityScore(traits: traits), 80)
    }
}
