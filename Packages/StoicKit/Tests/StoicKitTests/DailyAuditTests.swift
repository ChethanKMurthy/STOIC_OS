import XCTest
@testable import StoicKit

final class DailyAuditTests: XCTestCase {

    func testNoHoursLogged() {
        let lines = DailyAudit.compose(DailyAuditInput(
            hoursLogged: 0, productiveHours: 0, integrityScore: 50, drift: 50))
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].contains("did not record"))
    }

    func testLeakyDay() {
        let lines = DailyAudit.compose(DailyAuditInput(
            hoursLogged: 10, productiveHours: 3, integrityScore: 44, drift: 56))
        XCTAssertTrue(lines.contains { $0.contains("3 productive, 7 unproductive (30%)") })
        XCTAssertTrue(lines.contains { $0.contains("leaked") })
    }

    func testSharpDay() {
        let lines = DailyAudit.compose(DailyAuditInput(
            hoursLogged: 8, productiveHours: 7, integrityScore: 80, drift: 20))
        XCTAssertTrue(lines.contains { $0.contains("sharp day") })
        XCTAssertTrue(lines.contains { $0.contains("80 integrity, 20 drift") })
    }
}
