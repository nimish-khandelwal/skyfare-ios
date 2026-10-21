//
//  AmadeusTokenProvider.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

struct AmadeusToken: Sendable, Equatable {
    let value: String
    let expiresAt: Date

    func isValid(at date: Date, refreshMargin: TimeInterval) -> Bool {
        date.addingTimeInterval(refreshMargin) < expiresAt
    }
}

private struct TokenResponse: Decodable, Sendable {
    let accessToken: String
    let expiresIn: TimeInterval

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

/// Fetches and caches the Amadeus OAuth2 client-credentials token.
///
/// Concurrent callers share a single in-flight refresh instead of each triggering their own.
actor AmadeusTokenProvider: AccessTokenProviding {
    private let session: HTTPSession
    private let configuration: AppConfiguration
    private let refreshMargin: TimeInterval
    private let now: @Sendable () -> Date

    private var cachedToken: AmadeusToken?
    private var refreshTask: Task<AmadeusToken, Error>?

    init(
        session: HTTPSession,
        configuration: AppConfiguration,
        refreshMargin: TimeInterval = 60,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.session = session
        self.configuration = configuration
        self.refreshMargin = refreshMargin
        self.now = now
    }

    func accessToken() async throws -> String {
        if let cachedToken, cachedToken.isValid(at: now(), refreshMargin: refreshMargin) {
            return cachedToken.value
        }

        if let refreshTask {
            return try await refreshTask.value.value
        }

        let task = Task<AmadeusToken, Error> { [configuration, session] in
            try await Self.requestToken(session: session, configuration: configuration, now: now)
        }
        refreshTask = task

        do {
            let token = try await task.value
            cachedToken = token
            refreshTask = nil
            return token.value
        } catch {
            refreshTask = nil
            throw error
        }
    }

    func invalidate() {
        cachedToken = nil
    }

    private static func requestToken(
        session: HTTPSession,
        configuration: AppConfiguration,
        now: @Sendable () -> Date
    ) async throws -> AmadeusToken {
        guard configuration.hasCredentials else {
            throw APIError.missingCredentials
        }

        let endpoint = Endpoint(
            path: "v1/security/oauth2/token",
            method: .post,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: formBody(configuration: configuration),
            requiresAuthorization: false
        )

        let request = try endpoint.urlRequest(relativeTo: configuration.baseURL, accessToken: nil)

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

        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.server(status: http.statusCode, details: Self.decodeErrorDetails(from: data))
        }

        do {
            let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
            return AmadeusToken(
                value: decoded.accessToken,
                expiresAt: now().addingTimeInterval(decoded.expiresIn)
            )
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    private static func formBody(configuration: AppConfiguration) -> Data {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "client_secret", value: configuration.clientSecret)
        ]
        return Data((components.percentEncodedQuery ?? "").utf8)
    }

    private static func decodeErrorDetails(from data: Data) -> [AmadeusErrorDetail] {
        (try? JSONDecoder().decode(AmadeusErrorEnvelope.self, from: data))?.errors ?? []
    }
}
