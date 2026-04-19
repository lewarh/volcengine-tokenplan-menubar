import Foundation

public enum CurlImportParser {
    public static func parse(_ input: String) throws -> ParsedCurlImport {
        let normalized = input
            .replacingOccurrences(of: "\\\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")

        guard let cookie = extractFirstArgument(
            in: normalized,
            flags: ["-b", "--cookie"]
        ) else {
            throw CodingPlanError.missingCookie
        }

        let cookieValues = parseCookie(cookie)
        guard let connectSID = cookieValues["connect.sid"], !connectSID.isEmpty else {
            throw CodingPlanError.missingField("connect.sid")
        }
        guard let digest = cookieValues["digest"], !digest.isEmpty else {
            throw CodingPlanError.missingField("digest")
        }

        let csrfFromHeader = extractCSRFHeader(in: normalized)
        let csrfToken = csrfFromHeader ?? cookieValues["csrfToken"]
        guard let csrfToken, !csrfToken.isEmpty else {
            throw CodingPlanError.missingField("csrfToken / x-csrf-token")
        }

        let credentials = AccountCredentials(
            connectSID: connectSID,
            digest: digest,
            csrfToken: csrfToken
        )
        let payload = try? JWTDecoder.decodePayload(from: digest)
        return ParsedCurlImport(credentials: credentials, jwtPayload: payload)
    }

    private static func extractFirstArgument(in text: String, flags: [String]) -> String? {
        for flag in flags {
            let patterns = [
                #"(?:^|\s)\#(flag)\s+"((?:\\.|[^"])*)""#,
                #"(?:^|\s)\#(flag)\s+'((?:\\.|[^'])*)'"#,
                #"(?:^|\s)\#(flag)=((?:\\.|[^ ])+)"#,
                #"(?:^|\s)\#(flag)\s+([^ ]+)"#,
            ]

            for pattern in patterns {
                if let match = firstCapturedString(pattern: pattern, in: text) {
                    return match
                }
            }
        }
        return nil
    }

    private static func extractCSRFHeader(in text: String) -> String? {
        let patterns = [
            #"(?:^|\s)(?:-H|--header)\s+"x-csrf-token:\s*([^"]+)""#,
            #"(?:^|\s)(?:-H|--header)\s+'x-csrf-token:\s*([^']+)'"#,
        ]

        for pattern in patterns {
            if let value = firstCapturedString(pattern: pattern, in: text) {
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let headerPattern = #"(?:^|\s)(?:-H|--header)\s+(?:"([^"]+)"|'([^']+)')"#
        guard let regex = try? NSRegularExpression(pattern: headerPattern) else {
            return nil
        }

        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsrange)

        for match in matches {
            for index in 1..<match.numberOfRanges {
                let range = match.range(at: index)
                guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else { continue }
                let header = String(text[swiftRange])
                let parts = header.split(separator: ":", maxSplits: 1).map(String.init)
                if parts.count == 2, parts[0].lowercased().trimmingCharacters(in: .whitespaces) == "x-csrf-token" {
                    return parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        return nil
    }

    private static func parseCookie(_ cookie: String) -> [String: String] {
        cookie
            .split(separator: ";")
            .reduce(into: [String: String]()) { partialResult, rawEntry in
                let entry = rawEntry.trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = entry.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return }
                let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if partialResult[key] == nil {
                    partialResult[key] = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
    }

    private static func firstCapturedString(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: nsrange) else {
            return nil
        }

        for index in 1..<match.numberOfRanges {
            let range = match.range(at: index)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else { continue }
            let value = String(text[swiftRange])
            if !value.isEmpty {
                return value
            }
        }

        return nil
    }
}
