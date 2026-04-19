import CodingPlanKit
import XCTest

final class CurlImportParserTests: XCTestCase {
    func testParsesCookieAndCSRFHeader() throws {
        let curl = """
        curl 'https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage' \
          -H 'content-type: application/json' \
          -H 'x-csrf-token: csrf-123' \
          -b 'connect.sid=sid-001; digest=aaa.bbb.ccc; csrfToken=csrf-from-cookie' \
          --data-raw '{}'
        """

        let parsed = try CurlImportParser.parse(curl)

        XCTAssertEqual(parsed.credentials.connectSID, "sid-001")
        XCTAssertEqual(parsed.credentials.digest, "aaa.bbb.ccc")
        XCTAssertEqual(parsed.credentials.csrfToken, "csrf-123")
    }
}
