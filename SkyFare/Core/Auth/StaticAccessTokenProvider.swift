//
//  StaticAccessTokenProvider.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Supplies the provider's bearer token.
///
/// Duffel issues a long-lived access token rather than a refreshable OAuth2 grant, so there is
/// nothing to renew. The protocol stays in place because the API client should not care which
/// scheme a provider uses.
struct StaticAccessTokenProvider: AccessTokenProviding {
    private let token: String

    init(token: String) {
        self.token = token
    }

    func accessToken() async throws -> String {
        guard !token.isEmpty else {
            throw APIError.missingCredentials
        }
        return token
    }

    func invalidate() async {}
}
