//
//  AirportRepository.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

protocol AirportRepository: Sendable {
    func airports(matching keyword: String) async throws -> [Airport]
}

struct AmadeusAirportRepository: AirportRepository {
    static let minimumKeywordLength = 2

    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func airports(matching keyword: String) async throws -> [Airport] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumKeywordLength else { return [] }

        let endpoint = Endpoint(
            path: "v1/reference-data/locations",
            queryItems: [
                URLQueryItem(name: "subType", value: "AIRPORT,CITY"),
                URLQueryItem(name: "keyword", value: trimmed),
                URLQueryItem(name: "page[limit]", value: "12"),
                URLQueryItem(name: "sort", value: "analytics.travelers.score"),
                URLQueryItem(name: "view", value: "LIGHT")
            ]
        )

        let response = try await client.send(endpoint, as: LocationSearchResponse.self)
        return response.data.compactMap(\.asAirport)
    }
}
