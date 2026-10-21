//
//  EndpointTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class EndpointTests: XCTestCase {
    private let baseURL = URL(string: "https://test.api.amadeus.com")!

    func test_buildsURLWithQueryItems() throws {
        let endpoint = Endpoint(
            path: "v2/shopping/flight-offers",
            queryItems: [
                URLQueryItem(name: "originLocationCode", value: "DXB"),
                URLQueryItem(name: "adults", value: "2")
            ]
        )

        let request = try endpoint.urlRequest(relativeTo: baseURL, accessToken: nil)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://test.api.amadeus.com/v2/shopping/flight-offers?originLocationCode=DXB&adults=2"
        )
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func test_addsBearerTokenWhenProvided() throws {
        let request = try Endpoint(path: "v1/anything")
            .urlRequest(relativeTo: baseURL, accessToken: "abc123")

        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer abc123")
    }

    func test_omitsAuthorizationHeaderWithoutToken() throws {
        let request = try Endpoint(path: "v1/anything")
            .urlRequest(relativeTo: baseURL, accessToken: nil)

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func test_customHeadersAndBodyArePreserved() throws {
        let body = Data("grant_type=client_credentials".utf8)
        let endpoint = Endpoint(
            path: "v1/security/oauth2/token",
            method: .post,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: body
        )

        let request = try endpoint.urlRequest(relativeTo: baseURL, accessToken: nil)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpBody, body)
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "application/x-www-form-urlencoded"
        )
    }

    func test_encodesBracketedQueryNames() throws {
        let endpoint = Endpoint(
            path: "v1/reference-data/locations",
            queryItems: [URLQueryItem(name: "page[limit]", value: "12")]
        )

        let request = try endpoint.urlRequest(relativeTo: baseURL, accessToken: nil)

        XCTAssertEqual(
            request.url?.query(percentEncoded: false),
            "page[limit]=12"
        )
    }
}
