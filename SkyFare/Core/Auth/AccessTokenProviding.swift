//
//  AccessTokenProviding.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Supplies a currently valid bearer token, refreshing it when needed.
protocol AccessTokenProviding: Sendable {
    func accessToken() async throws -> String
    func invalidate() async
}
