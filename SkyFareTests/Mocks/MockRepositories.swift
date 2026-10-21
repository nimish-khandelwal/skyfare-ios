//
//  MockRepositories.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation
@testable import SkyFare

final class MockAirportRepository: AirportRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<[Airport], Error>
    private var recordedKeywords: [String] = []

    init(result: Result<[Airport], Error> = .success([])) {
        self.result = result
    }

    var keywords: [String] {
        lock.withLock { recordedKeywords }
    }

    var callCount: Int {
        lock.withLock { recordedKeywords.count }
    }

    func setResult(_ newResult: Result<[Airport], Error>) {
        lock.withLock { result = newResult }
    }

    func airports(matching keyword: String) async throws -> [Airport] {
        let current: Result<[Airport], Error> = lock.withLock {
            recordedKeywords.append(keyword)
            return result
        }
        return try current.get()
    }
}

final class MockFlightOfferRepository: FlightOfferRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<[FlightOffer], Error>
    private var recordedQueries: [FlightSearchQuery] = []

    init(result: Result<[FlightOffer], Error> = .success([])) {
        self.result = result
    }

    var queries: [FlightSearchQuery] {
        lock.withLock { recordedQueries }
    }

    func setResult(_ newResult: Result<[FlightOffer], Error>) {
        lock.withLock { result = newResult }
    }

    func offers(for query: FlightSearchQuery) async throws -> [FlightOffer] {
        let current: Result<[FlightOffer], Error> = lock.withLock {
            recordedQueries.append(query)
            return result
        }
        return try current.get()
    }
}
