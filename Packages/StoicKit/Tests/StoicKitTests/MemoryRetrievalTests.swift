import XCTest
@testable import StoicKit

final class MemoryRetrievalTests: XCTestCase {

    private func decision(_ situation: String, daysAgo: Int) -> DecisionRecord {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return DecisionRecord(createdAt: date, situation: situation,
                              isPast: false, outputJSON: "{}")
    }

    func testKeywordMatchOutranksPureRecency() {
        let decisions = [
            decision("Whether to switch jobs to another company", daysAgo: 30),
            decision("What to cook for dinner tonight", daysAgo: 1),
            decision("How to handle a difficult relative", daysAgo: 2)
        ]
        let result = MemoryRetrieval.relevant(
            to: "Should I leave for another company", from: decisions, limit: 3)
        XCTAssertEqual(result.first?.situation, "Whether to switch jobs to another company")
    }

    func testEmptyHistory() {
        XCTAssertTrue(MemoryRetrieval.relevant(to: "anything", from: []).isEmpty)
    }

    func testRespectsLimit() {
        let decisions = (0..<10).map { decision("decision number \($0)", daysAgo: $0) }
        XCTAssertEqual(
            MemoryRetrieval.relevant(to: "decision", from: decisions, limit: 3).count, 3)
    }
}
