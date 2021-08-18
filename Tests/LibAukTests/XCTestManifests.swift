import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(autonomy_account_vault_swiftTests.allTests),
    ]
}
#endif
