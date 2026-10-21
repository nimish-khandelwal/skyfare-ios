//
//  DuffelOfferPayload.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

struct DuffelEnvelope<Payload: Decodable & Sendable>: Decodable, Sendable {
    let data: Payload
}

struct OfferRequestPayload: Decodable, Sendable {
    let id: String
    let offers: [OfferPayload]
}

struct OfferPayload: Decodable, Sendable {
    struct Carrier: Decodable, Sendable {
        let iataCode: String?
        let name: String?

        enum CodingKeys: String, CodingKey {
            case iataCode = "iata_code"
            case name
        }
    }

    struct Passenger: Decodable, Sendable {
        let id: String?
    }

    let id: String
    let totalAmount: String
    let totalCurrency: String
    let baseAmount: String?
    let taxAmount: String?
    let owner: Carrier?
    let slices: [SlicePayload]
    let passengers: [Passenger]?
    let totalEmissionsKg: String?

    enum CodingKeys: String, CodingKey {
        case id
        case totalAmount = "total_amount"
        case totalCurrency = "total_currency"
        case baseAmount = "base_amount"
        case taxAmount = "tax_amount"
        case owner
        case slices
        case passengers
        case totalEmissionsKg = "total_emissions_kg"
    }
}

struct SlicePayload: Decodable, Sendable {
    let id: String?
    let duration: String?
    let fareBrandName: String?
    let segments: [SegmentPayload]

    enum CodingKeys: String, CodingKey {
        case id
        case duration
        case fareBrandName = "fare_brand_name"
        case segments
    }
}

struct SegmentPayload: Decodable, Sendable {
    struct Place: Decodable, Sendable {
        let iataCode: String?
        let name: String?
        let cityName: String?

        enum CodingKeys: String, CodingKey {
            case iataCode = "iata_code"
            case name
            case cityName = "city_name"
        }
    }

    struct Aircraft: Decodable, Sendable {
        let name: String?
    }

    struct Stop: Decodable, Sendable {
        let id: String?
    }

    struct SegmentPassenger: Decodable, Sendable {
        struct Baggage: Decodable, Sendable {
            let type: String?
            let quantity: Int?
        }

        let passengerId: String?
        let cabinClass: String?
        let cabinClassMarketingName: String?
        let baggages: [Baggage]?

        enum CodingKeys: String, CodingKey {
            case passengerId = "passenger_id"
            case cabinClass = "cabin_class"
            case cabinClassMarketingName = "cabin_class_marketing_name"
            case baggages
        }
    }

    let id: String
    let origin: Place
    let destination: Place
    let departingAt: Date
    let arrivingAt: Date
    let duration: String?
    let marketingCarrier: OfferPayload.Carrier?
    let operatingCarrier: OfferPayload.Carrier?
    let marketingCarrierFlightNumber: String?
    let aircraft: Aircraft?
    let stops: [Stop]?
    let passengers: [SegmentPassenger]?

    enum CodingKeys: String, CodingKey {
        case id
        case origin
        case destination
        case departingAt = "departing_at"
        case arrivingAt = "arriving_at"
        case duration
        case marketingCarrier = "marketing_carrier"
        case operatingCarrier = "operating_carrier"
        case marketingCarrierFlightNumber = "marketing_carrier_flight_number"
        case aircraft
        case stops
        case passengers
    }
}
