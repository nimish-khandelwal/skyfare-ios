//
//  ScreenshotUITests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest

/// Captures the screenshots used in the project README.
///
/// Run with `fastlane screenshots`, which exports the attachments to `docs/screenshots`.
final class ScreenshotUITests: SkyFareUITestCase {
    func test_captureReadmeScreenshots() {
        let originField = app.textFields["search.origin.field"]
        UIAssert.exists(originField)
        capture("01-search")

        originField.tap()
        originField.typeText("dubai")
        let originSuggestion = app.buttons["search.origin.suggestion.DXB"]
        UIAssert.exists(originSuggestion)
        capture("02-autocomplete")
        originSuggestion.tap()

        let destinationField = app.textFields["search.destination.field"]
        destinationField.tap()
        destinationField.typeText("mumbai")
        let destinationSuggestion = app.buttons["search.destination.suggestion.BOM"]
        UIAssert.exists(destinationSuggestion)
        destinationSuggestion.tap()

        let travellers = app.buttons["search.travellers"]
        UIAssert.exists(travellers)
        travellers.tap()
        UIAssert.exists(app.buttons["passengers.adults.increment"])
        capture("03-travellers")
        app.buttons["passengers.done"].tap()

        submitSearch()
        capture("04-results")

        app.buttons["results.filters"].tap()
        UIAssert.exists(app.buttons["filter.carrier.EK"])
        capture("05-filters")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
