//
//  CabinClass.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

enum CabinClass: String, CaseIterable, Identifiable, Sendable {
    case economy
    case premiumEconomy = "premium_economy"
    case business
    case first

    var id: String { rawValue }

    var title: String {
        switch self {
        case .economy: return "Economy"
        case .premiumEconomy: return "Premium economy"
        case .business: return "Business"
        case .first: return "First"
        }
    }
}
