import CodingPlanKit
import Foundation
import XCTest

final class RefreshPolicyTests: XCTestCase {
    func testPeriodicRefreshRequiresEightMinutes() {
        let policy = RefreshPolicy()
        let now = Date(timeIntervalSince1970: 1_000)
        let lastRefreshAt = now.addingTimeInterval(-7 * 60)

        let shouldRefresh = policy.shouldRefresh(
            lastRefreshAt: lastRefreshAt,
            now: now,
            trigger: .periodic,
            isRefreshing: false
        )

        XCTAssertFalse(shouldRefresh)
    }

    func testInteractiveRefreshRequiresThirtySeconds() {
        let policy = RefreshPolicy()
        let now = Date(timeIntervalSince1970: 1_000)
        let lastRefreshAt = now.addingTimeInterval(-29)

        let shouldRefresh = policy.shouldRefresh(
            lastRefreshAt: lastRefreshAt,
            now: now,
            trigger: .interactive,
            isRefreshing: false
        )

        XCTAssertFalse(shouldRefresh)
    }

    func testManualRefreshBypassesThrottle() {
        let policy = RefreshPolicy()
        let now = Date(timeIntervalSince1970: 1_000)
        let lastRefreshAt = now.addingTimeInterval(-2)

        let shouldRefresh = policy.shouldRefresh(
            lastRefreshAt: lastRefreshAt,
            now: now,
            trigger: .manual,
            isRefreshing: false
        )

        XCTAssertTrue(shouldRefresh)
    }

    func testRefreshingStateBlocksNewRefresh() {
        let policy = RefreshPolicy()

        let shouldRefresh = policy.shouldRefresh(
            lastRefreshAt: nil,
            now: Date(),
            trigger: .manual,
            isRefreshing: true
        )

        XCTAssertFalse(shouldRefresh)
    }
}
