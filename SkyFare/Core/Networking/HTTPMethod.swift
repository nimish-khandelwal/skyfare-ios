//
//  HTTPMethod.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
