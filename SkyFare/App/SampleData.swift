//
//  SampleData.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Offline data so the app, previews and UI tests run without provider credentials.
enum SampleData {
    static let dubai = Airport(
        id: "CDXB",
        iataCode: "DXB",
        name: "Dubai International",
        cityName: "Dubai",
        countryCode: "AE",
        kind: .airport
    )

    static let mumbai = Airport(
        id: "CBOM",
        iataCode: "BOM",
        name: "Chhatrapati Shivaji International",
        cityName: "Mumbai",
        countryCode: "IN",
        kind: .airport
    )

    static let delhi = Airport(
        id: "CDEL",
        iataCode: "DEL",
        name: "Indira Gandhi International",
        cityName: "Delhi",
        countryCode: "IN",
        kind: .airport
    )

    static let sharjah = Airport(
        id: "CSHJ",
        iataCode: "SHJ",
        name: "Sharjah International",
        cityName: "Sharjah",
        countryCode: "AE",
        kind: .airport
    )

    static let airports = [dubai, sharjah, mumbai, delhi]

    static var query: FlightSearchQuery {
        FlightSearchQuery(
            origin: dubai,
            destination: mumbai,
            departureDate: date("2026-11-10T00:00:00")
        )
    }

    static var offers: [FlightOffer] {
        [
            offer(
                id: "1",
                carrier: Carrier(code: "G9", name: "Air Arabia"),
                flightNumber: "451",
                departure: "2026-11-10T09:30:00",
                arrival: "2026-11-10T14:05:00",
                price: 650,
                seats: 7,
                bags: 0
            ),
            offer(
                id: "2",
                carrier: Carrier(code: "EK", name: "Emirates"),
                flightNumber: "508",
                departure: "2026-11-10T03:45:00",
                arrival: "2026-11-10T08:30:00",
                price: 1_240,
                seats: 4,
                bags: 1
            ),
            offer(
                id: "3",
                carrier: Carrier(code: "6E", name: "Indigo"),
                flightNumber: "1412",
                departure: "2026-11-10T19:15:00",
                arrival: "2026-11-11T02:40:00",
                price: 505,
                seats: 2,
                bags: 0,
                via: "MCT"
            )
        ]
    }

    static func date(_ text: String) -> Date {
        APIDateFormat.formatter(APIDateFormat.dateTime).date(from: text) ?? Date()
    }

    private static func offer(
        id: String,
        carrier: Carrier,
        flightNumber: String,
        departure: String,
        arrival: String,
        price: Decimal,
        seats: Int,
        bags: Int,
        via: String? = nil
    ) -> FlightOffer {
        let departureDate = date(departure)
        let arrivalDate = date(arrival)
        var segments: [FlightSegment] = []

        if let via {
            let midpoint = departureDate.addingTimeInterval(arrivalDate.timeIntervalSince(departureDate) / 2)
            segments.append(
                segment(
                    id: "\(id)-1",
                    carrier: carrier,
                    flightNumber: flightNumber,
                    from: "DXB",
                    to: via,
                    departure: departureDate,
                    arrival: midpoint.addingTimeInterval(-3_600)
                )
            )
            segments.append(
                segment(
                    id: "\(id)-2",
                    carrier: carrier,
                    flightNumber: String((Int(flightNumber) ?? 0) + 1),
                    from: via,
                    to: "BOM",
                    departure: midpoint.addingTimeInterval(3_600),
                    arrival: arrivalDate
                )
            )
        } else {
            segments.append(
                segment(
                    id: "\(id)-1",
                    carrier: carrier,
                    flightNumber: flightNumber,
                    from: "DXB",
                    to: "BOM",
                    departure: departureDate,
                    arrival: arrivalDate
                )
            )
        }

        return FlightOffer(
            id: id,
            itineraries: [
                Itinerary(
                    id: 0,
                    duration: arrivalDate.timeIntervalSince(departureDate),
                    segments: segments
                )
            ],
            totalPrice: price,
            basePrice: price - 60,
            currencyCode: "AED",
            seatsRemaining: seats,
            validatingCarrier: carrier,
            cabin: .economy,
            includedCheckedBags: bags,
            travellerCount: 1
        )
    }

    private static func segment(
        id: String,
        carrier: Carrier,
        flightNumber: String,
        from: String,
        to: String,
        departure: Date,
        arrival: Date
    ) -> FlightSegment {
        FlightSegment(
            id: id,
            departure: SegmentPoint(iataCode: from, terminal: "2", date: departure),
            arrival: SegmentPoint(iataCode: to, terminal: "2", date: arrival),
            carrier: carrier,
            flightNumber: flightNumber,
            aircraftName: "Airbus A320",
            duration: arrival.timeIntervalSince(departure),
            technicalStops: 0
        )
    }
}

struct SampleAirportRepository: AirportRepository {
    func airports(matching keyword: String) async throws -> [Airport] {
        let needle = keyword.lowercased()
        guard needle.count >= DuffelAirportRepository.minimumKeywordLength else { return [] }

        return SampleData.airports.filter {
            $0.cityName.lowercased().contains(needle)
                || $0.iataCode.lowercased().contains(needle)
                || $0.name.lowercased().contains(needle)
        }
    }
}

struct SampleFlightOfferRepository: FlightOfferRepository {
    func offers(for query: FlightSearchQuery) async throws -> [FlightOffer] {
        SampleData.offers
    }
}
