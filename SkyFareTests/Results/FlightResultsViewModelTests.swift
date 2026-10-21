//
//  FlightResultsViewModelTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

@MainActor
final class FlightResultsViewModelTests: XCTestCase {
    private func makeViewModel(offers: [FlightOffer] = SampleData.offers) -> FlightResultsViewModel {
        FlightResultsViewModel(query: SampleData.query, offers: offers)
    }

    func test_startsSortedByCheapest() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.sortOption, .cheapest)
        XCTAssertEqual(viewModel.visibleOffers.map(\.id), ["3", "1", "2"])
    }

    func test_changingSortReordersVisibleOffers() {
        let viewModel = makeViewModel()
        viewModel.sortOption = .earliestDeparture

        XCTAssertEqual(viewModel.visibleOffers.map(\.id), ["2", "1", "3"])
    }

    func test_filterAndSortComposeTogether() {
        let viewModel = makeViewModel()
        viewModel.filter.maximumStops = 0
        viewModel.sortOption = .fastest

        XCTAssertEqual(viewModel.visibleOffers.map(\.id), ["1", "2"])
    }

    func test_toggleCarrierAddsThenRemoves() {
        let viewModel = makeViewModel()

        viewModel.toggleCarrier("EK")
        XCTAssertEqual(viewModel.visibleOffers.map(\.id), ["2"])

        viewModel.toggleCarrier("EK")
        XCTAssertEqual(viewModel.visibleOffers.count, 3)
    }

    func test_toggleDepartureWindowAddsThenRemoves() {
        let viewModel = makeViewModel()

        viewModel.toggleDepartureWindow(.evening)
        XCTAssertEqual(viewModel.visibleOffers.map(\.id), ["3"])

        viewModel.toggleDepartureWindow(.evening)
        XCTAssertEqual(viewModel.visibleOffers.count, 3)
    }

    func test_resetFiltersRestoresEveryOffer() {
        let viewModel = makeViewModel()
        viewModel.filter.maximumStops = 0
        viewModel.toggleCarrier("EK")

        viewModel.resetFilters()

        XCTAssertFalse(viewModel.filter.isActive)
        XCTAssertEqual(viewModel.visibleOffers.count, 3)
    }

    func test_resultCountSummaryReflectsFiltering() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.resultCountSummary, "3 flights")

        viewModel.toggleCarrier("EK")
        XCTAssertEqual(viewModel.resultCountSummary, "1 of 3 flights")
    }

    func test_availableCarriersAreUniqueAndSortedByName() {
        let viewModel = makeViewModel()

        XCTAssertEqual(
            viewModel.availableCarriers.map(\.displayName),
            ["Air Arabia", "Emirates", "Indigo"]
        )
        XCTAssertEqual(viewModel.availableCarriers.map(\.code), ["G9", "EK", "6E"])
    }

    func test_emptyAfterFilteringIsDistinctFromNoOffers() {
        let viewModel = makeViewModel()
        viewModel.filter.carrierCodes = ["XX"]

        XCTAssertTrue(viewModel.isEmptyAfterFiltering)
        XCTAssertFalse(viewModel.hasNoOffers)

        let empty = makeViewModel(offers: [])
        XCTAssertTrue(empty.hasNoOffers)
        XCTAssertFalse(empty.isEmptyAfterFiltering)
    }

    func test_cheapestPriceIgnoresFilters() {
        let viewModel = makeViewModel()
        viewModel.filter.carrierCodes = ["EK"]

        XCTAssertEqual(viewModel.cheapestPrice, Decimal(505))
    }
}
