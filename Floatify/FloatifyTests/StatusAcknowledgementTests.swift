import XCTest
@testable import Floatify

final class StatusAcknowledgementTests: XCTestCase {
    func testCompletedSessionStaysIdleUntilAvatarTapAcknowledgesIt() {
        var tracker = CompletionAcknowledgementTracker()
        let sessionID = "codex:123"

        tracker.markCompleted(sessionID: sessionID)

        XCTAssertEqual(tracker.visibleState(for: .complete, sessionID: sessionID), .idle)

        tracker.acknowledge(sessionID: sessionID)

        XCTAssertEqual(tracker.visibleState(for: .complete, sessionID: sessionID), .complete)
    }

    func testRunningResetsAcknowledgedCompletion() {
        var tracker = CompletionAcknowledgementTracker()
        let sessionID = "claude:456"

        tracker.markCompleted(sessionID: sessionID)
        tracker.acknowledge(sessionID: sessionID)
        tracker.markRunning(sessionID: sessionID)

        XCTAssertEqual(tracker.visibleState(for: .running, sessionID: sessionID), .running)

        tracker.markCompleted(sessionID: sessionID)

        XCTAssertEqual(tracker.visibleState(for: .complete, sessionID: sessionID), .idle)
    }

    func testKnownLiveRunningStateOverridesStoredCompleteState() {
        let resolvedState = PersistentStatusStateResolver.rawState(
            storedState: .complete,
            monitoredState: .running,
            isTaskStateKnown: true
        )

        XCTAssertEqual(resolvedState, .running)
    }

    func testKnownLiveRunningStateOverridesStoredIdleState() {
        let resolvedState = PersistentStatusStateResolver.rawState(
            storedState: .idle,
            monitoredState: .running,
            isTaskStateKnown: true
        )

        XCTAssertEqual(resolvedState, .running)
    }

    func testNewerStoredRunningStateOverridesStaleMonitoredCompleteState() {
        let storedActivity = Date(timeIntervalSinceReferenceDate: 20)
        let monitoredActivity = Date(timeIntervalSinceReferenceDate: 10)

        let resolvedState = PersistentStatusStateResolver.rawState(
            storedState: .running,
            storedActivity: storedActivity,
            monitoredState: .complete,
            monitoredActivity: monitoredActivity,
            isTaskStateKnown: true
        )

        XCTAssertEqual(resolvedState, .running)
    }

    func testNewerStoredRunningStateOverridesStaleMonitoredIdleState() {
        let storedActivity = Date(timeIntervalSinceReferenceDate: 20)
        let monitoredActivity = Date(timeIntervalSinceReferenceDate: 10)

        let resolvedState = PersistentStatusStateResolver.rawState(
            storedState: .running,
            storedActivity: storedActivity,
            monitoredState: .idle,
            monitoredActivity: monitoredActivity,
            isTaskStateKnown: true
        )

        XCTAssertEqual(resolvedState, .running)
    }

    func testNewerMonitoredCompleteStateOverridesOlderStoredRunningState() {
        let storedActivity = Date(timeIntervalSinceReferenceDate: 10)
        let monitoredActivity = Date(timeIntervalSinceReferenceDate: 20)

        let resolvedState = PersistentStatusStateResolver.rawState(
            storedState: .running,
            storedActivity: storedActivity,
            monitoredState: .complete,
            monitoredActivity: monitoredActivity,
            isTaskStateKnown: true
        )

        XCTAssertEqual(resolvedState, .complete)
    }

    func testNewerStoredCompleteStateOverridesStaleMonitoredRunningState() {
        let storedActivity = Date(timeIntervalSinceReferenceDate: 20)
        let monitoredActivity = Date(timeIntervalSinceReferenceDate: 10)

        let resolvedState = PersistentStatusStateResolver.rawState(
            storedState: .complete,
            storedActivity: storedActivity,
            monitoredState: .running,
            monitoredActivity: monitoredActivity,
            isTaskStateKnown: true
        )

        XCTAssertEqual(resolvedState, .complete)
    }
}
