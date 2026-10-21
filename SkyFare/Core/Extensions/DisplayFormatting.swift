//
//  DisplayFormatting.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

enum DisplayFormatting {
    static func time(_ date: Date, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    static func shortDate(_ date: Date, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale.current
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60

        if hours == 0 {
            return "\(minutes)m"
        }
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    static func price(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale.current

        return formatter.string(from: amount as NSDecimalNumber)
            ?? "\(currencyCode) \(amount)"
    }

    static func stops(_ count: Int) -> String {
        switch count {
        case 0: return "Direct"
        case 1: return "1 stop"
        default: return "\(count) stops"
        }
    }
}
