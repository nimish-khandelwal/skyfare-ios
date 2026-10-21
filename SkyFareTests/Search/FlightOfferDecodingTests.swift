//
//  FlightOfferDecodingTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class FlightOfferDecodingTests: XCTestCase {
    private func loadResponse() throws -> FlightOffersResponse {
        try JSONDecoder.amadeus.decode(
            FlightOffersResponse.self,
            from: try Fixture.data("flight-offers")
        )
    }

    func test_decodesAllOffers() throws {
        let response = try loadResponse()
        XCTAssertEqual(response.data.count, 2)
        XCTAssertEqual(response.dictionaries?.carriers?["G9"], "AIR ARABIA")
        XCTAssertEqual(response.dictionaries?.aircraft?["320"], "AIRBUS A320")
    }

    func test_decodesReservedClassKeyword() throws {
        let response = try loadResponse()
        let fareDetails = try XCTUnwrap(response.data.first?.travelerPricings?.first?.fareDetailsBySegment.first)

        XCTAssertEqual(fareDetails.bookingClass, "Z")
        XCTAssertEqual(fareDetails.cabin, "ECONOMY")
        XCTAssertEqual(fareDetails.includedCheckedBags?.quantity, 0)
    }

    func test_decodesMixedDateFormats() throws {
        let response = try loadResponse()
        let offer = try XCTUnwrap(response.data.first)

        XCTAssertEqual(offer.lastTicketingDate, SampleData.date("2026-11-01T00:00:00"))
        XCTAssertEqual(
            offer.itineraries.first?.segments.first?.departure.at,
            SampleData.date("2026-11-10T09:30:00")
        )
    }

    func test_mapsDirectOfferToDomain() throws {
        let response = try loadResponse()
        let mapper = FlightOfferMapper(dictionaries: response.dictionaries)
        let offer = try XCTUnwrap(mapper.map(response.data).first)

        XCTAssertEqual(offer.id, "1")
        XCTAssertEqual(offer.totalPrice, Decimal(650))
        XCTAssertEqual(offer.basePrice, Decimal(500))
        XCTAssertEqual(offer.currencyCode, "AED")
        XCTAssertEqual(offer.seatsRemaining, 7)
        XCTAssertEqual(offer.validatingCarrier, Carrier(code: "G9", name: "Air Arabia"))
        XCTAssertEqual(offer.cabin, .economy)
        XCTAssertEqual(offer.includedCheckedBags, 0)
        XCTAssertEqual(offer.travellerCount, 1)
        XCTAssertEqual(offer.outbound?.duration, 11_100)
        XCTAssertEqual(offer.stopCount, 0)
        XCTAssertTrue(offer.isDirect)
        XCTAssertFalse(offer.includesCheckedBag)
        XCTAssertEqual(offer.outbound?.segments.first?.aircraftName, "Airbus A320")
        XCTAssertEqual(offer.outbound?.segments.first?.flightDesignator, "G9 451")
    }

    func test_mapsConnectingOfferToDomain() throws {
        let response = try loadResponse()
        let mapper = FlightOfferMapper(dictionaries: response.dictionaries)
        let offer = try XCTUnwrap(mapper.map(response.data).last)

        XCTAssertEqual(offer.id, "2")
        XCTAssertEqual(offer.totalPrice, Decimal(505))
        XCTAssertEqual(offer.outbound?.segments.count, 2)
        XCTAssertEqual(offer.outbound?.duration, 33_900)
        XCTAssertEqual(offer.outbound?.layoverAirports, ["MCT"])
        XCTAssertEqual(offer.stopCount, 2)
        XCTAssertFalse(offer.isDirect)
        XCTAssertEqual(offer.includedCheckedBags, 1)
        XCTAssertTrue(offer.includesCheckedBag)
        XCTAssertEqual(offer.validatingCarrier.displayName, "Oman Air")
        XCTAssertTrue(offer.outbound?.crossesMidnight == true)
    }

    func test_fallsBackToSegmentSumWhenItineraryDurationMissing() throws {
        let json: [String: Any] = [
            "data": [[
                "id": "9",
                "itineraries": [[
                    "segments": [[
                        "id": "1",
                        "departure": ["iataCode": "DXB", "at": "2026-11-10T09:00:00"],
                        "arrival": ["iataCode": "BOM", "at": "2026-11-10T12:00:00"],
                        "carrierCode": "G9",
                        "number": "100"
                    ]]
                ]],
                "price": ["currency": "AED", "total": "100.00"]
            ]]
        ]

        let data = try JSONSerialization.data(withJSONObject: json)
        let response = try JSONDecoder.amadeus.decode(FlightOffersResponse.self, from: data)
        let offer = try XCTUnwrap(FlightOfferMapper(dictionaries: nil).map(response.data).first)

        XCTAssertEqual(offer.outbound?.duration, 10_800)
        XCTAssertEqual(offer.validatingCarrier.code, "G9")
        XCTAssertEqual(offer.validatingCarrier.displayName, "G9")
    }

    func test_skipsOfferWithUnparseablePrice() throws {
        let json: [String: Any] = [
            "data": [[
                "id": "bad",
                "itineraries": [[
                    "duration": "PT1H",
                    "segments": [[
                        "id": "1",
                        "departure": ["iataCode": "DXB", "at": "2026-11-10T09:00:00"],
                        "arrival": ["iataCode": "BOM", "at": "2026-11-10T10:00:00"],
                        "carrierCode": "G9",
                        "number": "100"
                    ]]
                ]],
                "price": ["currency": "AED", "total": "not-a-number"]
            ]]
        ]

        let data = try JSONSerialization.data(withJSONObject: json)
        let response = try JSONDecoder.amadeus.decode(FlightOffersResponse.self, from: data)

        XCTAssertTrue(FlightOfferMapper(dictionaries: nil).map(response.data).isEmpty)
    }

    func test_perTravellerPriceDividesTotal() throws {
        let offer = FlightOffer(
            id: "x",
            itineraries: [],
            totalPrice: 900,
            basePrice: nil,
            currencyCode: "AED",
            seatsRemaining: nil,
            validatingCarrier: Carrier(code: "G9", name: "Air Arabia"),
            cabin: .economy,
            includedCheckedBags: 0,
            travellerCount: 3
        )

        XCTAssertEqual(offer.pricePerTraveller, 300)
    }
}
