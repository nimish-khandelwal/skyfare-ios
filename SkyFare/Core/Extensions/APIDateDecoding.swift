//
//  APIDateDecoding.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

enum APIDateFormat {
    static let dateTime = "yyyy-MM-dd'T'HH:mm:ss"
    static let dateOnly = "yyyy-MM-dd"

    static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        return formatter
    }
}

extension JSONDecoder {
    /// Duffel returns local airport times without an offset, but timestamps such as `expires_at`
    /// carry one, so several formats are tried in turn.
    static var flightProvider: JSONDecoder {
        let decoder = JSONDecoder()
        let dateTime = APIDateFormat.formatter(APIDateFormat.dateTime)
        let dateOnly = APIDateFormat.formatter(APIDateFormat.dateOnly)

        decoder.dateDecodingStrategy = .custom { container in
            let text = try container.singleValueContainer().decode(String.self)

            if let date = dateTime.date(from: text) {
                return date
            }
            if let date = dateOnly.date(from: text) {
                return date
            }

            // ISO8601DateFormatter is not Sendable, so it is built here rather than captured.
            // Only offset-bearing timestamps such as expires_at reach this path.
            if let date = Self.isoDate(from: text) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: try container.singleValueContainer(),
                debugDescription: "Unrecognised date format: \(text)"
            )
        }

        return decoder
    }

    private static func isoDate(from text: String) -> Date? {
        let withFractionalSeconds = ISO8601DateFormatter()
        withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return withFractionalSeconds.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}
