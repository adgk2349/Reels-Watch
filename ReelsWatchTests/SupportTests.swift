import XCTest
@testable import ReelsWatch

final class SwipeIntentTests: XCTestCase {
    func testClassifiesCardinalDirections() {
        XCTAssertEqual(SwipeIntent.classify(CGSize(width: -60, height: 5)), .left)
        XCTAssertEqual(SwipeIntent.classify(CGSize(width: 60, height: -5)), .right)
        XCTAssertEqual(SwipeIntent.classify(CGSize(width: 4, height: -60)), .up)
        XCTAssertEqual(SwipeIntent.classify(CGSize(width: -4, height: 60)), .down)
    }

    func testIgnoresShortAndDiagonalDrags() {
        XCTAssertNil(SwipeIntent.classify(CGSize(width: -20, height: 0)))
        XCTAssertNil(SwipeIntent.classify(CGSize(width: -50, height: -45)))
        XCTAssertNil(SwipeIntent.classify(.zero))
    }
}

final class FormattingTests: XCTestCase {
    func testCountGrouping() {
        XCTAssertEqual(Formatting.count(0), "0")
        XCTAssertEqual(Formatting.count(482), "482")
        XCTAssertEqual(Formatting.count(3_214), "3,214")
        XCTAssertEqual(Formatting.count(1_000_000), "1,000,000")
        XCTAssertEqual(Formatting.count(-1_234), "-1,234")
    }

    func testRelativeLabels() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(Formatting.relative(from: now.addingTimeInterval(-30), now: now), "방금")
        XCTAssertEqual(Formatting.relative(from: now.addingTimeInterval(-5 * 60), now: now), "5분")
        XCTAssertEqual(Formatting.relative(from: now.addingTimeInterval(-3 * 3_600), now: now), "3시간")
        XCTAssertEqual(Formatting.relative(from: now.addingTimeInterval(-2 * 86_400), now: now), "2일")
        XCTAssertEqual(Formatting.relative(from: now.addingTimeInterval(60), now: now), "방금")
    }
}
