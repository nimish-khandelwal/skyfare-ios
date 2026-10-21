//
//  FlightResultsViewModel.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Combine
import Foundation

@MainActor
final class FlightResultsViewModel: ObservableObject {
    @Published var sortOption: FlightSortOption = .cheapest
    @Published var filter = FlightResultsFilter()
    @Published private(set) var visibleOffers: [FlightOffer] = []

    let query: FlightSearchQuery
    private let allOffers: [FlightOffer]
    private var cancellables: Set<AnyCancellable> = []

    init(query: FlightSearchQuery, offers: [FlightOffer]) {
        self.query = query
        allOffers = offers

        Publishers.CombineLatest($sortOption, $filter)
            .map { [allOffers] sortOption, filter in
                sortOption.sort(filter.apply(to: allOffers))
            }
            .assign(to: &$visibleOffers)
    }

    var availableCarriers: [Carrier] {
        Set(allOffers.flatMap { $0.operatingCarriers })
            .sorted { $0.displayName < $1.displayName }
    }

    var cheapestPrice: Decimal? {
        allOffers.map(\.totalPrice).min()
    }

    var resultCountSummary: String {
        let total = allOffers.count
        let shown = visibleOffers.count

        if shown == total {
            return "\(total) flight\(total == 1 ? "" : "s")"
        }
        return "\(shown) of \(total) flights"
    }

    var isEmptyAfterFiltering: Bool {
        visibleOffers.isEmpty && !allOffers.isEmpty
    }

    var hasNoOffers: Bool {
        allOffers.isEmpty
    }

    func toggleCarrier(_ code: String) {
        if filter.carrierCodes.contains(code) {
            filter.carrierCodes.remove(code)
        } else {
            filter.carrierCodes.insert(code)
        }
    }

    func toggleDepartureWindow(_ window: DepartureWindow) {
        if filter.departureWindows.contains(window) {
            filter.departureWindows.remove(window)
        } else {
            filter.departureWindows.insert(window)
        }
    }

    func resetFilters() {
        filter = FlightResultsFilter()
    }
}
