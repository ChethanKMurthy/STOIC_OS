import XCTest
@testable import StoicKit

final class SafetyCheckTests: XCTestCase {

    func testDetectsCrisisPhrases() {
        XCTAssertTrue(SafetyCheck.isCrisis("I want to kill myself"))
        XCTAssertTrue(SafetyCheck.isCrisis("there is No Reason To Live anymore"))
        XCTAssertTrue(SafetyCheck.isCrisis("I keep thinking about suicide"))
    }

    func testIgnoresOrdinaryText() {
        XCTAssertFalse(SafetyCheck.isCrisis("Should I take the new job?"))
        XCTAssertFalse(SafetyCheck.isCrisis("This deadline is killing me at work"))
        XCTAssertFalse(SafetyCheck.isCrisis("How do I handle a hard conversation?"))
    }

    func testResourcesAndMessagePresent() {
        XCTAssertFalse(SafetyCheck.resources.isEmpty)
        XCTAssertFalse(SafetyCheck.supportiveMessage.isEmpty)
    }
}
