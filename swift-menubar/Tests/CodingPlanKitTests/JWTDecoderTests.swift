import CodingPlanKit
import XCTest

final class JWTDecoderTests: XCTestCase {
    func testDecodesPayload() throws {
        let payload = #"{"exp":1776699260,"iat":1776526460,"name":"songlairui","sub":"2114747863","iss":"https://signin.volcengine.com"}"#
        let payloadData = try XCTUnwrap(payload.data(using: .utf8))
        let payloadBase64 = payloadData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let jwt = "header.\(payloadBase64).signature"

        let decoded = try JWTDecoder.decodePayload(from: jwt)

        XCTAssertEqual(decoded.name, "songlairui")
        XCTAssertEqual(decoded.sub, "2114747863")
        XCTAssertEqual(decoded.exp, 1776699260)
    }
}
