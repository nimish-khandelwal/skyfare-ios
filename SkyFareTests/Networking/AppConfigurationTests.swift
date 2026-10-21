//
//  AppConfigurationTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class AppConfigurationTests: XCTestCase {
    func test_hasCredentialsRequiresAToken() {
        XCTAssertFalse(AppConfiguration.test(accessToken: "").hasCredentials)
        XCTAssertTrue(AppConfiguration.test().hasCredentials)
    }

    func test_environmentOverridesBundleValues() {
        let configuration = AppConfiguration.resolved(
            bundle: .main,
            environment: [
                AppConfiguration.InfoKey.accessToken: "token-from-environment",
                AppConfiguration.InfoKey.baseURL: "https://api.example.com",
                AppConfiguration.InfoKey.apiVersion: "v3"
            ]
        )

        XCTAssertEqual(configuration.accessToken, "token-from-environment")
        XCTAssertEqual(configuration.baseURL, URL(string: "https://api.example.com"))
        XCTAssertEqual(configuration.apiVersion, "v3")
    }

    func test_fallsBackToDefaultsWhenUnset() {
        let configuration = AppConfiguration.resolved(bundle: Bundle(for: Self.self), environment: [:])

        XCTAssertEqual(configuration.baseURL, AppConfiguration.defaultBaseURL)
        XCTAssertEqual(configuration.apiVersion, AppConfiguration.defaultAPIVersion)
        XCTAssertTrue(configuration.accessToken.isEmpty)
    }

    func test_blankEnvironmentValuesAreIgnored() {
        let configuration = AppConfiguration.resolved(
            bundle: Bundle(for: Self.self),
            environment: [AppConfiguration.InfoKey.accessToken: "   "]
        )

        XCTAssertTrue(configuration.accessToken.isEmpty)
    }

    func test_defaultHeadersCarryTheAPIVersion() {
        let headers = AppConfiguration.test().defaultHeaders

        XCTAssertEqual(headers["Duffel-Version"], "v2")
        XCTAssertEqual(headers["Accept"], "application/json")
    }
}
