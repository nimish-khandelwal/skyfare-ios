//
//  FlightSearchQuery.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

struct FlightSearchQuery: Hashable, Sendable {
    var origin: Airport
    var destination: Airport
    var departureDate: Date
    var returnDate: Date?
    var passengers: PassengerSelection
    var cabin: CabinClass
    var currencyCode: String
    var maximumResults: Int

    init(
        origin: Airport,
        destination: Airport,
        departureDate: Date,
        returnDate: Date? = nil,
        passengers: PassengerSelection = PassengerSelection(),
        cabin: CabinClass = .economy,
        currencyCode: String = "AED",
        maximumResults: Int = 30
    ) {
        self.origin = origin
        self.destination = destination
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.passengers = passengers
        self.cabin = cabin
        self.currencyCode = currencyCode
        self.maximumResults = maximumResults
    }

    var isRoundTrip: Bool {
        returnDate != nil
    }

    var routeSummary: String {
        "\(origin.iataCode) → \(destination.iataCode)"
    }
}
