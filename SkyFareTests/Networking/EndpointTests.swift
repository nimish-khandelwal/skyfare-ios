//
//  EndpointTests.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import XCTest
@testable import SkyFare

final class EndpointTests: XCTestCase {
    private let baseURL = URL(string: "https://api.duffel.com")!
    private let defaultHeaders = ["Duffel-Version": "v2", "Accept": "application/json"]

    func test_buildsURLWithQueryItems() throws {
        let endpoint = Endpoint(
            path: "places/suggestions",
            queryItems: [URLQueryItem(name: "query", value: "dub")]
        )

        let request = try endpoint.urlRequest(relativeTo: baseURL, accessToken: nil)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.duffel.com/places/suggestions?query=dub"
        )
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func test_appliesDefaultHeaders() throws {
        let request = try Endpoint(path: "places/suggestions")
            .urlRequest(relativeTo: baseURL, accessToken: nil, defaultHeaders: defaultHeaders)

        XCTAssertEqual(request.value(forHTTPHeaderField: "Duffel-Version"), "v2")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func test_endpointHeadersOverrideDefaults() throws {
        let endpoint = Endpoint(path: "anything", headers: ["Duffel-Version": "v1"])
        let request = try endpoint.urlRequest(
            relativeTo: baseURL,
            accessToken: nil,
            defaultHeaders: defaultHeaders
        )

        XCTAssertEqual(request.value(forHTTPHeaderField: "Duffel-Version"), "v1")
    }

    func test_addsBearerTokenWhenProvided() throws {
        let request = try Endpoint(path: "anything")
            .urlRequest(relativeTo: baseURL, accessToken: "token-under-test")

        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-under-test")
    }

    func test_omitsAuthorizationHeaderWithoutToken() throws {
        let request = try Endpoint(path: "anything")
            .urlRequest(relativeTo: baseURL, accessToken: nil)

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func test_setsJSONContentTypeOnlyWhenThereIsABody() throws {
        let body = Data(#"{"data":{}}"#.utf8)

        let withBody = try Endpoint(path: "air/offer_requests", method: .post, body: body)
            .urlRequest(relativeTo: baseURL, accessToken: nil)
        let withoutBody = try Endpoint(path: "air/offer_requests", method: .post)
            .urlRequest(relativeTo: baseURL, accessToken: nil)

        XCTAssertEqual(withBody.httpMethod, "POST")
        XCTAssertEqual(withBody.httpBody, body)
        XCTAssertEqual(withBody.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNil(withoutBody.value(forHTTPHeaderField: "Content-Type"))
    }
}
