import XCTest

/// Shorthand used across the logic tests: a boolean check with a plain-English message that names the rule
/// being protected, reported against the calling line rather than this file.
func expect(_ condition: Bool, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(condition, message, file: file, line: line)
}
