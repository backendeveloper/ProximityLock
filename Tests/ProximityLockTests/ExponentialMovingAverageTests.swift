import XCTest
@testable import ProximityLock

final class ExponentialMovingAverageTests: XCTestCase {

    func testFirstValueReturnedAsIs() {
        var ema = ExponentialMovingAverage(alpha: 0.3)
        let result = ema.update(with: -60.0)
        XCTAssertEqual(result, -60.0)
    }

    func testSubsequentValuesAreFiltered() {
        var ema = ExponentialMovingAverage(alpha: 0.3)
        _ = ema.update(with: -60.0)
        let second = ema.update(with: -70.0)

        // EMA = 0.3 * (-70) + 0.7 * (-60) = -21 + -42 = -63
        XCTAssertEqual(second, -63.0, accuracy: 0.001)
    }

    func testAlphaOnePassesThrough() {
        var ema = ExponentialMovingAverage(alpha: 1.0)
        _ = ema.update(with: -60.0)
        let second = ema.update(with: -70.0)
        XCTAssertEqual(second, -70.0, accuracy: 0.001)
    }

    func testConvergesToConstantSignal() {
        var ema = ExponentialMovingAverage(alpha: 0.3)
        _ = ema.update(with: -80.0)

        var last: Double = -80.0
        for _ in 0..<50 {
            last = ema.update(with: -50.0)
        }

        XCTAssertEqual(last, -50.0, accuracy: 0.01)
    }

    func testResetClearsState() {
        var ema = ExponentialMovingAverage(alpha: 0.3)
        _ = ema.update(with: -60.0)
        _ = ema.update(with: -70.0)

        ema.reset()
        XCTAssertNil(ema.currentValue)

        let afterReset = ema.update(with: -55.0)
        XCTAssertEqual(afterReset, -55.0)
    }

    func testCurrentValueTracksLastOutput() {
        var ema = ExponentialMovingAverage(alpha: 0.5)
        XCTAssertNil(ema.currentValue)

        _ = ema.update(with: -60.0)
        XCTAssertEqual(ema.currentValue, -60.0)

        _ = ema.update(with: -70.0)
        XCTAssertEqual(ema.currentValue, -65.0, accuracy: 0.001)
    }
}
