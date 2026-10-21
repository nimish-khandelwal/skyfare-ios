//
//  RootView.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import SwiftUI

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var searchViewModel: FlightSearchViewModel

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _searchViewModel = StateObject(
            wrappedValue: FlightSearchViewModel(
                airportRepository: dependencies.airportRepository,
                offerRepository: dependencies.offerRepository
            )
        )
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            FlightSearchView(
                viewModel: searchViewModel,
                isUsingSampleData: dependencies.isUsingSampleData
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case let .results(query, offers):
                    FlightResultsView(query: query, offers: offers)
                }
            }
        }
        .environmentObject(coordinator)
    }
}

#Preview {
    RootView(dependencies: .sample)
}
