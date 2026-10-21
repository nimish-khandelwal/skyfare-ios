//
//  AmadeusDateDecoding.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

enum AmadeusDateFormat {
    static let dateTime = "yyyy-MM-dd'T'HH:mm:ss"
    static let dateOnly = "yyyy-MM-dd"

    static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}

extension JSONDecoder {
    /// Amadeus mixes full timestamps with date-only values in the same payload, so both are tried.
    static var amadeus: JSONDecoder {
        let decoder = JSONDecoder()
        let dateTime = AmadeusDateFormat.formatter(AmadeusDateFormat.dateTime)
        let dateOnly = AmadeusDateFormat.formatter(AmadeusDateFormat.dateOnly)

        decoder.dateDecodingStrategy = .custom { container in
            let text = try container.singleValueContainer().decode(String.self)

            if let date = dateTime.date(from: text) {
                return date
            }
            if let date = dateOnly.date(from: text) {
                return date
            }
            if let date = ISO8601DateFormatter().date(from: text) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: try container.singleValueContainer(),
                debugDescription: "Unrecognised date format: \(text)"
            )
        }

        return decoder
    }
}
