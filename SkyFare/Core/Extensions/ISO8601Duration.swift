//
//  ISO8601Duration.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

/// Parses the ISO-8601 durations flight APIs use for leg and layover lengths, such as `PT3H5M`.
enum ISO8601Duration {
    static func seconds(from text: String) -> TimeInterval? {
        guard text.hasPrefix("P") else { return nil }

        var total: TimeInterval = 0
        var digits = ""
        var isParsingTime = false
        var sawComponent = false

        for character in text.dropFirst() {
            if character == "T" {
                isParsingTime = true
                digits = ""
                continue
            }

            if character.isNumber {
                digits.append(character)
                continue
            }

            guard let amount = TimeInterval(digits) else { return nil }
            digits = ""

            switch (character, isParsingTime) {
            case ("D", false):
                total += amount * 86_400
            case ("W", false):
                total += amount * 604_800
            case ("H", true):
                total += amount * 3_600
            case ("M", true):
                total += amount * 60
            case ("S", true):
                total += amount
            default:
                return nil
            }
            sawComponent = true
        }

        guard sawComponent, digits.isEmpty else { return nil }
        return total
    }
}
