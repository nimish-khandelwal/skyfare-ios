//
//  FlightSearchViewModelTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

@MainActor
final class FlightSearchViewModelTests: XCTestCase {
    private func makeViewModel(
        airports: MockAirportRepository = MockAirportRepository(result: .success(SampleData.airports)),
        offers: MockFlightOfferRepository = MockFlightOfferRepository(result: .success(SampleData.offers))
    ) -> FlightSearchViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        return FlightSearchViewModel(
            airportRepository: airports,
            offerRepository: offers,
            form: FlightSearchForm(
                referenceDate: SampleData.date("2026-11-01T00:00:00"),
                calendar: calendar
            ),
            debounceInterval: .milliseconds(10)
        )
    }

    private func completeRoute(on viewModel: FlightSearchViewModel) {
        viewModel.select(SampleData.dubai, for: .origin)
        viewModel.select(SampleData.mumbai, for: .destination)
    }

    func test_debouncedTypingCollapsesKeystrokesIntoOneRequest() async {
        let repository = MockAirportRepository(result: .success(SampleData.airports))
        let viewModel = makeViewModel(airports: repository)

        viewModel.form.originQuery = "d"
        viewModel.form.originQuery = "du"
        viewModel.form.originQuery = "dub"

        await eventually { !viewModel.originSuggestions.isEmpty }

        XCTAssertEqual(viewModel.originSuggestions.count, SampleData.airports.count)
        XCTAssertEqual(repository.keywords, ["dub"])
    }

    func test_shortKeywordClearsSuggestionsWithoutCallingRepository() async {
        let repository = MockAirportRepository(result: .success(SampleData.airports))
        let viewModel = makeViewModel(airports: repository)

        viewModel.form.originQuery = "dub"
        await eventually { !viewModel.originSuggestions.isEmpty }

        viewModel.form.originQuery = "d"
        await eventually { viewModel.originSuggestions.isEmpty }

        XCTAssertEqual(repository.keywords, ["dub"])
    }

    func test_originAndDestinationUseSeparateSuggestionLists() async {
        let viewModel = makeViewModel()

        viewModel.form.destinationQuery = "mum"
        await eventually { !viewModel.destinationSuggestions.isEmpty }

        XCTAssertTrue(viewModel.originSuggestions.isEmpty)
    }

    func test_loadingFlagIsSetForTheFieldBeingEdited() async {
        let viewModel = makeViewModel()

        viewModel.form.originQuery = "dub"
        await eventually { !viewModel.originSuggestions.isEmpty }

        XCTAssertFalse(viewModel.isLoadingSuggestions(for: .origin))
        XCTAssertFalse(viewModel.isLoadingSuggestions(for: .destination))
    }

    func test_selectingAirportClearsSuggestionsAndFocus() async {
        let viewModel = makeViewModel()
        viewModel.activeField = .origin

        viewModel.form.originQuery = "dub"
        await eventually { !viewModel.originSuggestions.isEmpty }

        viewModel.select(SampleData.dubai, for: .origin)

        XCTAssertTrue(viewModel.originSuggestions.isEmpty)
        XCTAssertNil(viewModel.activeField)
        XCTAssertEqual(viewModel.form.origin, SampleData.dubai)
        XCTAssertEqual(viewModel.form.originQuery, "Dubai (DXB)")
    }

    func test_selectedAirportTextDoesNotTriggerAnotherLookup() async throws {
        let repository = MockAirportRepository(result: .success(SampleData.airports))
        let viewModel = makeViewModel(airports: repository)

        viewModel.select(SampleData.dubai, for: .origin)
        try await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertTrue(repository.keywords.isEmpty)
        XCTAssertEqual(viewModel.form.origin, SampleData.dubai)
    }

    func test_editingAfterSelectionClearsTheSelection() async {
        let viewModel = makeViewModel()
        viewModel.select(SampleData.dubai, for: .origin)

        viewModel.form.originQuery = "mum"
        await eventually { !viewModel.originSuggestions.isEmpty }

        XCTAssertNil(viewModel.form.origin)
    }

    func test_suggestionFailureSurfacesLocalisedMessage() async {
        let repository = MockAirportRepository(result: .failure(APIError.unauthorized))
        let viewModel = makeViewModel(airports: repository)

        viewModel.form.originQuery = "dub"
        await eventually { viewModel.suggestionError != nil }

        XCTAssertEqual(viewModel.suggestionError, "Your API credentials were rejected.")
        XCTAssertTrue(viewModel.originSuggestions.isEmpty)
        XCTAssertFalse(viewModel.isLoadingSuggestions(for: .origin))
    }

    func test_canSearchBecomesTrueOnceRouteIsComplete() async {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.canSearch)

        completeRoute(on: viewModel)

        await eventually { viewModel.canSearch }
    }

    func test_validationMessageMirrorsFormRules() async {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.validationMessage, "Choose where you are flying from.")

        viewModel.select(SampleData.dubai, for: .origin)
        await eventually { viewModel.validationMessage == "Choose where you are flying to." }

        viewModel.select(SampleData.mumbai, for: .destination)
        await eventually { viewModel.validationMessage == nil }
    }

    func test_searchLoadsOffersAndPublishesQuery() async {
        let offers = MockFlightOfferRepository(result: .success(SampleData.offers))
        let viewModel = makeViewModel(offers: offers)
        completeRoute(on: viewModel)

        viewModel.search()

        await eventually {
            if case .loaded = viewModel.state { return true }
            return false
        }

        guard case let .loaded(query, loadedOffers) = viewModel.state else {
            return XCTFail("Unexpected state \(viewModel.state)")
        }

        XCTAssertEqual(query.origin, SampleData.dubai)
        XCTAssertEqual(query.destination, SampleData.mumbai)
        XCTAssertEqual(loadedOffers.count, SampleData.offers.count)
        XCTAssertEqual(offers.queries.count, 1)
    }

    func test_searchWithIncompleteFormFailsWithoutNetworkCall() {
        let offers = MockFlightOfferRepository(result: .success(SampleData.offers))
        let viewModel = makeViewModel(offers: offers)

        viewModel.search()

        XCTAssertEqual(viewModel.state, .failed("Choose where you are flying from."))
        XCTAssertTrue(offers.queries.isEmpty)
    }

    func test_searchFailureSurfacesLocalisedMessage() async {
        let offers = MockFlightOfferRepository(result: .failure(APIError.missingCredentials))
        let viewModel = makeViewModel(offers: offers)
        completeRoute(on: viewModel)

        viewModel.search()

        await eventually {
            viewModel.state == .failed(
                "Amadeus API credentials are missing. Add them to Config/Secrets.xcconfig."
            )
        }
    }

    func test_cancelSearchReturnsToIdle() {
        let viewModel = makeViewModel()
        completeRoute(on: viewModel)

        viewModel.search()
        XCTAssertTrue(viewModel.state.isSearching)

        viewModel.cancelSearch()
        XCTAssertEqual(viewModel.state, .idle)
    }

    func test_swapExchangesBothAirportsAndTheirText() {
        let viewModel = makeViewModel()
        completeRoute(on: viewModel)

        viewModel.swapEndpoints()

        XCTAssertEqual(viewModel.form.origin, SampleData.mumbai)
        XCTAssertEqual(viewModel.form.destination, SampleData.dubai)
        XCTAssertEqual(viewModel.form.originQuery, "Mumbai (BOM)")
        XCTAssertEqual(viewModel.form.destinationQuery, "Dubai (DXB)")
    }

    func test_swapClearsOpenSuggestionLists() async {
        let viewModel = makeViewModel()

        viewModel.form.originQuery = "dub"
        await eventually { !viewModel.originSuggestions.isEmpty }

        viewModel.swapEndpoints()

        XCTAssertTrue(viewModel.originSuggestions.isEmpty)
        XCTAssertTrue(viewModel.destinationSuggestions.isEmpty)
    }
}
