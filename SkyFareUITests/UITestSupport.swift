//
//  UITestSupport.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest

/// Assertion helpers that read element state before asserting, keeping main-actor
/// access out of XCTest's non-isolated autoclosures.
@MainActor
enum UIAssert {
    static func exists(
        _ element: XCUIElement,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let appeared = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(appeared, "Element never appeared: \(element)", file: file, line: line)
    }

    static func doesNotExist(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let present = element.exists
        XCTAssertFalse(present, "Element unexpectedly present: \(element)", file: file, line: line)
    }

    static func isEnabled(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let enabled = element.isEnabled
        XCTAssertTrue(enabled, "Element was not enabled: \(element)", file: file, line: line)
    }

    static func isDisabled(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let enabled = element.isEnabled
        XCTAssertFalse(enabled, "Element was unexpectedly enabled: \(element)", file: file, line: line)
    }

    static func label(
        _ element: XCUIElement,
        contains text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let label = element.label
        XCTAssertTrue(label.contains(text), "\"\(label)\" does not contain \"\(text)\"", file: file, line: line)
    }
}

@MainActor
class SkyFareUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
    }

    func chooseRoute(origin: String = "dubai", destination: String = "mumbai") {
        let originField = app.textFields["search.origin.field"]
        UIAssert.exists(originField)
        originField.tap()
        originField.typeText(origin)

        let originSuggestion = app.buttons["search.origin.suggestion.DXB"]
        UIAssert.exists(originSuggestion)
        originSuggestion.tap()

        let destinationField = app.textFields["search.destination.field"]
        UIAssert.exists(destinationField)
        destinationField.tap()
        destinationField.typeText(destination)

        let destinationSuggestion = app.buttons["search.destination.suggestion.BOM"]
        UIAssert.exists(destinationSuggestion)
        destinationSuggestion.tap()
    }

    func submitSearch() {
        let submit = app.buttons["search.submit"]
        UIAssert.isEnabled(submit)
        submit.tap()
        UIAssert.exists(app.staticTexts["results.count"])
    }
}
