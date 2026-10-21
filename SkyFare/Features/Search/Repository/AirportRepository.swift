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

struct DuffelAirportRepository: AirportRepository {
    static let minimumKeywordLength = 2

    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func airports(matching keyword: String) async throws -> [Airport] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumKeywordLength else { return [] }

        let response = try await client.send(
            endpoint(for: trimmed),
            as: DuffelEnvelope<[PlacePayload]>.self
        )

        return response.data.compactMap(\.asAirport)
    }

    func endpoint(for keyword: String) -> Endpoint {
        Endpoint(
            path: "places/suggestions",
            queryItems: [URLQueryItem(name: "query", value: keyword)]
        )
    }
}
