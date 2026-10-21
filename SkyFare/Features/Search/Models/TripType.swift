//
//  TripType.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

enum TripType: String, CaseIterable, Identifiable, Sendable {
    case oneWay
    case roundTrip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneWay: return "One way"
        case .roundTrip: return "Round trip"
        }
    }
}
