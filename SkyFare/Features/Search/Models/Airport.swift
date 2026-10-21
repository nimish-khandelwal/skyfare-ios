//
//  Airport.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

struct Airport: Identifiable, Hashable, Sendable {
    enum Kind: String, Sendable {
        case airport = "AIRPORT"
        case city = "CITY"
        case unknown
    }

    let id: String
    let iataCode: String
    let name: String
    let cityName: String
    let countryName: String
    let kind: Kind

    var displayTitle: String {
        "\(cityName) (\(iataCode))"
    }

    var displaySubtitle: String {
        name.capitalizedWords
    }
}

struct LocationSearchResponse: Decodable, Sendable {
    let data: [LocationPayload]
}

struct LocationPayload: Decodable, Sendable {
    struct Address: Decodable, Sendable {
        let cityName: String?
        let countryName: String?
    }

    let id: String?
    let subType: String?
    let name: String?
    let detailedName: String?
    let iataCode: String?
    let address: Address?
}

extension LocationPayload {
    var asAirport: Airport? {
        guard let iataCode, !iataCode.isEmpty else { return nil }

        return Airport(
            id: id ?? iataCode,
            iataCode: iataCode,
            name: (name ?? detailedName ?? iataCode).capitalizedWords,
            cityName: (address?.cityName ?? name ?? iataCode).capitalizedWords,
            countryName: (address?.countryName ?? "").capitalizedWords,
            kind: Airport.Kind(rawValue: subType ?? "") ?? .unknown
        )
    }
}

extension String {
    /// Amadeus returns names in upper case, which reads badly in a list.
    var capitalizedWords: String {
        split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
