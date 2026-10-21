//
//  PassengerSelectionTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class PassengerSelectionTests: XCTestCase {
    func test_defaultIsOneAdult() {
        let passengers = PassengerSelection()

        XCTAssertEqual(passengers.adults, 1)
        XCTAssertEqual(passengers.total, 1)
        XCTAssertTrue(passengers.isValid)
        XCTAssertEqual(passengers.summary, "1 adult")
    }

    func test_summaryListsEveryTravellerType() {
        let passengers = PassengerSelection(adults: 2, children: 1, infants: 1)
        XCTAssertEqual(passengers.summary, "2 adults, 1 child, 1 infant")
    }

    func test_rejectsMoreInfantsThanAdults() {
        let passengers = PassengerSelection(adults: 1, children: 0, infants: 2)

        XCTAssertFalse(passengers.isValid)
        XCTAssertEqual(passengers.validationMessage, "Each infant must travel with an adult.")
    }

    func test_rejectsMoreThanNineSeatedTravellers() {
        let passengers = PassengerSelection(adults: 9, children: 1, infants: 0)

        XCTAssertFalse(passengers.isValid)
        XCTAssertEqual(
            passengers.validationMessage,
            "A single booking allows up to 9 seated travellers."
        )
    }

    func test_infantsDoNotCountTowardsSeatedLimit() {
        let passengers = PassengerSelection(adults: 9, children: 0, infants: 9)

        XCTAssertEqual(passengers.seatedTravellers, 9)
        XCTAssertEqual(passengers.total, 18)
        XCTAssertTrue(passengers.isValid)
    }

    func test_incrementStopsAtSeatedLimit() {
        var passengers = PassengerSelection(adults: 9, children: 0, infants: 0)
        passengers.increment(.children)

        XCTAssertEqual(passengers.children, 0)
    }

    func test_incrementInfantsStopsAtAdultCount() {
        var passengers = PassengerSelection(adults: 1)
        passengers.increment(.infants)
        passengers.increment(.infants)

        XCTAssertEqual(passengers.infants, 1)
    }

    func test_decrementNeverRemovesLastAdult() {
        var passengers = PassengerSelection()
        passengers.decrement(.adults)

        XCTAssertEqual(passengers.adults, 1)
    }

    func test_decrementAdultsBelowInfantCountIsRejected() {
        var passengers = PassengerSelection(adults: 2, children: 0, infants: 2)
        passengers.decrement(.adults)

        XCTAssertEqual(passengers.adults, 2)
    }

    func test_decrementChildrenFloorsAtZero() {
        var passengers = PassengerSelection(adults: 1, children: 0, infants: 0)
        passengers.decrement(.children)

        XCTAssertEqual(passengers.children, 0)
    }
}
