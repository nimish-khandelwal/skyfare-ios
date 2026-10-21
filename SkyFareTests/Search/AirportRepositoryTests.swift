//
//  AirportRepositoryTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class AirportRepositoryTests: XCTestCase {
    private func makeRepository(session: MockHTTPSession) -> DuffelAirportRepository {
        DuffelAirportRepository(
            client: HTTPAPIClient(
                session: session,
                configuration: .test(),
                tokenProvider: MockTokenProvider(),
                decoder: .flightProvider
            )
        )
    }

    func test_returnsMappedAirports() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("places"))])
        let airports = try await makeRepository(session: session).airports(matching: "dub")

        XCTAssertEqual(airports.map(\.iataCode), ["DXB", "DUB"])
        XCTAssertEqual(session.requestCount, 1)
    }

    func test_callsThePlaceSuggestionsEndpoint() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("places"))])
        _ = try await makeRepository(session: session).airports(matching: "dubai")

        let url = try XCTUnwrap(session.requests.first?.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.path, "/places/suggestions")
        XCTAssertEqual(components.queryItems?.first { $0.name == "query" }?.value, "dubai")
        XCTAssertEqual(session.requests.first?.httpMethod, "GET")
    }

    func test_shortKeywordSkipsNetworkCall() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("places"))])
        let airports = try await makeRepository(session: session).airports(matching: "d")

        XCTAssertTrue(airports.isEmpty)
        XCTAssertEqual(session.requestCount, 0)
    }

    func test_whitespaceOnlyKeywordSkipsNetworkCall() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("places"))])
        let airports = try await makeRepository(session: session).airports(matching: "   ")

        XCTAssertTrue(airports.isEmpty)
        XCTAssertEqual(session.requestCount, 0)
    }

    func test_sendsTrimmedKeyword() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("places"))])
        _ = try await makeRepository(session: session).airports(matching: "  dubai  ")

        let url = try XCTUnwrap(session.requests.first?.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.queryItems?.first { $0.name == "query" }?.value, "dubai")
    }
}
