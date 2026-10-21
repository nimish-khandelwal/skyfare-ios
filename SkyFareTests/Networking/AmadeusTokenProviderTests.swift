//
//  AmadeusTokenProviderTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class AmadeusTokenProviderTests: XCTestCase {
    private func makeProvider(
        session: MockHTTPSession,
        configuration: AppConfiguration = .test(),
        clock: @escaping @Sendable () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> AmadeusTokenProvider {
        AmadeusTokenProvider(
            session: session,
            configuration: configuration,
            refreshMargin: 60,
            now: clock
        )
    }

    func test_fetchesAndReturnsToken() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("token"))])
        let provider = makeProvider(session: session)

        let token = try await provider.accessToken()

        XCTAssertEqual(token, "token-abc-123")
        XCTAssertEqual(session.requestCount, 1)
    }

    func test_sendsFormEncodedClientCredentials() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("token"))])
        let provider = makeProvider(session: session, configuration: .test(clientID: "abc", clientSecret: "shh"))

        _ = try await provider.accessToken()

        let request = try XCTUnwrap(session.requests.first)
        let body = String(decoding: try XCTUnwrap(request.httpBody), as: UTF8.self)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/v1/security/oauth2/token")
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "application/x-www-form-urlencoded"
        )
        XCTAssertTrue(body.contains("grant_type=client_credentials"), body)
        XCTAssertTrue(body.contains("client_id=abc"), body)
        XCTAssertTrue(body.contains("client_secret=shh"), body)
    }

    func test_reusesCachedTokenWhileValid() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("token"))])
        let provider = makeProvider(session: session)

        _ = try await provider.accessToken()
        _ = try await provider.accessToken()
        _ = try await provider.accessToken()

        XCTAssertEqual(session.requestCount, 1)
    }

    func test_refetchesOnceTokenIsInsideRefreshMargin() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("token"))])
        let clock = MutableClock(now: Date(timeIntervalSince1970: 0))
        let provider = makeProvider(session: session, clock: { clock.value })

        _ = try await provider.accessToken()
        clock.value = Date(timeIntervalSince1970: 1_799)
        _ = try await provider.accessToken()

        XCTAssertEqual(session.requestCount, 2)
    }

    func test_invalidateForcesRefresh() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("token"))])
        let provider = makeProvider(session: session)

        _ = try await provider.accessToken()
        await provider.invalidate()
        _ = try await provider.accessToken()

        XCTAssertEqual(session.requestCount, 2)
    }

    func test_concurrentCallersShareOneRefresh() async throws {
        let session = MockHTTPSession(stubs: [.success(try Fixture.data("token"))])
        let provider = makeProvider(session: session)

        let tokens = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<8 {
                group.addTask { try await provider.accessToken() }
            }
            return try await group.reduce(into: [String]()) { $0.append($1) }
        }

        XCTAssertEqual(tokens.count, 8)
        XCTAssertTrue(tokens.allSatisfy { $0 == "token-abc-123" })
        XCTAssertEqual(session.requestCount, 1)
    }

    func test_throwsWhenCredentialsMissing() async {
        let session = MockHTTPSession(stubs: [.json([:])])
        let provider = makeProvider(
            session: session,
            configuration: .test(clientID: "", clientSecret: "")
        )

        do {
            _ = try await provider.accessToken()
            XCTFail("Expected missing credentials error")
        } catch {
            XCTAssertEqual(error as? APIError, .missingCredentials)
            XCTAssertEqual(session.requestCount, 0)
        }
    }

    func test_mapsRejectedCredentialsToUnauthorized() async {
        let session = MockHTTPSession(stubs: [.json(["error": "invalid_client"], statusCode: 401)])
        let provider = makeProvider(session: session)

        do {
            _ = try await provider.accessToken()
            XCTFail("Expected unauthorized error")
        } catch {
            XCTAssertEqual(error as? APIError, .unauthorized)
        }
    }

    func test_doesNotCacheFailedRefresh() async throws {
        let session = MockHTTPSession(
            stubs: [
                .json(["error": "server"], statusCode: 500),
                .success(try Fixture.data("token"))
            ],
            repeatsLastStub: false
        )
        let provider = makeProvider(session: session)

        do {
            _ = try await provider.accessToken()
            XCTFail("Expected first refresh to fail")
        } catch {
            XCTAssertNotNil(error)
        }

        let token = try await provider.accessToken()
        XCTAssertEqual(token, "token-abc-123")
        XCTAssertEqual(session.requestCount, 2)
    }
}

private final class MutableClock: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Date

    init(now: Date) {
        storage = now
    }

    var value: Date {
        get { lock.withLock { storage } }
        set { lock.withLock { storage = newValue } }
    }
}
