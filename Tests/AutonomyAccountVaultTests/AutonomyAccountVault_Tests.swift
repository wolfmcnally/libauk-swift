import XCTest
@testable import AutonomyAccountVault

final class AutonomyAccountVaultTests: XCTestCase {
    
    func testCreateAutonomyAccountVault() {
        AutonomyAccountVault.create(keyChainGroup: "com.bitmark.autonomy")
        XCTAssertEqual(AutonomyAccountVault.shared.keyChainGroup, "com.bitmark.autonomy")
    }
    
}
