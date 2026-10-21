//
//  ISO8601DurationTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class ISO8601DurationTests: XCTestCase {
    func test_parsesHoursAndMinutes() {
        XCTAssertEqual(ISO8601Duration.seconds(from: "PT3H5M"), 11_100)
    }

    func test_parsesHoursOnly() {
        XCTAssertEqual(ISO8601Duration.seconds(from: "PT2H"), 7_200)
    }

    func test_parsesMinutesOnly() {
        XCTAssertEqual(ISO8601Duration.seconds(from: "PT45M"), 2_700)
    }

    func test_parsesDaysAndTimeComponents() {
        XCTAssertEqual(ISO8601Duration.seconds(from: "P1DT2H30M"), 95_400)
    }

    func test_parsesSeconds() {
        XCTAssertEqual(ISO8601Duration.seconds(from: "PT1M30S"), 90)
    }

    func test_returnsNilForMissingPrefix() {
        XCTAssertNil(ISO8601Duration.seconds(from: "3H5M"))
    }

    func test_returnsNilForUnknownComponent() {
        XCTAssertNil(ISO8601Duration.seconds(from: "PT3X"))
    }

    func test_returnsNilForTrailingDigits() {
        XCTAssertNil(ISO8601Duration.seconds(from: "PT3H5"))
    }

    func test_returnsNilForEmptyDuration() {
        XCTAssertNil(ISO8601Duration.seconds(from: "PT"))
    }
}
