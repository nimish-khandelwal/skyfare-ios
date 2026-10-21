//
//  FlightOffer.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

struct Carrier: Hashable, Sendable {
    let code: String
    let name: String

    var displayName: String {
        name.isEmpty ? code : name
    }
}

struct SegmentPoint: Hashable, Sendable {
    let iataCode: String
    let terminal: String?
    let date: Date
}

struct FlightSegment: Identifiable, Hashable, Sendable {
    let id: String
    let departure: SegmentPoint
    let arrival: SegmentPoint
    let carrier: Carrier
    let flightNumber: String
    let aircraftName: String?
    let duration: TimeInterval
    let technicalStops: Int

    var flightDesignator: String {
        "\(carrier.code) \(flightNumber)"
    }
}

struct Itinerary: Identifiable, Hashable, Sendable {
    let id: Int
    let duration: TimeInterval
    let segments: [FlightSegment]

    var stopCount: Int {
        max(0, segments.count - 1) + segments.reduce(0) { $0 + $1.technicalStops }
    }

    var departure: SegmentPoint? {
        segments.first?.departure
    }

    var arrival: SegmentPoint? {
        segments.last?.arrival
    }

    var layoverAirports: [String] {
        guard segments.count > 1 else { return [] }
        return segments.dropLast().map(\.arrival.iataCode)
    }

    var crossesMidnight: Bool {
        guard let departure, let arrival else { return false }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        return !calendar.isDate(departure.date, inSameDayAs: arrival.date)
    }
}

struct FlightOffer: Identifiable, Hashable, Sendable {
    let id: String
    let itineraries: [Itinerary]
    let totalPrice: Decimal
    let basePrice: Decimal?
    let currencyCode: String
    let seatsRemaining: Int?
    let validatingCarrier: Carrier
    let cabin: CabinClass?
    let includedCheckedBags: Int
    let travellerCount: Int

    var outbound: Itinerary? {
        itineraries.first
    }

    var inbound: Itinerary? {
        itineraries.count > 1 ? itineraries[1] : nil
    }

    var totalDuration: TimeInterval {
        itineraries.reduce(0) { $0 + $1.duration }
    }

    var stopCount: Int {
        outbound?.stopCount ?? 0
    }

    var isDirect: Bool {
        itineraries.allSatisfy { $0.stopCount == 0 }
    }

    var operatingCarriers: Set<Carrier> {
        Set(itineraries.flatMap { $0.segments.map(\.carrier) })
    }

    var pricePerTraveller: Decimal {
        travellerCount > 0 ? totalPrice / Decimal(travellerCount) : totalPrice
    }

    var includesCheckedBag: Bool {
        includedCheckedBags > 0
    }
}
