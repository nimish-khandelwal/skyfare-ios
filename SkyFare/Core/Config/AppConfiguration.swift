//
//  AppConfiguration.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Credentials and endpoints the app needs at launch, resolved from the build configuration.
struct AppConfiguration: Sendable, Equatable {
    static let defaultBaseURL = URL(string: "https://api.duffel.com")!
    static let defaultAPIVersion = "v2"

    /// Duffel test tokens carry this prefix. Live tokens use `duffel_live_`.
    static let testTokenPrefix = "duffel_test_"

    let baseURL: URL
    let accessToken: String
    let apiVersion: String

    var hasCredentials: Bool {
        !accessToken.isEmpty
    }

    /// SkyFare is a portfolio project and deliberately refuses anything but a sandbox token,
    /// so it cannot reach real inventory or run up a bill.
    var isTestToken: Bool {
        accessToken.hasPrefix(Self.testTokenPrefix)
    }

    /// Headers every request to the flight provider must carry.
    var defaultHeaders: [String: String] {
        [
            "Duffel-Version": apiVersion,
            "Accept": "application/json"
        ]
    }
}

extension AppConfiguration {
    enum InfoKey {
        static let baseURL = "DUFFEL_BASE_URL"
        static let accessToken = "DUFFEL_ACCESS_TOKEN"
        static let apiVersion = "DUFFEL_API_VERSION"
    }

    /// Reads configuration from the app's `Info.plist`, letting environment variables win so that
    /// CI and UI-test runs can inject credentials without a checked-in secrets file.
    static func resolved(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> AppConfiguration {
        let baseURLString = value(for: InfoKey.baseURL, bundle: bundle, environment: environment)

        return AppConfiguration(
            baseURL: baseURLString.flatMap(URL.init(string:)) ?? defaultBaseURL,
            accessToken: value(for: InfoKey.accessToken, bundle: bundle, environment: environment) ?? "",
            apiVersion: value(for: InfoKey.apiVersion, bundle: bundle, environment: environment) ?? defaultAPIVersion
        )
    }

    private static func value(
        for key: String,
        bundle: Bundle,
        environment: [String: String]
    ) -> String? {
        if let fromEnvironment = environment[key]?.trimmed, !fromEnvironment.isEmpty {
            return fromEnvironment
        }
        guard let fromBundle = (bundle.object(forInfoDictionaryKey: key) as? String)?.trimmed,
              !fromBundle.isEmpty else {
            return nil
        }
        return fromBundle
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
