//
//  FlightResultsFiltering.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

enum FlightSortOption: String, CaseIterable, Identifiable, Sendable {
    case cheapest
    case fastest
    case earliestDeparture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cheapest: return "Cheapest"
        case .fastest: return "Fastest"
        case .earliestDeparture: return "Earliest"
        }
    }
}

enum DepartureWindow: String, CaseIterable, Identifiable, Sendable {
    case earlyMorning
    case morning
    case afternoon
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .earlyMorning: return "00:00 – 06:00"
        case .morning: return "06:00 – 12:00"
        case .afternoon: return "12:00 – 18:00"
        case .evening: return "18:00 – 24:00"
        }
    }

    var hourRange: Range<Int> {
        switch self {
        case .earlyMorning: return 0..<6
        case .morning: return 6..<12
        case .afternoon: return 12..<18
        case .evening: return 18..<24
        }
    }

    func contains(_ date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> Bool {
        var calendar = calendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return hourRange.contains(calendar.component(.hour, from: date))
    }
}

/// Pure value type describing the active filters, so filtering can be tested without a view model.
struct FlightResultsFilter: Equatable, Sendable {
    var maximumStops: Int?
    var carrierCodes: Set<String> = []
    var departureWindows: Set<DepartureWindow> = []
    var checkedBagIncludedOnly = false

    var isActive: Bool {
        maximumStops != nil
            || !carrierCodes.isEmpty
            || !departureWindows.isEmpty
            || checkedBagIncludedOnly
    }

    var activeCount: Int {
        var count = 0
        if maximumStops != nil { count += 1 }
        if !carrierCodes.isEmpty { count += 1 }
        if !departureWindows.isEmpty { count += 1 }
        if checkedBagIncludedOnly { count += 1 }
        return count
    }

    func matches(_ offer: FlightOffer) -> Bool {
        if let maximumStops, offer.stopCount > maximumStops {
            return false
        }
        if !carrierCodes.isEmpty {
            let offerCarriers = Set(offer.operatingCarriers.map(\.code))
            guard !offerCarriers.isDisjoint(with: carrierCodes) else { return false }
        }
        if !departureWindows.isEmpty {
            guard let departure = offer.outbound?.departure?.date,
                  departureWindows.contains(where: { $0.contains(departure) }) else {
                return false
            }
        }
        if checkedBagIncludedOnly, !offer.includesCheckedBag {
            return false
        }
        return true
    }

    func apply(to offers: [FlightOffer]) -> [FlightOffer] {
        offers.filter(matches)
    }
}

extension FlightSortOption {
    func sort(_ offers: [FlightOffer]) -> [FlightOffer] {
        switch self {
        case .cheapest:
            return offers.sorted {
                ($0.totalPrice, $0.totalDuration) < ($1.totalPrice, $1.totalDuration)
            }
        case .fastest:
            return offers.sorted {
                ($0.totalDuration, $0.totalPrice) < ($1.totalDuration, $1.totalPrice)
            }
        case .earliestDeparture:
            return offers.sorted {
                let first = $0.outbound?.departure?.date ?? .distantFuture
                let second = $1.outbound?.departure?.date ?? .distantFuture
                return first == second ? $0.totalPrice < $1.totalPrice : first < second
            }
        }
    }
}
