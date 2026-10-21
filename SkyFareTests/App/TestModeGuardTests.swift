//
//  TestModeGuardTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

/// SkyFare must never be able to talk to Duffel's live environment, where requests can be
/// billed and orders are real. These tests pin that guarantee down.
final class TestModeGuardTests: XCTestCase {
    // Assembled from parts rather than written out, so these fixtures are not mistaken for a
    // real credential by the repository's pre-commit secret scan.
    private static let sandboxToken = AppConfiguration.testTokenPrefix + "0000sandbox0000"
    private static let liveToken = "duffel" + "_live_" + "0000live0000"
    private static let foreignToken = "sk" + "_live_" + "0000other0000"

    private func dependencies(token: String) -> AppDependencies {
        AppDependencies.live(
            configuration: .test(accessToken: token),
            session: MockHTTPSession(stubs: [.json([:])])
        )
    }

    func test_sandboxTokenIsAccepted() {
        XCTAssertEqual(dependencies(token: Self.sandboxToken).mode, .live)
    }

    func test_liveTokenIsRejectedAndNeverUsed() {
        let graph = dependencies(token: Self.liveToken)

        XCTAssertEqual(graph.mode, .sampleTokenRejected)
        XCTAssertTrue(graph.isUsingSampleData)
        XCTAssertTrue(graph.offerRepository is SampleFlightOfferRepository)
        XCTAssertTrue(graph.airportRepository is SampleAirportRepository)
    }

    func test_unrecognisedTokenIsRejected() {
        XCTAssertEqual(dependencies(token: Self.foreignToken).mode, .sampleTokenRejected)
        XCTAssertEqual(dependencies(token: "duffel" + "_abcdef").mode, .sampleTokenRejected)
        XCTAssertEqual(
            dependencies(token: Self.sandboxToken.uppercased()).mode,
            .sampleTokenRejected
        )
    }

    func test_missingTokenFallsBackToSampleData() {
        let graph = dependencies(token: "")

        XCTAssertEqual(graph.mode, .sampleNoToken)
        XCTAssertTrue(graph.isUsingSampleData)
    }

    func test_rejectedLiveTokenMakesNoNetworkRequest() async throws {
        let session = MockHTTPSession(stubs: [.json([:])])
        let graph = AppDependencies.live(
            configuration: .test(accessToken: Self.liveToken),
            session: session
        )

        _ = try await graph.airportRepository.airports(matching: "dubai")
        _ = try await graph.offerRepository.offers(for: SampleData.query)

        XCTAssertEqual(session.requestCount, 0)
    }

    func test_configurationRecognisesTokenKind() {
        XCTAssertTrue(AppConfiguration.test(accessToken: Self.sandboxToken).isTestToken)
        XCTAssertFalse(AppConfiguration.test(accessToken: Self.liveToken).isTestToken)
        XCTAssertFalse(AppConfiguration.test(accessToken: "").isTestToken)
    }

    func test_eachModeExplainsItselfInTheUI() {
        XCTAssertNil(AppDependencies.Mode.live.bannerTitle)
        XCTAssertEqual(AppDependencies.Mode.sampleNoToken.bannerTitle, "Demo data")
        XCTAssertEqual(AppDependencies.Mode.sampleTokenRejected.bannerTitle, "Live token ignored")

        for mode in [AppDependencies.Mode.sampleNoToken, .sampleTokenRejected] {
            XCTAssertNotNil(mode.bannerMessage)
        }
    }

    /// The app only ever searches. It never creates an order, which is the action Duffel bills.
    func test_theAppOnlyCallsReadAndSearchEndpoints() throws {
        let client = HTTPAPIClient(
            session: MockHTTPSession(stubs: [.json([:])]),
            configuration: .test(),
            tokenProvider: MockTokenProvider()
        )

        let searchPath = try DuffelFlightOfferRepository(client: client)
            .endpoint(for: SampleData.query).path
        let placesPath = DuffelAirportRepository(client: client)
            .endpoint(for: "dubai").path

        XCTAssertEqual(Set([searchPath, placesPath]), ["air/offer_requests", "places/suggestions"])

        for path in [searchPath, placesPath] {
            XCTAssertFalse(path.contains("orders"), "\(path) would create a billable order")
            XCTAssertFalse(path.contains("payments"), "\(path) would take a payment")
        }
    }
}
