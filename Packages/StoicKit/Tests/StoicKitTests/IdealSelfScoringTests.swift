import XCTest
@testable import StoicKit

final class IdealSelfScoringTests: XCTestCase {

    private let rubric: [TraitWeight] = [
        .init(trait: "Composure", weight: 1.0),
        .init(trait: "Integrity", weight: 1.0),
        .init(trait: "Discipline", weight: 0.5)
    ]

    func testPositiveActionScoresCloser() {
        let score = IdealSelfScoring.actionScore(
            weights: rubric,
            impacts: ["Composure": 0.8, "Integrity": 0.6, "Discipline": 0.4]
        )
        XCTAssertGreaterThan(score, 0)
        XCTAssertEqual(IdealSelfScoring.band(for: score), .closer)
    }

    func testNegativeActionScoresFurther() {
        let score = IdealSelfScoring.actionScore(
            weights: rubric,
            impacts: ["Discipline": -1.0]
        )
        XCTAssertLessThan(score, 0)
        XCTAssertEqual(IdealSelfScoring.band(for: score), .further)
    }

    func testEmptyRubricIsNeutral() {
        let score = IdealSelfScoring.actionScore(weights: [], impacts: ["X": 1.0])
        XCTAssertEqual(score, 0)
        XCTAssertEqual(IdealSelfScoring.band(for: score), .neutral)
    }

    func testWeightingFavoursHeavierTraits() {
        let score = IdealSelfScoring.actionScore(
            weights: [.init(trait: "Big", weight: 1.0),
                      .init(trait: "Small", weight: 0.1)],
            impacts: ["Big": 1.0, "Small": -1.0]
        )
        XCTAssertGreaterThan(score, 0, "Heavier trait should dominate the score")
    }

    func testImpactIsClampedToUnitRange() {
        let clamped = IdealSelfScoring.actionScore(
            weights: [.init(trait: "T", weight: 1.0)],
            impacts: ["T": 9.0]
        )
        XCTAssertEqual(clamped, 1.0, accuracy: 0.0001)
    }

    func testTrajectoryStaysWithinBounds() {
        XCTAssertEqual(IdealSelfScoring.updatedTrajectory(current: 99, actionScore: 1.0), 100)
        XCTAssertEqual(IdealSelfScoring.updatedTrajectory(current: 1, actionScore: -1.0), 0)
    }
}
