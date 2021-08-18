import XCTest
@testable import LibAuk

final class LibAuk_Tests: XCTestCase {
    
    func testCreateAutonomyAccountVault() throws {
        LibAuk.create(keyChainGroup: "com.bitmark.autonomy")
        XCTAssertEqual(LibAuk.shared.keyChainGroup, "com.bitmark.autonomy")
    }
    
}
