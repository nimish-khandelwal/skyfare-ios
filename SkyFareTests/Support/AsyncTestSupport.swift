//
//  AsyncTestSupport.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation
import XCTest
@testable import SkyFare

/// Polls a main-actor condition until it holds, failing the test if it never does.
///
/// Used instead of subscribing to `@Published` publishers, which are not `Sendable`
/// and so cannot be handed to a detached task under strict concurrency checking.
@MainActor
func eventually(
    timeout: TimeInterval = 3,
    pollInterval: TimeInterval = 0.01,
    message: String = "Condition was never met",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ condition: @MainActor () -> Bool
) async {
    let deadline = Date().addingTimeInterval(timeout)

    while Date() < deadline {
        if condition() {
            return
        }
        try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
    }

    XCTFail("\(message) within \(timeout)s", file: file, line: line)
}

extension AppConfiguration {
    static func test(
        baseURL: URL = URL(string: "https://api.duffel.com")!,
        accessToken: String = "token-for-tests",
        apiVersion: String = "v2"
    ) -> AppConfiguration {
        AppConfiguration(baseURL: baseURL, accessToken: accessToken, apiVersion: apiVersion)
    }
}
