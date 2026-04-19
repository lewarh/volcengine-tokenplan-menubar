import Foundation

public struct JWTPayload: Codable, Equatable, Sendable {
    public let exp: TimeInterval?
    public let iat: TimeInterval?
    public let name: String?
    public let sub: String?
    public let iss: String?

    public init(exp: TimeInterval?, iat: TimeInterval?, name: String?, sub: String?, iss: String?) {
        self.exp = exp
        self.iat = iat
        self.name = name
        self.sub = sub
        self.iss = iss
    }
}

public enum JWTDecoder {
    public static func decodePayload(from jwt: String) throws -> JWTPayload {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else {
            throw CodingPlanError.invalidJWT
        }

        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = payload.count % 4
        if remainder != 0 {
            payload += String(repeating: "=", count: 4 - remainder)
        }

        guard
            let data = Data(base64Encoded: payload),
            let decoded = try? JSONDecoder().decode(JWTPayload.self, from: data)
        else {
            throw CodingPlanError.invalidJWT
        }

        return decoded
    }
}
