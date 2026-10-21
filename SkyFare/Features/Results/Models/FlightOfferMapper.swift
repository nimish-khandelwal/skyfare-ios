//
//  FlightOfferMapper.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Turns an Amadeus offer payload into the model the UI renders, resolving the code
/// dictionaries the API returns alongside the offers.
struct FlightOfferMapper: Sendable {
    private let carriers: [String: String]
    private let aircraft: [String: String]

    init(dictionaries: AmadeusDictionaries?) {
        carriers = dictionaries?.carriers ?? [:]
        aircraft = dictionaries?.aircraft ?? [:]
    }

    func map(_ payloads: [FlightOfferPayload]) -> [FlightOffer] {
        payloads.compactMap(map)
    }

    func map(_ payload: FlightOfferPayload) -> FlightOffer? {
        guard let totalPrice = Decimal(string: payload.price.grandTotal ?? payload.price.total) else {
            return nil
        }

        let itineraries = payload.itineraries.enumerated().map { index, itinerary in
            map(itinerary, id: index)
        }

        guard !itineraries.isEmpty else { return nil }

        let fareDetails = payload.travelerPricings?.first?.fareDetailsBySegment
        let cabinCode = fareDetails?.first?.cabin ?? ""

        return FlightOffer(
            id: payload.id,
            itineraries: itineraries,
            totalPrice: totalPrice,
            basePrice: payload.price.base.flatMap { Decimal(string: $0) },
            currencyCode: payload.price.currency,
            seatsRemaining: payload.numberOfBookableSeats,
            validatingCarrier: carrier(for: payload.validatingAirlineCodes?.first
                ?? payload.itineraries.first?.segments.first?.carrierCode ?? ""),
            cabin: CabinClass(rawValue: cabinCode),
            includedCheckedBags: fareDetails?
                .compactMap { $0.includedCheckedBags?.quantity }
                .min() ?? 0,
            travellerCount: payload.travelerPricings?.count ?? 1
        )
    }

    private func map(_ payload: ItineraryPayload, id: Int) -> Itinerary {
        let segments = payload.segments.map(map)
        let declaredDuration = payload.duration.flatMap(ISO8601Duration.seconds(from:))
        let summedDuration = segments.reduce(0) { $0 + $1.duration }

        return Itinerary(
            id: id,
            duration: declaredDuration ?? summedDuration,
            segments: segments
        )
    }

    private func map(_ payload: SegmentPayload) -> FlightSegment {
        let fallbackDuration = payload.arrival.at.timeIntervalSince(payload.departure.at)

        return FlightSegment(
            id: payload.id,
            departure: SegmentPoint(
                iataCode: payload.departure.iataCode,
                terminal: payload.departure.terminal,
                date: payload.departure.at
            ),
            arrival: SegmentPoint(
                iataCode: payload.arrival.iataCode,
                terminal: payload.arrival.terminal,
                date: payload.arrival.at
            ),
            carrier: carrier(for: payload.carrierCode),
            flightNumber: payload.number,
            aircraftName: payload.aircraft?.code.flatMap { aircraft[$0]?.capitalizedWords },
            duration: payload.duration.flatMap(ISO8601Duration.seconds(from:)) ?? max(0, fallbackDuration),
            technicalStops: payload.numberOfStops ?? 0
        )
    }

    private func carrier(for code: String) -> Carrier {
        Carrier(code: code, name: carriers[code]?.capitalizedWords ?? "")
    }
}
