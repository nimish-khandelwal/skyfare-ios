//
//  APIError.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// One entry from the provider's error envelope.
struct APIErrorDetail: Decodable, Sendable, Equatable {
    let type: String?
    let title: String?
    let message: String?
    let code: String?

    var displayText: String? {
        message ?? title
    }
}

struct APIErrorEnvelope: Decodable, Sendable, Equatable {
    let errors: [APIErrorDetail]
}

enum APIError: Error, Sendable, Equatable {
    case invalidURL
    case missingCredentials
    case transport(String)
    case decoding(String)
    case unauthorized
    case rateLimited(retryAfter: TimeInterval?)
    case server(status: Int, details: [APIErrorDetail])
    case unexpectedResponse
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "We could not build a valid request."
        case .missingCredentials:
            return "A Duffel access token is missing. Add one to Config/Secrets.xcconfig."
        case .transport(let message):
            return "Network problem: \(message)"
        case .decoding:
            return "The server sent a response we could not read."
        case .unauthorized:
            return "Your access token was rejected."
        case .rateLimited:
            return "Too many requests. Please try again in a moment."
        case .server(let status, let details):
            let described = details.compactMap(\.displayText)
            return described.isEmpty ? "The server returned an error (\(status))." : described.joined(separator: "\n")
        case .unexpectedResponse:
            return "The server sent something unexpected."
        }
    }
}
