//
//  FlightResultsFilterTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class FlightResultsFilterTests: XCTestCase {
    private var offers: [FlightOffer] { SampleData.offers }

    func test_emptyFilterKeepsEverything() {
        let filter = FlightResultsFilter()

        XCTAssertFalse(filter.isActive)
        XCTAssertEqual(filter.activeCount, 0)
        XCTAssertEqual(filter.apply(to: offers).count, offers.count)
    }

    func test_directOnlyRemovesConnections() {
        var filter = FlightResultsFilter()
        filter.maximumStops = 0

        let filtered = filter.apply(to: offers)

        XCTAssertTrue(filtered.allSatisfy(\.isDirect))
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filter.isActive)
    }

    func test_carrierFilterKeepsOnlySelectedAirlines() {
        var filter = FlightResultsFilter()
        filter.carrierCodes = ["EK"]

        XCTAssertEqual(filter.apply(to: offers).map(\.id), ["2"])
    }

    func test_checkedBagFilterKeepsFaresWithBaggage() {
        var filter = FlightResultsFilter()
        filter.checkedBagIncludedOnly = true

        XCTAssertEqual(filter.apply(to: offers).map(\.id), ["2"])
    }

    func test_departureWindowFilterUsesOutboundDeparture() {
        var filter = FlightResultsFilter()
        filter.departureWindows = [.earlyMorning]

        XCTAssertEqual(filter.apply(to: offers).map(\.id), ["2"])
    }

    func test_multipleWindowsAreUnioned() {
        var filter = FlightResultsFilter()
        filter.departureWindows = [.earlyMorning, .evening]

        XCTAssertEqual(Set(filter.apply(to: offers).map(\.id)), ["2", "3"])
    }

    func test_filtersCombineAsAnd() {
        var filter = FlightResultsFilter()
        filter.maximumStops = 0
        filter.checkedBagIncludedOnly = true

        XCTAssertEqual(filter.activeCount, 2)
        XCTAssertEqual(filter.apply(to: offers).map(\.id), ["2"])
    }

    func test_conflictingFiltersReturnNothing() {
        var filter = FlightResultsFilter()
        filter.carrierCodes = ["EK"]
        filter.departureWindows = [.evening]

        XCTAssertTrue(filter.apply(to: offers).isEmpty)
    }

    func test_departureWindowBoundariesAreHalfOpen() {
        let sixAM = SampleData.date("2026-11-10T06:00:00")

        XCTAssertFalse(DepartureWindow.earlyMorning.contains(sixAM))
        XCTAssertTrue(DepartureWindow.morning.contains(sixAM))
    }

    func test_cheapestSortOrdersByPriceThenDuration() {
        let sorted = FlightSortOption.cheapest.sort(offers)
        XCTAssertEqual(sorted.map(\.id), ["3", "1", "2"])
    }

    func test_fastestSortOrdersByDuration() {
        let sorted = FlightSortOption.fastest.sort(offers)
        XCTAssertEqual(sorted.map(\.id), ["1", "2", "3"])
    }

    func test_earliestSortOrdersByDepartureTime() {
        let sorted = FlightSortOption.earliestDeparture.sort(offers)
        XCTAssertEqual(sorted.map(\.id), ["2", "1", "3"])
    }
}
