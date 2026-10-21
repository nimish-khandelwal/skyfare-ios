//
//  FlightSearchUITests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest

final class FlightSearchUITests: SkyFareUITestCase {
    func test_searchStaysDisabledUntilRouteIsChosen() {
        let submit = app.buttons["search.submit"]
        UIAssert.exists(submit)
        UIAssert.isDisabled(submit)
        UIAssert.exists(app.staticTexts["search.validationMessage"])
    }

    func test_demoBannerExplainsMissingCredentials() {
        let banner = app.staticTexts["search.sampleDataBanner"]
        UIAssert.exists(banner)
        UIAssert.label(banner, contains: "Demo data")
    }

    func test_completingTheRouteEnablesSearchAndShowsResults() {
        chooseRoute()
        submitSearch()

        let offer = app.staticTexts["results.offer.1"]
        UIAssert.exists(offer)
        UIAssert.label(offer, contains: "Air Arabia")
        UIAssert.label(offer, contains: "Direct")
    }

    func test_passengerSheetEnforcesInfantRule() {
        let travellers = app.buttons["search.travellers"]
        UIAssert.exists(travellers)
        travellers.tap()

        let increment = app.buttons["passengers.infants.increment"]
        UIAssert.exists(increment)
        increment.tap()
        increment.tap()

        UIAssert.exists(app.staticTexts["1"])

        app.buttons["passengers.done"].tap()
        UIAssert.exists(app.buttons["search.travellers"])
    }
}
