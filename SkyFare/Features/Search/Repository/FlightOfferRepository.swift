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

struct AmadeusFlightOfferRepository: FlightOfferRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func offers(for query: FlightSearchQuery) async throws -> [FlightOffer] {
        let response = try await client.send(endpoint(for: query), as: FlightOffersResponse.self)
        let mapper = FlightOfferMapper(dictionaries: response.dictionaries)
        return mapper.map(response.data)
    }

    func endpoint(for query: FlightSearchQuery) -> Endpoint {
        let formatter = AmadeusDateFormat.formatter(AmadeusDateFormat.dateOnly)

        var queryItems = [
            URLQueryItem(name: "originLocationCode", value: query.origin.iataCode),
            URLQueryItem(name: "destinationLocationCode", value: query.destination.iataCode),
            URLQueryItem(name: "departureDate", value: formatter.string(from: query.departureDate)),
            URLQueryItem(name: "adults", value: String(query.passengers.adults)),
            URLQueryItem(name: "travelClass", value: query.cabin.rawValue),
            URLQueryItem(name: "currencyCode", value: query.currencyCode),
            URLQueryItem(name: "max", value: String(query.maximumResults))
        ]

        if let returnDate = query.returnDate {
            queryItems.append(URLQueryItem(name: "returnDate", value: formatter.string(from: returnDate)))
        }
        if query.passengers.children > 0 {
            queryItems.append(URLQueryItem(name: "children", value: String(query.passengers.children)))
        }
        if query.passengers.infants > 0 {
            queryItems.append(URLQueryItem(name: "infants", value: String(query.passengers.infants)))
        }

        return Endpoint(path: "v2/shopping/flight-offers", queryItems: queryItems)
    }
}
