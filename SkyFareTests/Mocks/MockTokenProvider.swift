//
//  MockTokenProvider.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation
@testable import SkyFare

actor MockTokenProvider: AccessTokenProviding {
    private(set) var accessTokenCallCount = 0
    private(set) var invalidateCallCount = 0

    private var tokens: [String]
    private var error: Error?

    init(tokens: [String] = ["token-1"], error: Error? = nil) {
        self.tokens = tokens
        self.error = error
    }

    func accessToken() async throws -> String {
        accessTokenCallCount += 1

        if let error {
            throw error
        }
        if tokens.count > 1 {
            return tokens.removeFirst()
        }
        return tokens.first ?? "token"
    }

    func invalidate() {
        invalidateCallCount += 1
    }

    func counts() -> (accessToken: Int, invalidate: Int) {
        (accessTokenCallCount, invalidateCallCount)
    }
}
