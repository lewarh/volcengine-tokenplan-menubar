import Foundation

public struct UsageService: Sendable {
    private let endpoint = URL(string: "https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage")!
    private let referer = "https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?LLM=%7B%7D&action=%7B%7D&advancedActiveKey=subscribe&tab=Application"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchUsage(credentials: AccountCredentials) async throws -> UsageSnapshot {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("https://console.volcengine.com", forHTTPHeaderField: "origin")
        request.setValue(referer, forHTTPHeaderField: "referer")
        request.setValue(credentials.csrfToken, forHTTPHeaderField: "x-csrf-token")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36",
            forHTTPHeaderField: "user-agent"
        )
        request.setValue(
            "connect.sid=\(credentials.connectSID); digest=\(credentials.digest); csrfToken=\(credentials.csrfToken)",
            forHTTPHeaderField: "cookie"
        )
        request.timeoutInterval = 10

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw CodingPlanError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CodingPlanError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw CodingPlanError.authenticationExpired
        case 429:
            throw CodingPlanError.rateLimited
        default:
            let message = try? JSONDecoder().decode(ErrorEnvelope.self, from: data).message
            throw CodingPlanError.invalidHTTPStatus(httpResponse.statusCode, message)
        }

        let envelope = try decodeEnvelope(from: data)
        let quotas = envelope.result.quotaUsage.map { quota in
            QuotaSnapshot(
                level: QuotaLevel(rawValue: quota.level),
                usedPercent: quota.percent,
                resetAt: Date(timeIntervalSince1970: quota.resetTimestamp)
            )
        }

        return UsageSnapshot(
            status: UsageStatus(rawValue: envelope.result.status),
            updatedAt: Date(timeIntervalSince1970: envelope.result.updateTimestamp),
            quotas: quotas
        )
    }

    private func decodeEnvelope(from data: Data) throws -> UsageEnvelope {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(UsageEnvelope.self, from: data)
        guard envelope.responseMetadata != nil else {
            throw CodingPlanError.invalidResponse
        }
        return envelope
    }
}

private struct UsageEnvelope: Decodable {
    let responseMetadata: ResponseMetadata?
    let result: UsageResult

    enum CodingKeys: String, CodingKey {
        case responseMetadata = "ResponseMetadata"
        case result = "Result"
    }
}

private struct ResponseMetadata: Decodable {}

private struct UsageResult: Decodable {
    let status: String
    let updateTimestamp: TimeInterval
    let quotaUsage: [QuotaUsage]

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case updateTimestamp = "UpdateTimestamp"
        case quotaUsage = "QuotaUsage"
    }
}

private struct QuotaUsage: Decodable {
    let level: String
    let percent: Double
    let resetTimestamp: TimeInterval

    enum CodingKeys: String, CodingKey {
        case level = "Level"
        case percent = "Percent"
        case resetTimestamp = "ResetTimestamp"
    }
}

private struct ErrorEnvelope: Decodable {
    let message: String?
}
