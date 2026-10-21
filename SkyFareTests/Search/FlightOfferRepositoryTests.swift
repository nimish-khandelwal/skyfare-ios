//
//  FlightOfferRepositoryTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class FlightOfferRepositoryTests: XCTestCase {
    private func makeRepository(session: MockHTTPSession) -> DuffelFlightOfferRepository {
        DuffelFlightOfferRepository(
            client: HTTPAPIClient(
                session: session,
                configuration: .test(),
                tokenProvider: MockTokenProvider(),
                decoder: .flightProvider
            )
        )
    }

    private func requestBody(for query: FlightSearchQuery) throws -> [String: Any] {
        let repository = DuffelFlightOfferRepository(
            client: HTTPAPIClient(
                session: MockHTTPSession(stubs: [.json([:])]),
                configuration: .test(),
                tokenProvider: MockTokenProvider()
            )
        )

        let body = try XCTUnwrap(repository.endpoint(for: query).body)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        return try XCTUnwrap(json?["data"] as? [String: Any])
    }

    func test_postsAnOfferRequestAskingForOffersInline() throws {
        let endpoint = try DuffelFlightOfferRepository(
            client: HTTPAPIClient(
                session: MockHTTPSession(stubs: [.json([:])]),
                configuration: .test(),
                tokenProvider: MockTokenProvider()
            )
        ).endpoint(for: SampleData.query)

        XCTAssertEqual(endpoint.path, "air/offer_requests")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(
            endpoint.queryItems.first { $0.name == "return_offers" }?.value,
            "true"
        )
    }

    func test_buildsOneWaySliceAndSingleAdult() throws {
        let data = try requestBody(for: SampleData.query)
        let slices = try XCTUnwrap(data["slices"] as? [[String: Any]])
        let passengers = try XCTUnwrap(data["passengers"] as? [[String: Any]])

        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices.first?["origin"] as? String, "DXB")
        XCTAssertEqual(slices.first?["destination"] as? String, "BOM")
        XCTAssertEqual(slices.first?["departure_date"] as? String, "2026-11-10")
        XCTAssertEqual(passengers.count, 1)
        XCTAssertEqual(passengers.first?["type"] as? String, "adult")
        XCTAssertEqual(data["cabin_class"] as? String, "economy")
    }

    func test_roundTripAddsTheReturnSliceInReverse() throws {
        var query = SampleData.query
        query.returnDate = SampleData.date("2026-11-17T00:00:00")

        let slices = try XCTUnwrap(try requestBody(for: query)["slices"] as? [[String: Any]])

        XCTAssertEqual(slices.count, 2)
        XCTAssertEqual(slices[1]["origin"] as? String, "BOM")
        XCTAssertEqual(slices[1]["destination"] as? String, "DXB")
        XCTAssertEqual(slices[1]["departure_date"] as? String, "2026-11-17")
    }

    func test_expandsPassengerCountsIntoIndividualTravellers() throws {
        var query = SampleData.query
        query.passengers = PassengerSelection(adults: 2, children: 1, infants: 1)
        query.cabin = .business

        let data = try requestBody(for: query)
        let passengers = try XCTUnwrap(data["passengers"] as? [[String: Any]])
        let types = passengers.compactMap { $0["type"] as? String }

        XCTAssertEqual(types, ["adult", "adult", "child", "infant_without_seat"])
        XCTAssertEqual(data["cabin_class"] as? String, "business")
    }

    func test_decodesOffersFromTheResponse() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("offers"))])
        let offers = try await makeRepository(session: session).offers(for: SampleData.query)

        XCTAssertEqual(offers.count, 2)
        XCTAssertEqual(offers.first?.validatingCarrier.displayName, "Air Arabia")
        XCTAssertEqual(session.requests.first?.httpMethod, "POST")
        XCTAssertEqual(
            session.requests.first?.value(forHTTPHeaderField: "Content-Type"),
            "application/json"
        )
    }

    func test_limitsResultsToTheRequestedMaximum() async throws {
        var query = SampleData.query
        query.maximumResults = 1

        let session = MockHTTPSession(stubs: [.success(try Fixture.data("offers"))])
        let offers = try await makeRepository(session: session).offers(for: query)

        XCTAssertEqual(offers.count, 1)
    }
}
