import CodingPlanKit
import Foundation
import XCTest

final class UsageSnapshotTests: XCTestCase {
    func testCompactLabelUsesMostConstrainedQuota() {
        let snapshot = UsageSnapshot(
            status: .running,
            updatedAt: Date(),
            quotas: [
                QuotaSnapshot(level: .session, usedPercent: 18.6, resetAt: Date().addingTimeInterval(1_000)),
                QuotaSnapshot(level: .weekly, usedPercent: 29.2, resetAt: Date().addingTimeInterval(2_000)),
                QuotaSnapshot(level: .monthly, usedPercent: 14.7, resetAt: Date().addingTimeInterval(3_000)),
            ]
        )

        XCTAssertEqual(snapshot.compactMenuLabel, "W71")
    }

    func testResetRemainingPercentClampsToCycleRange() {
        let future = Date().addingTimeInterval(3 * 24 * 60 * 60)
        let quota = QuotaSnapshot(level: .weekly, usedPercent: 10, resetAt: future)

        let percent = quota.resetRemainingPercent(now: Date())

        XCTAssertGreaterThan(percent, 40)
        XCTAssertLessThan(percent, 50)
    }
}
