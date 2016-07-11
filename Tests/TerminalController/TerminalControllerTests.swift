import XCTest
@testable import TerminalController

class TerminalControllerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(TerminalController().text, "Hello, World!")
    }


    static var allTests : [(String, (TerminalControllerTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
