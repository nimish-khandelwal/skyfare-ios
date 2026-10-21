//
//  FlightOfferMapper.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Turns a provider payload into the model the UI renders.
///
/// Everything provider-specific stops here: nothing above this type knows which flight API
/// the data came from.
struct FlightOfferMapper: Sendable {
    func map(_ payloads: [OfferPayload]) -> [FlightOffer] {
        payloads.compactMap(map)
    }

    func map(_ payload: OfferPayload) -> FlightOffer? {
        guard let totalPrice = Decimal(string: payload.totalAmount) else {
            return nil
        }

        let itineraries = payload.slices.enumerated().map { index, slice in
            map(slice, id: index)
        }

        guard !itineraries.isEmpty, itineraries.allSatisfy({ !$0.segments.isEmpty }) else {
            return nil
        }

        let segmentPassengers = payload.slices
            .flatMap(\.segments)
            .map { $0.passengers ?? [] }

        return FlightOffer(
            id: payload.id,
            itineraries: itineraries,
            totalPrice: totalPrice,
            basePrice: payload.baseAmount.flatMap { Decimal(string: $0) },
            currencyCode: payload.totalCurrency,
            seatsRemaining: nil,
            validatingCarrier: carrier(
                from: payload.owner,
                fallback: payload.slices.first?.segments.first?.marketingCarrier
            ),
            cabin: cabinClass(from: segmentPassengers),
            includedCheckedBags: checkedBags(from: segmentPassengers),
            travellerCount: max(1, payload.passengers?.count ?? 1)
        )
    }

    private func map(_ payload: SlicePayload, id: Int) -> Itinerary {
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
        let fallbackDuration = payload.arrivingAt.timeIntervalSince(payload.departingAt)

        return FlightSegment(
            id: payload.id,
            departure: SegmentPoint(
                iataCode: payload.origin.iataCode ?? "",
                terminal: nil,
                date: payload.departingAt
            ),
            arrival: SegmentPoint(
                iataCode: payload.destination.iataCode ?? "",
                terminal: nil,
                date: payload.arrivingAt
            ),
            carrier: carrier(from: payload.marketingCarrier, fallback: payload.operatingCarrier),
            flightNumber: payload.marketingCarrierFlightNumber ?? "",
            aircraftName: payload.aircraft?.name,
            duration: payload.duration.flatMap(ISO8601Duration.seconds(from:)) ?? max(0, fallbackDuration),
            technicalStops: payload.stops?.count ?? 0
        )
    }

    private func carrier(
        from primary: OfferPayload.Carrier?,
        fallback: OfferPayload.Carrier?
    ) -> Carrier {
        let source = primary ?? fallback

        return Carrier(
            code: source?.iataCode ?? "",
            name: source?.name ?? ""
        )
    }

    private func cabinClass(from segmentPassengers: [[SegmentPayload.SegmentPassenger]]) -> CabinClass? {
        segmentPassengers
            .flatMap { $0 }
            .compactMap(\.cabinClass)
            .compactMap(CabinClass.init(rawValue:))
            .first
    }

    /// An offer only counts as including a checked bag when every segment allows one.
    private func checkedBags(from segmentPassengers: [[SegmentPayload.SegmentPassenger]]) -> Int {
        let perSegment = segmentPassengers.map { passengers in
            passengers
                .flatMap { $0.baggages ?? [] }
                .filter { $0.type == "checked" }
                .reduce(0) { $0 + ($1.quantity ?? 0) }
        }

        return perSegment.min() ?? 0
    }
}
