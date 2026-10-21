//
//  AppDependencies.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Builds the object graph once at launch and hands it to the views.
struct AppDependencies: Sendable {
    /// Why the app is showing the data it is showing.
    enum Mode: Equatable, Sendable {
        case live
        case sampleNoToken
        case sampleTokenRejected
    }

    let airportRepository: AirportRepository
    let offerRepository: FlightOfferRepository
    let mode: Mode

    var isUsingSampleData: Bool {
        mode != .live
    }

    static func live(
        configuration: AppConfiguration = .resolved(),
        session: HTTPSession = URLSession.shared
    ) -> AppDependencies {
        guard configuration.hasCredentials else {
            return .sample(reason: .sampleNoToken)
        }

        // Only a Duffel sandbox token is ever accepted. A live token is ignored rather than
        // used, so no request from this app can reach real inventory or be billed.
        guard configuration.isTestToken else {
            return .sample(reason: .sampleTokenRejected)
        }

        let client = HTTPAPIClient(
            session: session,
            configuration: configuration,
            tokenProvider: StaticAccessTokenProvider(token: configuration.accessToken),
            decoder: .flightProvider
        )

        return AppDependencies(
            airportRepository: DuffelAirportRepository(client: client),
            offerRepository: DuffelFlightOfferRepository(client: client),
            mode: .live
        )
    }

    static func sample(reason: Mode = .sampleNoToken) -> AppDependencies {
        AppDependencies(
            airportRepository: SampleAirportRepository(),
            offerRepository: SampleFlightOfferRepository(),
            mode: reason
        )
    }

    static let sample = AppDependencies.sample(reason: .sampleNoToken)
}

extension AppDependencies.Mode {
    var bannerTitle: String? {
        switch self {
        case .live: return nil
        case .sampleNoToken: return "Demo data"
        case .sampleTokenRejected: return "Live token ignored"
        }
    }

    var bannerMessage: String? {
        switch self {
        case .live:
            return nil
        case .sampleNoToken:
            return "Add a Duffel test token to Config/Secrets.xcconfig for live flights."
        case .sampleTokenRejected:
            return "SkyFare only accepts a duffel_test_ sandbox token, so this one was not used."
        }
    }
}
