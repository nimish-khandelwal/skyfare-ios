//
//  FlightSearchFormTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class FlightSearchFormTests: XCTestCase {
    private let reference = SampleData.date("2026-11-01T00:00:00")

    private func makeForm() -> FlightSearchForm {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return FlightSearchForm(referenceDate: reference, calendar: calendar)
    }

    private func makeCompleteForm() -> FlightSearchForm {
        var form = makeForm()
        form.select(SampleData.dubai, for: .origin)
        form.select(SampleData.mumbai, for: .destination)
        return form
    }

    func test_defaultsDepartureOneWeekOut() {
        let form = makeForm()
        XCTAssertEqual(form.departureDate, SampleData.date("2026-11-08T00:00:00"))
        XCTAssertEqual(form.returnDate, SampleData.date("2026-11-15T00:00:00"))
        XCTAssertEqual(form.tripType, .oneWay)
    }

    func test_incompleteFormCannotSearch() {
        let form = makeForm()

        XCTAssertFalse(form.canSearch)
        XCTAssertEqual(form.validationMessage, "Choose where you are flying from.")
        XCTAssertNil(form.makeQuery())
    }

    func test_promptsForDestinationOnceOriginChosen() {
        var form = makeForm()
        form.select(SampleData.dubai, for: .origin)

        XCTAssertEqual(form.validationMessage, "Choose where you are flying to.")
    }

    func test_rejectsIdenticalOriginAndDestination() {
        var form = makeForm()
        form.select(SampleData.dubai, for: .origin)
        form.select(SampleData.dubai, for: .destination)

        XCTAssertEqual(form.validationMessage, "Origin and destination must be different.")
    }

    func test_rejectsPastDepartureDate() {
        var form = makeCompleteForm()
        form.departureDate = SampleData.date("2026-10-30T00:00:00")

        XCTAssertEqual(form.validationMessage, "Departure date cannot be in the past.")
    }

    func test_allowsDepartureToday() {
        var form = makeCompleteForm()
        form.departureDate = reference

        XCTAssertTrue(form.canSearch)
    }

    func test_rejectsReturnBeforeDepartureOnRoundTrip() {
        var form = makeCompleteForm()
        form.tripType = .roundTrip
        form.departureDate = SampleData.date("2026-11-20T00:00:00")
        form.returnDate = SampleData.date("2026-11-10T00:00:00")

        XCTAssertEqual(
            form.validationMessage,
            "Return date must be on or after the departure date."
        )
    }

    func test_ignoresReturnDateOnOneWayTrip() {
        var form = makeCompleteForm()
        form.tripType = .oneWay
        form.returnDate = SampleData.date("2026-11-02T00:00:00")

        XCTAssertTrue(form.canSearch)
        XCTAssertNil(form.makeQuery()?.returnDate)
    }

    func test_surfacesPassengerValidation() {
        var form = makeCompleteForm()
        form.passengers = PassengerSelection(adults: 1, children: 0, infants: 3)

        XCTAssertEqual(form.validationMessage, "Each infant must travel with an adult.")
    }

    func test_buildsQueryFromValidForm() throws {
        var form = makeCompleteForm()
        form.tripType = .roundTrip
        form.cabin = .business
        form.passengers = PassengerSelection(adults: 2, children: 1, infants: 0)

        let query = try XCTUnwrap(form.makeQuery())

        XCTAssertEqual(query.origin, SampleData.dubai)
        XCTAssertEqual(query.destination, SampleData.mumbai)
        XCTAssertEqual(query.departureDate, form.departureDate)
        XCTAssertEqual(query.returnDate, form.returnDate)
        XCTAssertEqual(query.cabin, .business)
        XCTAssertEqual(query.passengers.adults, 2)
        XCTAssertTrue(query.isRoundTrip)
        XCTAssertEqual(query.routeSummary, "DXB → BOM")
    }

    func test_selectingAirportFillsQueryText() {
        var form = makeForm()
        form.select(SampleData.mumbai, for: .destination)

        XCTAssertEqual(form.destinationQuery, "Mumbai (BOM)")
        XCTAssertEqual(form.selection(for: .destination), SampleData.mumbai)
    }

    func test_swapExchangesBothAirportsAndText() {
        var form = makeCompleteForm()
        form.swapEndpoints()

        XCTAssertEqual(form.origin, SampleData.mumbai)
        XCTAssertEqual(form.destination, SampleData.dubai)
        XCTAssertEqual(form.originQuery, "Mumbai (BOM)")
        XCTAssertEqual(form.destinationQuery, "Dubai (DXB)")
    }

    func test_earliestReturnDateTracksDeparture() {
        var form = makeCompleteForm()
        form.departureDate = SampleData.date("2026-12-01T00:00:00")

        XCTAssertEqual(form.earliestReturnDate, form.departureDate)
    }
}
