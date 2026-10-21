//
//  PlaceDecodingTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class PlaceDecodingTests: XCTestCase {
    private func loadPlaces() throws -> [PlacePayload] {
        try JSONDecoder.flightProvider.decode(
            DuffelEnvelope<[PlacePayload]>.self,
            from: try Fixture.data("places")
        ).data
    }

    func test_mapsPayloadsAndDropsEntriesWithoutIATACode() throws {
        let payloads = try loadPlaces()
        let airports = payloads.compactMap(\.asAirport)

        XCTAssertEqual(payloads.count, 3)
        XCTAssertEqual(airports.map(\.iataCode), ["DXB", "DUB"])
    }

    func test_readsAirportDetails() throws {
        let dubai = try XCTUnwrap(try loadPlaces().first?.asAirport)

        XCTAssertEqual(dubai.id, "arp_dxb_ae")
        XCTAssertEqual(dubai.name, "Dubai International")
        XCTAssertEqual(dubai.cityName, "Dubai")
        XCTAssertEqual(dubai.countryCode, "AE")
        XCTAssertEqual(dubai.kind, .airport)
        XCTAssertEqual(dubai.displayTitle, "Dubai (DXB)")
        XCTAssertEqual(dubai.displaySubtitle, "Dubai International · AE")
    }

    func test_readsCityType() throws {
        let dublin = try XCTUnwrap(try loadPlaces()[1].asAirport)

        XCTAssertEqual(dublin.kind, .city)
    }

    func test_unknownTypeFallsBack() throws {
        let data = Data(#"{"data":[{"id":"x","type":"spaceport","iata_code":"ZZZ"}]}"#.utf8)
        let payloads = try JSONDecoder.flightProvider
            .decode(DuffelEnvelope<[PlacePayload]>.self, from: data).data

        XCTAssertEqual(payloads.first?.asAirport?.kind, .unknown)
    }
}
