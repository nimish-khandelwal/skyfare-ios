//
//  FlightOfferPayload.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

struct FlightOffersResponse: Decodable, Sendable {
    let data: [FlightOfferPayload]
    let dictionaries: AmadeusDictionaries?
}

struct AmadeusDictionaries: Decodable, Sendable {
    let carriers: [String: String]?
    let aircraft: [String: String]?
    let currencies: [String: String]?
}

struct FlightOfferPayload: Decodable, Sendable {
    let id: String
    let oneWay: Bool?
    let numberOfBookableSeats: Int?
    let lastTicketingDate: Date?
    let itineraries: [ItineraryPayload]
    let price: PricePayload
    let validatingAirlineCodes: [String]?
    let travelerPricings: [TravelerPricingPayload]?
}

struct ItineraryPayload: Decodable, Sendable {
    let duration: String?
    let segments: [SegmentPayload]
}

struct SegmentPayload: Decodable, Sendable {
    struct Point: Decodable, Sendable {
        let iataCode: String
        let terminal: String?
        let at: Date
    }

    struct Aircraft: Decodable, Sendable {
        let code: String?
    }

    let id: String
    let departure: Point
    let arrival: Point
    let carrierCode: String
    let number: String
    let aircraft: Aircraft?
    let duration: String?
    let numberOfStops: Int?
}

struct PricePayload: Decodable, Sendable {
    let currency: String
    let total: String
    let base: String?
    let grandTotal: String?
}

struct TravelerPricingPayload: Decodable, Sendable {
    struct FareDetails: Decodable, Sendable {
        struct Bags: Decodable, Sendable {
            let quantity: Int?
        }

        let segmentId: String
        let cabin: String?
        let bookingClass: String?
        let includedCheckedBags: Bags?

        enum CodingKeys: String, CodingKey {
            case segmentId
            case cabin
            case bookingClass = "class"
            case includedCheckedBags
        }
    }

    let travelerId: String
    let travelerType: String?
    let price: PricePayload?
    let fareDetailsBySegment: [FareDetails]
}
