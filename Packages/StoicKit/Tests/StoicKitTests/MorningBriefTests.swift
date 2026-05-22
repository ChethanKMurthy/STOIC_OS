import XCTest
@testable import StoicKit

final class MorningBriefTests: XCTestCase {

    func testDepletedHighDriftBrief() {
        let lines = MorningBrief.compose(BriefInput(
            integrityScore: 38, drift: 62, recoveryPercent: 24,
            productiveRatioPercent: 41, pendingOutcomes: 2, todayBlockCount: 0))
        XCTAssertFalse(lines.isEmpty)
        XCTAssertTrue(lines.contains { $0.contains("Depleted") })
        XCTAssertTrue(lines.contains { $0.contains("gap to close") })
        XCTAssertTrue(lines.contains { $0.contains("leaking") })
        XCTAssertTrue(lines.contains { $0.contains("awaiting an outcome") })
    }

    func testOmitsWhoopAndRatioWhenNil() {
        let lines = MorningBrief.compose(BriefInput(
            integrityScore: 82, drift: 18, recoveryPercent: nil,
            productiveRatioPercent: nil, pendingOutcomes: 0, todayBlockCount: 3))
        XCTAssertFalse(lines.contains { $0.contains("Recovery") })
        XCTAssertFalse(lines.contains { $0.contains("productive") })
        XCTAssertTrue(lines.contains { $0.contains("hold the line") })
        XCTAssertTrue(lines.contains { $0.contains("3 blocks") })
    }

    func testSinglePendingOutcomeIsSingular() {
        let lines = MorningBrief.compose(BriefInput(
            integrityScore: 50, drift: 50, recoveryPercent: nil,
            productiveRatioPercent: nil, pendingOutcomes: 1, todayBlockCount: 1))
        XCTAssertTrue(lines.contains { $0.contains("1 past decision still") })
        XCTAssertTrue(lines.contains { $0.contains("1 block ") })
    }
}
