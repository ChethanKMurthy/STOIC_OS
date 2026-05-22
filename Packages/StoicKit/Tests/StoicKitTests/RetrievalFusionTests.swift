import XCTest
@testable import StoicKit

final class RetrievalFusionTests: XCTestCase {

    func testConsensusItemRanksFirst() {
        let semantic = ["a", "b", "c"]
        let keyword  = ["b", "a", "d"]
        let recency  = ["a", "e", "b"]
        let fused = RetrievalFusion.fuse([semantic, keyword, recency])
        XCTAssertEqual(fused.first, "a", "'a' is ranked highly across all three lists")
    }

    func testFusionIsDeterministic() {
        let lists = [["x", "y"], ["y", "x"]]
        let first  = RetrievalFusion.fuse(lists)
        let second = RetrievalFusion.fuse(lists)
        XCTAssertEqual(first, second)
    }

    func testTieBreaksByFirstAppearance() {
        // x and y appear once each at rank 1 -> equal score -> x seen first.
        let fused = RetrievalFusion.fuse([["x"], ["y"]])
        XCTAssertEqual(fused, ["x", "y"])
    }

    func testLimitTrimsResults() {
        let fused = RetrievalFusion.fuse([["a", "b", "c", "d"]], limit: 2)
        XCTAssertEqual(fused.count, 2)
        XCTAssertEqual(fused, ["a", "b"])
    }

    func testEmptyInputYieldsEmptyOutput() {
        let fused: [String] = RetrievalFusion.fuse([])
        XCTAssertTrue(fused.isEmpty)
    }
}
