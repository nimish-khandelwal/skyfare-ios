//
//  APIClient.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Sends an `Endpoint` and decodes its response.
protocol APIClient: Sendable {
    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as responseType: Response.Type
    ) async throws -> Response
}

extension APIClient {
    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> Response {
        try await send(endpoint, as: Response.self)
    }
}

struct AmadeusAPIClient: APIClient {
    private let session: HTTPSession
    private let configuration: AppConfiguration
    private let tokenProvider: AccessTokenProviding
    private let decoder: JSONDecoder

    init(
        session: HTTPSession,
        configuration: AppConfiguration,
        tokenProvider: AccessTokenProviding,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.configuration = configuration
        self.tokenProvider = tokenProvider
        self.decoder = decoder
    }

    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        do {
            return try await perform(endpoint, as: responseType)
        } catch APIError.unauthorized where endpoint.requiresAuthorization {
            await tokenProvider.invalidate()
            return try await perform(endpoint, as: responseType)
        }
    }

    private func perform<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        let token = endpoint.requiresAuthorization ? try await tokenProvider.accessToken() : nil
        let request = try endpoint.urlRequest(relativeTo: configuration.baseURL, accessToken: token)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.send(request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }

        try validate(http, data: data)

        do {
            return try decoder.decode(responseType, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    private func validate(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200..<300:
            return
        case 401:
            throw APIError.unauthorized
        case 429:
            let header = response.value(forHTTPHeaderField: "Retry-After")
            throw APIError.rateLimited(retryAfter: header.flatMap(TimeInterval.init))
        default:
            let details = (try? decoder.decode(AmadeusErrorEnvelope.self, from: data))?.errors ?? []
            throw APIError.server(status: response.statusCode, details: details)
        }
    }
}
