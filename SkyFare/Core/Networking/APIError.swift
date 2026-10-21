//
//  APIError.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// One entry from an Amadeus error envelope.
struct AmadeusErrorDetail: Decodable, Sendable, Equatable {
    let status: Int?
    let code: Int?
    let title: String?
    let detail: String?
}

struct AmadeusErrorEnvelope: Decodable, Sendable, Equatable {
    let errors: [AmadeusErrorDetail]
}

enum APIError: Error, Sendable, Equatable {
    case invalidURL
    case missingCredentials
    case transport(String)
    case decoding(String)
    case unauthorized
    case rateLimited(retryAfter: TimeInterval?)
    case server(status: Int, details: [AmadeusErrorDetail])
    case unexpectedResponse
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "We could not build a valid request."
        case .missingCredentials:
            return "Amadeus API credentials are missing. Add them to Config/Secrets.xcconfig."
        case .transport(let message):
            return "Network problem: \(message)"
        case .decoding:
            return "The server sent a response we could not read."
        case .unauthorized:
            return "Your API credentials were rejected."
        case .rateLimited:
            return "Too many requests. Please try again in a moment."
        case .server(let status, let details):
            let described = details.compactMap { $0.detail ?? $0.title }
            return described.isEmpty ? "The server returned an error (\(status))." : described.joined(separator: "\n")
        case .unexpectedResponse:
            return "The server sent something unexpected."
        }
    }
}
