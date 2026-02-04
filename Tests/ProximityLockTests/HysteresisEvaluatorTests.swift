import XCTest
@testable import ProximityLock

final class HysteresisEvaluatorTests: XCTestCase {

    private var evaluator: HysteresisEvaluator!

    override func setUp() {
        super.setUp()
        evaluator = HysteresisEvaluator(lockThreshold: -80, presentThreshold: -55)
    }

    func testAbovePresentThreshold() {
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -50), .abovePresent)
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -55), .abovePresent)
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -30), .abovePresent)
    }

    func testBelowLockThreshold() {
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -85), .belowLock)
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -80), .belowLock)
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -100), .belowLock)
    }

    func testInGap() {
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -60), .inGap)
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -70), .inGap)
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -79.9), .inGap)
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -55.1), .inGap)
    }

    func testExactBoundaries() {
        // At present threshold → abovePresent
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -55), .abovePresent)
        // At lock threshold → belowLock
        XCTAssertEqual(evaluator.evaluate(filteredRSSI: -80), .belowLock)
    }
}
