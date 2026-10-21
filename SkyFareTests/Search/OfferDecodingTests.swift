//
//  OfferDecodingTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class OfferDecodingTests: XCTestCase {
    private func loadOffers() throws -> [OfferPayload] {
        try JSONDecoder.flightProvider.decode(
            DuffelEnvelope<OfferRequestPayload>.self,
            from: try Fixture.data("offers")
        ).data.offers
    }

    private func mapped() throws -> [FlightOffer] {
        FlightOfferMapper().map(try loadOffers())
    }

    func test_decodesTheOfferRequestEnvelope() throws {
        let response = try JSONDecoder.flightProvider.decode(
            DuffelEnvelope<OfferRequestPayload>.self,
            from: try Fixture.data("offers")
        )

        XCTAssertEqual(response.data.id, "orq_0000AaBbCcDdEeFfGgHhIi")
        XCTAssertEqual(response.data.offers.count, 2)
    }

    func test_decodesSnakeCasedKeys() throws {
        let offer = try XCTUnwrap(try loadOffers().first)
        let segment = try XCTUnwrap(offer.slices.first?.segments.first)

        XCTAssertEqual(offer.totalAmount, "650.00")
        XCTAssertEqual(offer.totalCurrency, "AED")
        XCTAssertEqual(offer.baseAmount, "500.00")
        XCTAssertEqual(offer.totalEmissionsKg, "212")
        XCTAssertEqual(segment.marketingCarrierFlightNumber, "451")
        XCTAssertEqual(segment.marketingCarrier?.iataCode, "G9")
        XCTAssertEqual(segment.passengers?.first?.cabinClassMarketingName, "Economy")
    }

    func test_decodesLocalAirportTimesWithoutAnOffset() throws {
        let segment = try XCTUnwrap(try loadOffers().first?.slices.first?.segments.first)

        XCTAssertEqual(segment.departingAt, SampleData.date("2026-11-10T09:30:00"))
        XCTAssertEqual(segment.arrivingAt, SampleData.date("2026-11-10T14:05:00"))
    }

    func test_mapsDirectOfferToDomain() throws {
        let offer = try XCTUnwrap(try mapped().first)

        XCTAssertEqual(offer.id, "off_0000direct")
        XCTAssertEqual(offer.totalPrice, Decimal(650))
        XCTAssertEqual(offer.basePrice, Decimal(500))
        XCTAssertEqual(offer.currencyCode, "AED")
        XCTAssertEqual(offer.validatingCarrier, Carrier(code: "G9", name: "Air Arabia"))
        XCTAssertEqual(offer.cabin, .economy)
        XCTAssertEqual(offer.travellerCount, 1)
        XCTAssertEqual(offer.outbound?.duration, 11_100)
        XCTAssertEqual(offer.stopCount, 0)
        XCTAssertTrue(offer.isDirect)
        XCTAssertEqual(offer.outbound?.segments.first?.aircraftName, "Airbus A320")
        XCTAssertEqual(offer.outbound?.segments.first?.flightDesignator, "G9 451")
    }

    func test_zeroQuantityCheckedBagIsNotIncludedBaggage() throws {
        let offer = try XCTUnwrap(try mapped().first)

        XCTAssertEqual(offer.includedCheckedBags, 0)
        XCTAssertFalse(offer.includesCheckedBag)
    }

    func test_mapsConnectingOfferToDomain() throws {
        let offer = try XCTUnwrap(try mapped().last)

        XCTAssertEqual(offer.id, "off_0000connect")
        XCTAssertEqual(offer.totalPrice, Decimal(505))
        XCTAssertEqual(offer.outbound?.segments.count, 2)
        XCTAssertEqual(offer.outbound?.duration, 33_900)
        XCTAssertEqual(offer.outbound?.layoverAirports, ["MCT"])
        XCTAssertFalse(offer.isDirect)
        XCTAssertEqual(offer.validatingCarrier.displayName, "Oman Air")
        XCTAssertTrue(offer.outbound?.crossesMidnight == true)
    }

    func test_technicalStopsCountTowardsTheStopTotal() throws {
        let offer = try XCTUnwrap(try mapped().last)

        XCTAssertEqual(offer.outbound?.segments.last?.technicalStops, 1)
        XCTAssertEqual(offer.stopCount, 2)
    }

    func test_checkedBaggageUsesTheLeastGenerousSegment() throws {
        let offer = try XCTUnwrap(try mapped().last)

        XCTAssertEqual(offer.includedCheckedBags, 1)
        XCTAssertTrue(offer.includesCheckedBag)
    }

    func test_zeroPaddedDurationsParse() {
        XCTAssertEqual(ISO8601Duration.seconds(from: "PT03H05M"), 11_100)
        XCTAssertEqual(ISO8601Duration.seconds(from: "PT09H25M"), 33_900)
    }

    func test_fallsBackToSegmentTimesWhenDurationMissing() throws {
        let json: [String: Any] = ["data": ["id": "orq_1", "offers": [[
            "id": "off_nodur",
            "total_amount": "100.00",
            "total_currency": "AED",
            "slices": [["segments": [[
                "id": "seg_1",
                "origin": ["iata_code": "DXB"],
                "destination": ["iata_code": "BOM"],
                "departing_at": "2026-11-10T09:00:00",
                "arriving_at": "2026-11-10T12:00:00",
                "marketing_carrier": ["iata_code": "G9", "name": "Air Arabia"],
                "marketing_carrier_flight_number": "100"
            ]]]],
            "passengers": [["id": "pas_1"]]
        ]]]]

        let data = try JSONSerialization.data(withJSONObject: json)
        let payload = try JSONDecoder.flightProvider
            .decode(DuffelEnvelope<OfferRequestPayload>.self, from: data)
        let offer = try XCTUnwrap(FlightOfferMapper().map(payload.data.offers).first)

        XCTAssertEqual(offer.outbound?.duration, 10_800)
        XCTAssertEqual(offer.includedCheckedBags, 0)
    }

    func test_skipsOfferWithUnparseableAmount() throws {
        let json: [String: Any] = ["data": ["id": "orq_1", "offers": [[
            "id": "off_bad",
            "total_amount": "not-a-number",
            "total_currency": "AED",
            "slices": [["duration": "PT01H", "segments": [[
                "id": "seg_1",
                "origin": ["iata_code": "DXB"],
                "destination": ["iata_code": "BOM"],
                "departing_at": "2026-11-10T09:00:00",
                "arriving_at": "2026-11-10T10:00:00"
            ]]]]
        ]]]]

        let data = try JSONSerialization.data(withJSONObject: json)
        let payload = try JSONDecoder.flightProvider
            .decode(DuffelEnvelope<OfferRequestPayload>.self, from: data)

        XCTAssertTrue(FlightOfferMapper().map(payload.data.offers).isEmpty)
    }

    func test_skipsOfferWithNoSegments() throws {
        let json: [String: Any] = ["data": ["id": "orq_1", "offers": [[
            "id": "off_empty",
            "total_amount": "100.00",
            "total_currency": "AED",
            "slices": [["duration": "PT01H", "segments": []]]
        ]]]]

        let data = try JSONSerialization.data(withJSONObject: json)
        let payload = try JSONDecoder.flightProvider
            .decode(DuffelEnvelope<OfferRequestPayload>.self, from: data)

        XCTAssertTrue(FlightOfferMapper().map(payload.data.offers).isEmpty)
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
