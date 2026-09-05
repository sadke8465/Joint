import XCTest
@testable import CouplesTodo

final class AppInfoTests: XCTestCase {
    func testDisplayNameIsStable() {
        XCTAssertEqual(AppInfo.displayName, "Couples Todo")
    }
}
