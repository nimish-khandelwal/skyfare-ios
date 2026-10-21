//
//  StaticAccessTokenProviderTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class StaticAccessTokenProviderTests: XCTestCase {
    func test_returnsTheConfiguredToken() async throws {
        let provider = StaticAccessTokenProvider(token: "token-under-test")

        let token = try await provider.accessToken()

        XCTAssertEqual(token, "token-under-test")
    }

    func test_returnsTheSameTokenEveryTime() async throws {
        let provider = StaticAccessTokenProvider(token: "token-under-test")

        let first = try await provider.accessToken()
        let second = try await provider.accessToken()

        XCTAssertEqual(first, second)
    }

    func test_throwsWhenTokenIsMissing() async {
        let provider = StaticAccessTokenProvider(token: "")

        do {
            _ = try await provider.accessToken()
            XCTFail("Expected missing credentials error")
        } catch {
            XCTAssertEqual(error as? APIError, .missingCredentials)
        }
    }

    func test_invalidateIsHarmlessForALongLivedToken() async throws {
        let provider = StaticAccessTokenProvider(token: "token-under-test")

        await provider.invalidate()

        let token = try await provider.accessToken()
        XCTAssertEqual(token, "token-under-test")
    }
}
