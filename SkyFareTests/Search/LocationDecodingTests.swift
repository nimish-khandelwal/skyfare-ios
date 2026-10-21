//
//  LocationDecodingTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class LocationDecodingTests: XCTestCase {
    func test_mapsPayloadsToAirportsAndDropsEntriesWithoutIATACode() throws {
        let response = try JSONDecoder.amadeus.decode(
            LocationSearchResponse.self,
            from: try Fixture.data("locations")
        )

        let airports = response.data.compactMap(\.asAirport)

        XCTAssertEqual(response.data.count, 3)
        XCTAssertEqual(airports.count, 2)
        XCTAssertEqual(airports.map(\.iataCode), ["DXB", "DUB"])
    }

    func test_normalisesUpperCaseNames() throws {
        let response = try JSONDecoder.amadeus.decode(
            LocationSearchResponse.self,
            from: try Fixture.data("locations")
        )

        let dubai = try XCTUnwrap(response.data.first?.asAirport)

        XCTAssertEqual(dubai.name, "Dubai International")
        XCTAssertEqual(dubai.cityName, "Dubai")
        XCTAssertEqual(dubai.countryName, "United Arab Emirates")
        XCTAssertEqual(dubai.kind, .airport)
        XCTAssertEqual(dubai.displayTitle, "Dubai (DXB)")
    }

    func test_readsCitySubType() throws {
        let response = try JSONDecoder.amadeus.decode(
            LocationSearchResponse.self,
            from: try Fixture.data("locations")
        )

        let dublin = try XCTUnwrap(response.data[1].asAirport)
        XCTAssertEqual(dublin.kind, .city)
    }
}
