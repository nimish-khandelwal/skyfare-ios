//
//  HTTPSession.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// The seam that lets tests replace real networking with canned responses.
protocol HTTPSession: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}
