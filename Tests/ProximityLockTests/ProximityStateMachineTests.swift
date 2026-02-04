import XCTest
@testable import ProximityLock

final class ProximityStateMachineTests: XCTestCase {

    private var stateMachine: ProximityStateMachine!
    private var stateChanges: [ProximityState]!

    override func setUp() {
        super.setUp()
        stateMachine = ProximityStateMachine(lockTimeout: 100, signalLossTimeout: 100)
        stateChanges = []
        stateMachine.onStateChange = { [weak self] state in
            self?.stateChanges.append(state)
        }
    }

    override func tearDown() {
        stateMachine = nil
        stateChanges = nil
        super.tearDown()
    }

    func testInitialStateIsUnknown() {
        XCTAssertEqual(stateMachine.currentState, .unknown)
    }

    func testUnknownToPresent() {
        stateMachine.processSignal(.abovePresent)
        XCTAssertEqual(stateMachine.currentState, .present)
        XCTAssertEqual(stateChanges, [.present])
    }

    func testUnknownToAway() {
        stateMachine.processSignal(.belowLock)
        XCTAssertEqual(stateMachine.currentState, .away)
    }

    func testPresentToWarning() {
        stateMachine.processSignal(.abovePresent) // → present
        stateMachine.processSignal(.belowLock)     // → warning
        XCTAssertEqual(stateMachine.currentState, .warning)
        XCTAssertEqual(stateChanges, [.present, .warning])
    }

    func testWarningBackToPresent() {
        stateMachine.processSignal(.abovePresent)
        stateMachine.processSignal(.belowLock)
        stateMachine.processSignal(.abovePresent)
        XCTAssertEqual(stateMachine.currentState, .present)
        XCTAssertEqual(stateChanges, [.present, .warning, .present])
    }

    func testWarningStaysOnInGap() {
        stateMachine.processSignal(.abovePresent)
        stateMachine.processSignal(.belowLock)
        stateMachine.processSignal(.inGap)
        XCTAssertEqual(stateMachine.currentState, .warning)
    }

    func testSignalLostFromPresent() {
        stateMachine.processSignal(.abovePresent)
        stateMachine.signalLost()
        XCTAssertEqual(stateMachine.currentState, .away)
    }

    func testSignalLostFromWarning() {
        stateMachine.processSignal(.abovePresent)
        stateMachine.processSignal(.belowLock)
        stateMachine.signalLost()
        XCTAssertEqual(stateMachine.currentState, .away)
    }

    func testBluetoothOffFromPresent() {
        stateMachine.processSignal(.abovePresent)
        stateMachine.bluetoothOff()
        XCTAssertEqual(stateMachine.currentState, .away)
    }

    func testBluetoothOffFromUnknown() {
        stateMachine.bluetoothOff()
        XCTAssertEqual(stateMachine.currentState, .away)
    }

    func testAwayToPresent() {
        stateMachine.processSignal(.abovePresent)
        stateMachine.signalLost()
        XCTAssertEqual(stateMachine.currentState, .away)

        stateMachine.processSignal(.abovePresent)
        XCTAssertEqual(stateMachine.currentState, .present)
    }

    func testResetGoesToUnknown() {
        stateMachine.processSignal(.abovePresent)
        stateMachine.reset()
        XCTAssertEqual(stateMachine.currentState, .unknown)
    }

    func testWarningTimeoutTransitionsToAway() {
        let sm = ProximityStateMachine(lockTimeout: 0.1, signalLossTimeout: 100)
        var changes: [ProximityState] = []
        sm.onStateChange = { changes.append($0) }

        sm.processSignal(.abovePresent)
        sm.processSignal(.belowLock)
        XCTAssertEqual(sm.currentState, .warning)

        let expectation = expectation(description: "timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(sm.currentState, .away)
        XCTAssertTrue(changes.contains(.away))
    }

    func testWarningTimerCancelledOnReturnToPresent() {
        let sm = ProximityStateMachine(lockTimeout: 0.2, signalLossTimeout: 100)

        sm.processSignal(.abovePresent)
        sm.processSignal(.belowLock)
        XCTAssertEqual(sm.currentState, .warning)

        sm.processSignal(.abovePresent)
        XCTAssertEqual(sm.currentState, .present)

        let expectation = expectation(description: "no timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(sm.currentState, .present)
    }

    func testDuplicateStateDoesNotFireCallback() {
        stateMachine.processSignal(.abovePresent)
        stateMachine.processSignal(.abovePresent)
        stateMachine.processSignal(.abovePresent)
        XCTAssertEqual(stateChanges.count, 1)
    }
}
