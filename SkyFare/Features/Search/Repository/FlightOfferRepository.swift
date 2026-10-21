//
//  FlightOfferRepository.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

protocol FlightOfferRepository: Sendable {
    func offers(for query: FlightSearchQuery) async throws -> [FlightOffer]
}

/// Duffel searches by creating an offer request and asking for the offers inline.
struct DuffelFlightOfferRepository: FlightOfferRepository {
    private let client: APIClient
    private let mapper = FlightOfferMapper()

    init(client: APIClient) {
        self.client = client
    }

    func offers(for query: FlightSearchQuery) async throws -> [FlightOffer] {
        let response = try await client.send(
            try endpoint(for: query),
            as: DuffelEnvelope<OfferRequestPayload>.self
        )

        return Array(mapper.map(response.data.offers).prefix(query.maximumResults))
    }

    func endpoint(for query: FlightSearchQuery) throws -> Endpoint {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let body: Data
        do {
            body = try encoder.encode(OfferRequestBody(query: query))
        } catch {
            throw APIError.decoding(String(describing: error))
        }

        return Endpoint(
            path: "air/offer_requests",
            method: .post,
            queryItems: [URLQueryItem(name: "return_offers", value: "true")],
            body: body
        )
    }
}

struct OfferRequestBody: Encodable, Sendable {
    struct Slice: Encodable, Sendable {
        let origin: String
        let destination: String
        let departureDate: String

        enum CodingKeys: String, CodingKey {
            case origin
            case destination
            case departureDate = "departure_date"
        }
    }

    struct Passenger: Encodable, Sendable {
        let type: String
    }

    struct Payload: Encodable, Sendable {
        let slices: [Slice]
        let passengers: [Passenger]
        let cabinClass: String
        let maxConnections: Int

        enum CodingKeys: String, CodingKey {
            case slices
            case passengers
            case cabinClass = "cabin_class"
            case maxConnections = "max_connections"
        }
    }

    let data: Payload

    init(query: FlightSearchQuery) {
        let formatter = APIDateFormat.formatter(APIDateFormat.dateOnly)

        var slices = [
            Slice(
                origin: query.origin.iataCode,
                destination: query.destination.iataCode,
                departureDate: formatter.string(from: query.departureDate)
            )
        ]

        if let returnDate = query.returnDate {
            slices.append(
                Slice(
                    origin: query.destination.iataCode,
                    destination: query.origin.iataCode,
                    departureDate: formatter.string(from: returnDate)
                )
            )
        }

        var passengers = Array(
            repeating: Passenger(type: "adult"),
            count: query.passengers.adults
        )
        passengers += Array(repeating: Passenger(type: "child"), count: query.passengers.children)
        passengers += Array(
            repeating: Passenger(type: "infant_without_seat"),
            count: query.passengers.infants
        )

        data = Payload(
            slices: slices,
            passengers: passengers,
            cabinClass: query.cabin.rawValue,
            maxConnections: 1
        )
    }
}
