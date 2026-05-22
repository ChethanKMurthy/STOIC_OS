import XCTest
@testable import StoicKit

final class WeeklyReportTests: XCTestCase {

    func testFourSections() {
        let sections = WeeklyReport.compose(WeeklyReportInput(
            integrityNow: 60, integrityWeekAgo: 55, drift: 40,
            hoursLogged: 20, productiveHours: 14, decisionsMade: 3, outcomesLogged: 3))
        XCTAssertEqual(sections.count, 4)
        XCTAssertEqual(sections.map(\.heading), ["Integrity", "Time", "Decisions", "The verdict"])
    }

    func testDriftDownIsNamedPlainly() {
        let sections = WeeklyReport.compose(WeeklyReportInput(
            integrityNow: 40, integrityWeekAgo: 55, drift: 60,
            hoursLogged: 0, productiveHours: 0, decisionsMade: 0, outcomesLogged: 0))
        XCTAssertTrue(sections[0].body.contains("You drifted"))
        XCTAssertTrue(sections[1].body.contains("cannot answer for"))
        XCTAssertTrue(sections[3].body.contains("well off the person"))
    }

    func testOpenLoopsAreCalledOut() {
        let sections = WeeklyReport.compose(WeeklyReportInput(
            integrityNow: 70, integrityWeekAgo: 70, drift: 30,
            hoursLogged: 30, productiveHours: 25, decisionsMade: 5, outcomesLogged: 2))
        XCTAssertTrue(sections[2].body.contains("Close the loop"))
    }
}
