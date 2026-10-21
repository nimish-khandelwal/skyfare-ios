//
//  FlightOfferRepositoryTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class FlightOfferRepositoryTests: XCTestCase {
    private func queryItems(for query: FlightSearchQuery) -> [String: String] {
        let repository = AmadeusFlightOfferRepository(
            client: AmadeusAPIClient(
                session: MockHTTPSession(stubs: [.json([:])]),
                configuration: .test(),
                tokenProvider: MockTokenProvider()
            )
        )

        return repository.endpoint(for: query).queryItems.reduce(into: [:]) { result, item in
            result[item.name] = item.value
        }
    }

    func test_buildsOneWayQuery() {
        let items = queryItems(for: SampleData.query)

        XCTAssertEqual(items["originLocationCode"], "DXB")
        XCTAssertEqual(items["destinationLocationCode"], "BOM")
        XCTAssertEqual(items["departureDate"], "2026-11-10")
        XCTAssertEqual(items["adults"], "1")
        XCTAssertEqual(items["travelClass"], "ECONOMY")
        XCTAssertEqual(items["currencyCode"], "AED")
        XCTAssertEqual(items["max"], "30")
        XCTAssertNil(items["returnDate"])
        XCTAssertNil(items["children"])
        XCTAssertNil(items["infants"])
    }

    func test_includesReturnDateAndExtraPassengers() {
        var query = SampleData.query
        query.returnDate = SampleData.date("2026-11-17T00:00:00")
        query.passengers = PassengerSelection(adults: 2, children: 1, infants: 1)
        query.cabin = .business

        let items = queryItems(for: query)

        XCTAssertEqual(items["returnDate"], "2026-11-17")
        XCTAssertEqual(items["adults"], "2")
        XCTAssertEqual(items["children"], "1")
        XCTAssertEqual(items["infants"], "1")
        XCTAssertEqual(items["travelClass"], "BUSINESS")
    }

    func test_mapsResponseThroughDictionaries() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("flight-offers"))])
        let client = AmadeusAPIClient(
            session: session,
            configuration: .test(),
            tokenProvider: MockTokenProvider(),
            decoder: .amadeus
        )

        let offers = try await AmadeusFlightOfferRepository(client: client).offers(for: SampleData.query)

        XCTAssertEqual(offers.count, 2)
        XCTAssertEqual(offers.first?.validatingCarrier.displayName, "Air Arabia")
    }
}
