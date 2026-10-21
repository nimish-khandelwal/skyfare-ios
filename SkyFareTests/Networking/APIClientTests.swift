//
//  APIClientTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

private struct Probe: Decodable, Sendable, Equatable {
    let value: String
}

final class APIClientTests: XCTestCase {
    private func makeClient(
        session: MockHTTPSession,
        tokenProvider: MockTokenProvider = MockTokenProvider()
    ) -> AmadeusAPIClient {
        AmadeusAPIClient(
            session: session,
            configuration: .test(),
            tokenProvider: tokenProvider,
            decoder: .amadeus
        )
    }

    func test_decodesSuccessfulResponse() async throws {
        let session = MockHTTPSession(stubs: [.json(["value": "ok"])])
        let client = makeClient(session: session)

        let probe = try await client.send(Endpoint(path: "v1/probe"), as: Probe.self)

        XCTAssertEqual(probe, Probe(value: "ok"))
        XCTAssertEqual(session.requestCount, 1)
    }

    func test_attachesBearerTokenFromProvider() async throws {
        let session = MockHTTPSession(stubs: [.json(["value": "ok"])])
        let provider = MockTokenProvider(tokens: ["token-xyz"])
        let client = makeClient(session: session, tokenProvider: provider)

        _ = try await client.send(Endpoint(path: "v1/probe"), as: Probe.self)

        XCTAssertEqual(
            session.requests.first?.value(forHTTPHeaderField: "Authorization"),
            "Bearer token-xyz"
        )
    }

    func test_skipsTokenForUnauthenticatedEndpoint() async throws {
        let session = MockHTTPSession(stubs: [.json(["value": "ok"])])
        let provider = MockTokenProvider()
        let client = makeClient(session: session, tokenProvider: provider)

        _ = try await client.send(
            Endpoint(path: "v1/probe", requiresAuthorization: false),
            as: Probe.self
        )

        let counts = await provider.counts()
        XCTAssertEqual(counts.accessToken, 0)
        XCTAssertNil(session.requests.first?.value(forHTTPHeaderField: "Authorization"))
    }

    func test_retriesOnceAfterUnauthorized() async throws {
        let session = MockHTTPSession(
            stubs: [
                .json(["errors": []], statusCode: 401),
                .json(["value": "second"])
            ],
            repeatsLastStub: false
        )
        let provider = MockTokenProvider(tokens: ["stale", "fresh"])
        let client = makeClient(session: session, tokenProvider: provider)

        let probe = try await client.send(Endpoint(path: "v1/probe"), as: Probe.self)

        XCTAssertEqual(probe, Probe(value: "second"))
        XCTAssertEqual(session.requestCount, 2)

        let counts = await provider.counts()
        XCTAssertEqual(counts.invalidate, 1)
        XCTAssertEqual(counts.accessToken, 2)
        XCTAssertEqual(
            session.requests.last?.value(forHTTPHeaderField: "Authorization"),
            "Bearer fresh"
        )
    }

    func test_doesNotRetryMoreThanOnce() async {
        let session = MockHTTPSession(stubs: [.json(["errors": []], statusCode: 401)])
        let client = makeClient(session: session)

        do {
            _ = try await client.send(Endpoint(path: "v1/probe"), as: Probe.self)
            XCTFail("Expected unauthorized error")
        } catch {
            XCTAssertEqual(error as? APIError, .unauthorized)
            XCTAssertEqual(session.requestCount, 2)
        }
    }

    func test_mapsRateLimitingWithRetryAfter() async {
        let session = MockHTTPSession(
            stubs: [.success(Data("{}".utf8), statusCode: 429, headers: ["Retry-After": "30"])]
        )
        let client = makeClient(session: session)

        do {
            _ = try await client.send(Endpoint(path: "v1/probe"), as: Probe.self)
            XCTFail("Expected rate limit error")
        } catch {
            XCTAssertEqual(error as? APIError, .rateLimited(retryAfter: 30))
        }
    }

    func test_surfacesAmadeusErrorDetails() async throws {
        let session = MockHTTPSession(
            stubs: [.success(try Fixture.data("error-400"), statusCode: 400)]
        )
        let client = makeClient(session: session)

        do {
            _ = try await client.send(Endpoint(path: "v1/probe"), as: Probe.self)
            XCTFail("Expected server error")
        } catch let error as APIError {
            guard case let .server(status, details) = error else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertEqual(status, 400)
            XCTAssertEqual(details.first?.code, 32171)
            XCTAssertEqual(details.first?.detail, "departureDate is required")
            XCTAssertEqual(error.errorDescription, "departureDate is required")
        }
    }

    func test_wrapsTransportFailure() async {
        let session = MockHTTPSession(stubs: [.failure(MockHTTPSession.MockError.transportFailure)])
        let client = makeClient(session: session)

        do {
            _ = try await client.send(Endpoint(path: "v1/probe"), as: Probe.self)
            XCTFail("Expected transport error")
        } catch let error as APIError {
            guard case .transport = error else {
                return XCTFail("Unexpected error \(error)")
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func test_wrapsDecodingFailure() async {
        let session = MockHTTPSession(stubs: [.json(["unexpected": 1])])
        let client = makeClient(session: session)

        do {
            _ = try await client.send(Endpoint(path: "v1/probe"), as: Probe.self)
            XCTFail("Expected decoding error")
        } catch let error as APIError {
            guard case .decoding = error else {
                return XCTFail("Unexpected error \(error)")
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
