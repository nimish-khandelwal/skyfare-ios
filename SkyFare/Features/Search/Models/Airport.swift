//
//  Airport.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

struct Airport: Identifiable, Hashable, Sendable {
    enum Kind: String, Sendable {
        case airport
        case city
        case unknown
    }

    let id: String
    let iataCode: String
    let name: String
    let cityName: String
    let countryCode: String
    let kind: Kind

    var displayTitle: String {
        "\(cityName) (\(iataCode))"
    }

    var displaySubtitle: String {
        countryCode.isEmpty ? name : "\(name) · \(countryCode)"
    }
}

struct PlacePayload: Decodable, Sendable {
    let id: String?
    let type: String?
    let name: String?
    let iataCode: String?
    let iataCityCode: String?
    let cityName: String?
    let iataCountryCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
        case iataCode = "iata_code"
        case iataCityCode = "iata_city_code"
        case cityName = "city_name"
        case iataCountryCode = "iata_country_code"
    }
}

extension PlacePayload {
    var asAirport: Airport? {
        guard let iataCode, !iataCode.isEmpty else { return nil }

        return Airport(
            id: id ?? iataCode,
            iataCode: iataCode,
            name: name ?? iataCode,
            cityName: cityName ?? name ?? iataCode,
            countryCode: iataCountryCode ?? "",
            kind: Airport.Kind(rawValue: type ?? "") ?? .unknown
        )
    }
}
