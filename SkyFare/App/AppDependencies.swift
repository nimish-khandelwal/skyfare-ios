//
//  AppDependencies.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Builds the object graph once at launch and hands it to the views.
struct AppDependencies: Sendable {
    let airportRepository: AirportRepository
    let offerRepository: FlightOfferRepository
    let isUsingSampleData: Bool

    static func live(
        configuration: AppConfiguration = .resolved(),
        session: HTTPSession = URLSession.shared
    ) -> AppDependencies {
        guard configuration.hasCredentials else {
            return .sample
        }

        let tokenProvider = AmadeusTokenProvider(session: session, configuration: configuration)
        let client = AmadeusAPIClient(
            session: session,
            configuration: configuration,
            tokenProvider: tokenProvider,
            decoder: .amadeus
        )

        return AppDependencies(
            airportRepository: AmadeusAirportRepository(client: client),
            offerRepository: AmadeusFlightOfferRepository(client: client),
            isUsingSampleData: false
        )
    }

    static let sample = AppDependencies(
        airportRepository: SampleAirportRepository(),
        offerRepository: SampleFlightOfferRepository(),
        isUsingSampleData: true
    )
}
