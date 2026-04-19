import Foundation

public enum UsageStatus: String, Codable, Equatable, Sendable {
    case running = "Running"
    case expired = "Expired"
    case exhausted = "Exhausted"
    case unknown

    public init(rawValue: String) {
        switch rawValue {
        case Self.running.rawValue: self = .running
        case Self.expired.rawValue: self = .expired
        case Self.exhausted.rawValue: self = .exhausted
        default: self = .unknown
        }
    }

    public var displayName: String {
        switch self {
        case .running: return "正常"
        case .expired: return "已过期"
        case .exhausted: return "已耗尽"
        case .unknown: return "未知"
        }
    }
}

public enum QuotaLevel: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case session
    case weekly
    case monthly
    case unknown

    public init(rawValue: String) {
        switch rawValue {
        case Self.session.rawValue: self = .session
        case Self.weekly.rawValue: self = .weekly
        case Self.monthly.rawValue: self = .monthly
        default: self = .unknown
        }
    }

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .session: return "会话配额"
        case .weekly: return "周配额"
        case .monthly: return "月配额"
        case .unknown: return "未知配额"
        }
    }

    public var compactCode: String {
        switch self {
        case .session: return "S"
        case .weekly: return "W"
        case .monthly: return "M"
        case .unknown: return "?"
        }
    }

    public var totalQuotaText: String {
        switch self {
        case .session: return "总配额 5 小时"
        case .weekly: return "总配额 40 小时"
        case .monthly: return "总配额 160 小时"
        case .unknown: return "总配额未知"
        }
    }

    public var compactTitle: String {
        switch self {
        case .session: return "5小时限制"
        case .weekly: return "周限制"
        case .monthly: return "总量"
        case .unknown: return "未知"
        }
    }

    public var cycleLength: TimeInterval {
        switch self {
        case .session: return 5 * 60 * 60
        case .weekly: return 7 * 24 * 60 * 60
        case .monthly: return 30 * 24 * 60 * 60
        case .unknown: return 24 * 60 * 60
        }
    }
}

public struct AccountCredentials: Codable, Equatable, Sendable {
    public let connectSID: String
    public let digest: String
    public let csrfToken: String

    public init(connectSID: String, digest: String, csrfToken: String) {
        self.connectSID = connectSID
        self.digest = digest
        self.csrfToken = csrfToken
    }

    public var isComplete: Bool {
        !connectSID.isEmpty && !digest.isEmpty && !csrfToken.isEmpty
    }
}

public struct StoredAccount: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let username: String?
    public let credentialExpiresAt: Date?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String,
        name: String,
        username: String?,
        credentialExpiresAt: Date?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.credentialExpiresAt = credentialExpiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ParsedCurlImport: Equatable, Sendable {
    public let credentials: AccountCredentials
    public let jwtPayload: JWTPayload?

    public init(credentials: AccountCredentials, jwtPayload: JWTPayload?) {
        self.credentials = credentials
        self.jwtPayload = jwtPayload
    }
}

public struct QuotaSnapshot: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let level: QuotaLevel
    public let usedPercent: Double
    public let resetAt: Date

    public init(level: QuotaLevel, usedPercent: Double, resetAt: Date) {
        self.level = level
        self.usedPercent = usedPercent
        self.resetAt = resetAt
    }

    public var remainingPercent: Double {
        max(0, 100 - usedPercent)
    }

    public func resetRemainingPercent(now: Date = Date()) -> Double {
        let remaining = resetAt.timeIntervalSince(now)
        let fraction = remaining / max(level.cycleLength, 1)
        return min(100, max(0, fraction * 100))
    }
}

public struct UsageSnapshot: Equatable, Sendable {
    public let status: UsageStatus
    public let updatedAt: Date
    public let quotas: [QuotaSnapshot]

    public init(status: UsageStatus, updatedAt: Date, quotas: [QuotaSnapshot]) {
        self.status = status
        self.updatedAt = updatedAt
        self.quotas = quotas.sorted { lhs, rhs in
            lhs.level.cycleLength < rhs.level.cycleLength
        }
    }

    public var mostConstrainedQuota: QuotaSnapshot? {
        quotas.min { lhs, rhs in
            lhs.remainingPercent < rhs.remainingPercent
        }
    }

    public var compactMenuLabel: String {
        guard status == .running, let quota = mostConstrainedQuota else {
            return status == .running ? "—" : status.displayName
        }
        return "\(quota.level.compactCode)\(Int(quota.remainingPercent.rounded()))"
    }

    public var sessionQuota: QuotaSnapshot? {
        quotas.first { $0.level == .session }
    }
}

public enum CodingPlanError: LocalizedError, Equatable, Sendable {
    case missingCookie
    case missingField(String)
    case invalidJWT
    case invalidResponse
    case invalidHTTPStatus(Int, String?)
    case authenticationExpired
    case rateLimited
    case missingImportedCredentials
    case network(String)

    public var errorDescription: String? {
        switch self {
        case .missingCookie:
            return "未找到 cURL 里的 Cookie 参数。"
        case let .missingField(field):
            return "cURL 缺少必要字段：\(field)。"
        case .invalidJWT:
            return "digest 不是可解析的 JWT。"
        case .invalidResponse:
            return "接口返回格式无法识别。"
        case let .invalidHTTPStatus(code, message):
            return message.map { "请求失败（\(code)）：\($0)" } ?? "请求失败，HTTP \(code)。"
        case .authenticationExpired:
            return "认证失败，请重新导入最新 cURL。"
        case .rateLimited:
            return "请求过于频繁，请稍后再试。"
        case .missingImportedCredentials:
            return "请重新导入 GetCodingPlanUsage 的 cURL。"
        case let .network(message):
            return message
        }
    }
}
