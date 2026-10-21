//
//  ResultsFilterUITests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest

final class ResultsFilterUITests: SkyFareUITestCase {
    func test_filteringByAirlineNarrowsResults() {
        chooseRoute()
        submitSearch()

        app.buttons["results.filters"].tap()

        let emirates = app.buttons["filter.carrier.EK"]
        UIAssert.exists(emirates)
        emirates.tap()
        app.buttons["filter.apply"].tap()

        UIAssert.exists(app.staticTexts["results.offer.2"])
        UIAssert.doesNotExist(app.staticTexts["results.offer.1"])
    }

    func test_sortingSwitchesToFastest() {
        chooseRoute()
        submitSearch()

        app.buttons["Fastest"].tap()

        let offer = app.staticTexts["results.offer.1"]
        UIAssert.exists(offer)
        UIAssert.label(offer, contains: "4h 35m")
    }
}
