//
//  AirportRepositoryTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class AirportRepositoryTests: XCTestCase {
    private func makeRepository(session: MockHTTPSession) -> AmadeusAirportRepository {
        AmadeusAirportRepository(
            client: AmadeusAPIClient(
                session: session,
                configuration: .test(),
                tokenProvider: MockTokenProvider(),
                decoder: .amadeus
            )
        )
    }

    func test_returnsMappedAirports() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("locations"))])
        let airports = try await makeRepository(session: session).airports(matching: "dub")

        XCTAssertEqual(airports.map(\.iataCode), ["DXB", "DUB"])
        XCTAssertEqual(session.requestCount, 1)
    }

    func test_shortKeywordSkipsNetworkCall() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("locations"))])
        let airports = try await makeRepository(session: session).airports(matching: "d")

        XCTAssertTrue(airports.isEmpty)
        XCTAssertEqual(session.requestCount, 0)
    }

    func test_whitespaceOnlyKeywordSkipsNetworkCall() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("locations"))])
        let airports = try await makeRepository(session: session).airports(matching: "   ")

        XCTAssertTrue(airports.isEmpty)
        XCTAssertEqual(session.requestCount, 0)
    }

    func test_sendsTrimmedKeywordAsQueryParameter() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("locations"))])
        _ = try await makeRepository(session: session).airports(matching: "  dubai  ")

        let url = try XCTUnwrap(session.requests.first?.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let keyword = components.queryItems?.first { $0.name == "keyword" }?.value

        XCTAssertEqual(keyword, "dubai")
    }
}
