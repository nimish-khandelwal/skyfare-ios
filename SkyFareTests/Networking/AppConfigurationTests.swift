//
//  AppConfigurationTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class AppConfigurationTests: XCTestCase {
    func test_hasCredentialsRequiresBothValues() {
        XCTAssertFalse(AppConfiguration.test(clientID: "", clientSecret: "secret").hasCredentials)
        XCTAssertFalse(AppConfiguration.test(clientID: "id", clientSecret: "").hasCredentials)
        XCTAssertTrue(AppConfiguration.test().hasCredentials)
    }

    func test_environmentOverridesBundleValues() {
        let configuration = AppConfiguration.resolved(
            bundle: .main,
            environment: [
                AppConfiguration.InfoKey.clientID: "env-id",
                AppConfiguration.InfoKey.clientSecret: "env-secret",
                AppConfiguration.InfoKey.baseURL: "https://api.example.com"
            ]
        )

        XCTAssertEqual(configuration.clientID, "env-id")
        XCTAssertEqual(configuration.clientSecret, "env-secret")
        XCTAssertEqual(configuration.baseURL, URL(string: "https://api.example.com"))
    }

    func test_fallsBackToDefaultBaseURLWhenUnset() {
        let configuration = AppConfiguration.resolved(bundle: Bundle(for: Self.self), environment: [:])
        XCTAssertEqual(configuration.baseURL, AppConfiguration.defaultBaseURL)
    }

    func test_blankEnvironmentValuesAreIgnored() {
        let configuration = AppConfiguration.resolved(
            bundle: Bundle(for: Self.self),
            environment: [AppConfiguration.InfoKey.clientID: "   "]
        )
        XCTAssertTrue(configuration.clientID.isEmpty)
    }
}
