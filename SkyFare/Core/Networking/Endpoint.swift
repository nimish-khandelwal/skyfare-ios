//
//  Endpoint.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// A single API operation, independent of how it is transported.
struct Endpoint: Sendable, Equatable {
    var path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?
    var requiresAuthorization: Bool = true

    func urlRequest(relativeTo baseURL: URL, accessToken: String?) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        return request
    }
}
