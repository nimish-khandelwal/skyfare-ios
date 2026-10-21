//
//  AppConfiguration.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Credentials and endpoints the app needs at launch, resolved from the build configuration.
struct AppConfiguration: Sendable, Equatable {
    static let defaultBaseURL = URL(string: "https://test.api.amadeus.com")!

    let baseURL: URL
    let clientID: String
    let clientSecret: String

    var hasCredentials: Bool {
        !clientID.isEmpty && !clientSecret.isEmpty
    }
}

extension AppConfiguration {
    enum InfoKey {
        static let baseURL = "AMADEUS_BASE_URL"
        static let clientID = "AMADEUS_CLIENT_ID"
        static let clientSecret = "AMADEUS_CLIENT_SECRET"
    }

    /// Reads configuration from the app's `Info.plist`, letting environment variables win so that
    /// CI and UI-test runs can inject credentials without a checked-in secrets file.
    static func resolved(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> AppConfiguration {
        let baseURLString = value(for: InfoKey.baseURL, bundle: bundle, environment: environment)
        let baseURL = baseURLString.flatMap(URL.init(string:)) ?? defaultBaseURL

        return AppConfiguration(
            baseURL: baseURL,
            clientID: value(for: InfoKey.clientID, bundle: bundle, environment: environment) ?? "",
            clientSecret: value(for: InfoKey.clientSecret, bundle: bundle, environment: environment) ?? ""
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
