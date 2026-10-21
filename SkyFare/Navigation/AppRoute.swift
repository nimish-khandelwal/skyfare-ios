//
//  AppRoute.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

enum AppRoute: Hashable, Sendable {
    case results(query: FlightSearchQuery, offers: [FlightOffer])
}
