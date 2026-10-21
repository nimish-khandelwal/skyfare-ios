//
//  AppCoordinator.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Combine
import Foundation

/// Owns the navigation stack so views never push each other directly.
@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []

    func showResults(query: FlightSearchQuery, offers: [FlightOffer]) {
        path.append(.results(query: query, offers: offers))
    }

    func popToRoot() {
        path.removeAll()
    }
}
