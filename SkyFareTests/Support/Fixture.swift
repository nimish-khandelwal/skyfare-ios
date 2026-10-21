//
//  Fixture.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation
import XCTest
@testable import SkyFare

private final class BundleToken {}

enum Fixture {
    static func data(_ name: String, extension fileExtension: String = "json") throws -> Data {
        let bundle = Bundle(for: BundleToken.self)

        guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
            throw XCTSkip("Missing fixture \(name).\(fileExtension) in test bundle")
        }

        return try Data(contentsOf: url)
    }
}
