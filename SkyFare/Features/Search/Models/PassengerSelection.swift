//
//  PassengerSelection.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Passenger counts, bounded by the same limits airline booking flows enforce.
struct PassengerSelection: Hashable, Sendable {
    static let maximumTravellers = 9

    var adults: Int = 1
    var children: Int = 0
    var infants: Int = 0

    var total: Int {
        adults + children + infants
    }

    var seatedTravellers: Int {
        adults + children
    }

    var summary: String {
        var parts = ["\(adults) adult\(adults == 1 ? "" : "s")"]
        if children > 0 { parts.append("\(children) child\(children == 1 ? "" : "ren")") }
        if infants > 0 { parts.append("\(infants) infant\(infants == 1 ? "" : "s")") }
        return parts.joined(separator: ", ")
    }

    var validationMessage: String? {
        if adults < 1 {
            return "At least one adult is required."
        }
        if seatedTravellers > Self.maximumTravellers {
            return "A single booking allows up to \(Self.maximumTravellers) seated travellers."
        }
        if infants > adults {
            return "Each infant must travel with an adult."
        }
        return nil
    }

    var isValid: Bool {
        validationMessage == nil
    }

    mutating func increment(_ kind: Kind) {
        var updated = self
        switch kind {
        case .adults: updated.adults += 1
        case .children: updated.children += 1
        case .infants: updated.infants += 1
        }
        if updated.isValid {
            self = updated
        }
    }

    mutating func decrement(_ kind: Kind) {
        var updated = self
        switch kind {
        case .adults: updated.adults = max(1, adults - 1)
        case .children: updated.children = max(0, children - 1)
        case .infants: updated.infants = max(0, infants - 1)
        }
        if updated.isValid {
            self = updated
        }
    }

    enum Kind: String, CaseIterable, Identifiable, Sendable {
        case adults
        case children
        case infants

        var id: String { rawValue }

        var title: String {
            switch self {
            case .adults: return "Adults"
            case .children: return "Children"
            case .infants: return "Infants"
            }
        }

        var subtitle: String {
            switch self {
            case .adults: return "12 years and over"
            case .children: return "2 to 11 years"
            case .infants: return "Under 2 years"
            }
        }
    }
}
