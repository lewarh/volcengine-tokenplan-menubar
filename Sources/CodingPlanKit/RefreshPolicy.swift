import Foundation

public enum RefreshTrigger: Sendable {
    case periodic
    case interactive
    case manual
}

public struct RefreshPolicy: Equatable, Sendable {
    public let periodicInterval: TimeInterval
    public let interactiveThrottle: TimeInterval

    public init(
        periodicInterval: TimeInterval = 8 * 60,
        interactiveThrottle: TimeInterval = 30
    ) {
        self.periodicInterval = periodicInterval
        self.interactiveThrottle = interactiveThrottle
    }

    public func shouldRefresh(
        lastRefreshAt: Date?,
        now: Date,
        trigger: RefreshTrigger,
        isRefreshing: Bool
    ) -> Bool {
        guard !isRefreshing else { return false }

        let minimumInterval: TimeInterval
        switch trigger {
        case .periodic:
            minimumInterval = periodicInterval
        case .interactive:
            minimumInterval = interactiveThrottle
        case .manual:
            minimumInterval = 0
        }

        guard let lastRefreshAt else { return true }
        return now.timeIntervalSince(lastRefreshAt) >= minimumInterval
    }
}
