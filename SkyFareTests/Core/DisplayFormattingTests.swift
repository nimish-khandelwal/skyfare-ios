//
//  DisplayFormattingTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class DisplayFormattingTests: XCTestCase {
    func test_durationShowsHoursAndMinutes() {
        XCTAssertEqual(DisplayFormatting.duration(11_100), "3h 5m")
    }

    func test_durationShowsMinutesOnlyUnderAnHour() {
        XCTAssertEqual(DisplayFormatting.duration(2_700), "45m")
    }

    func test_durationOmitsZeroMinutes() {
        XCTAssertEqual(DisplayFormatting.duration(7_200), "2h")
    }

    func test_stopsLabels() {
        XCTAssertEqual(DisplayFormatting.stops(0), "Direct")
        XCTAssertEqual(DisplayFormatting.stops(1), "1 stop")
        XCTAssertEqual(DisplayFormatting.stops(3), "3 stops")
    }

    func test_timeUsesTwentyFourHourClock() {
        let date = SampleData.date("2026-11-10T09:30:00")
        XCTAssertEqual(DisplayFormatting.time(date), "09:30")
    }
}
