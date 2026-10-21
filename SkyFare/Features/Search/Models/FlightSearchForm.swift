//
//  FlightSearchForm.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Everything the user types on the search screen, plus the rules that decide whether
/// the form can be submitted. Kept free of Combine and UIKit so it can be tested directly.
struct FlightSearchForm: Equatable, Sendable {
    var tripType: TripType = .oneWay
    var originQuery: String = ""
    var destinationQuery: String = ""
    var origin: Airport?
    var destination: Airport?
    var departureDate: Date
    var returnDate: Date
    var passengers = PassengerSelection()
    var cabin: CabinClass = .economy
    var currencyCode: String = "AED"

    private let calendar: Calendar
    private let today: Date

    init(
        referenceDate: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) {
        self.calendar = calendar
        today = calendar.startOfDay(for: referenceDate)
        departureDate = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        returnDate = calendar.date(byAdding: .day, value: 14, to: today) ?? today
    }

    var earliestDepartureDate: Date {
        today
    }

    var earliestReturnDate: Date {
        departureDate
    }

    var validationMessage: String? {
        guard let origin else {
            return "Choose where you are flying from."
        }
        guard let destination else {
            return "Choose where you are flying to."
        }
        if origin.iataCode == destination.iataCode {
            return "Origin and destination must be different."
        }
        if calendar.startOfDay(for: departureDate) < today {
            return "Departure date cannot be in the past."
        }
        if tripType == .roundTrip,
           calendar.startOfDay(for: returnDate) < calendar.startOfDay(for: departureDate) {
            return "Return date must be on or after the departure date."
        }
        if let passengerMessage = passengers.validationMessage {
            return passengerMessage
        }
        return nil
    }

    var canSearch: Bool {
        validationMessage == nil
    }

    func makeQuery() -> FlightSearchQuery? {
        guard canSearch, let origin, let destination else { return nil }

        return FlightSearchQuery(
            origin: origin,
            destination: destination,
            departureDate: departureDate,
            returnDate: tripType == .roundTrip ? returnDate : nil,
            passengers: passengers,
            cabin: cabin,
            currencyCode: currencyCode
        )
    }

    mutating func select(_ airport: Airport, for field: AirportField) {
        switch field {
        case .origin:
            origin = airport
            originQuery = airport.displayTitle
        case .destination:
            destination = airport
            destinationQuery = airport.displayTitle
        }
    }

    func query(for field: AirportField) -> String {
        switch field {
        case .origin: return originQuery
        case .destination: return destinationQuery
        }
    }

    func selection(for field: AirportField) -> Airport? {
        switch field {
        case .origin: return origin
        case .destination: return destination
        }
    }

    mutating func clearSelection(for field: AirportField) {
        switch field {
        case .origin: origin = nil
        case .destination: destination = nil
        }
    }

    mutating func swapEndpoints() {
        let previousOrigin = origin
        let previousOriginQuery = originQuery
        origin = destination
        originQuery = destinationQuery
        destination = previousOrigin
        destinationQuery = previousOriginQuery
    }
}

enum AirportField: String, CaseIterable, Identifiable, Sendable {
    case origin
    case destination

    var id: String { rawValue }

    var title: String {
        switch self {
        case .origin: return "From"
        case .destination: return "To"
        }
    }

    var placeholder: String {
        switch self {
        case .origin: return "City or airport"
        case .destination: return "City or airport"
        }
    }
}
