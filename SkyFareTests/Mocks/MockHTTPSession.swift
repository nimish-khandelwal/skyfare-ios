//
//  MockHTTPSession.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Foundation
@testable import SkyFare

final class MockHTTPSession: HTTPSession, @unchecked Sendable {
    struct Stub {
        var data: Data
        var statusCode: Int
        var headers: [String: String]
        var error: Error?

        static func success(_ data: Data, statusCode: Int = 200, headers: [String: String] = [:]) -> Stub {
            Stub(data: data, statusCode: statusCode, headers: headers, error: nil)
        }

        static func failure(_ error: Error) -> Stub {
            Stub(data: Data(), statusCode: 0, headers: [:], error: error)
        }

        static func json(_ object: Any, statusCode: Int = 200) -> Stub {
            let data = try! JSONSerialization.data(withJSONObject: object)
            return .success(data, statusCode: statusCode)
        }
    }

    private let lock = NSLock()
    private var stubs: [Stub]
    private var recorded: [URLRequest] = []
    private let repeatsLastStub: Bool

    init(stubs: [Stub], repeatsLastStub: Bool = true) {
        self.stubs = stubs
        self.repeatsLastStub = repeatsLastStub
    }

    var requests: [URLRequest] {
        lock.withLock { recorded }
    }

    var requestCount: Int {
        lock.withLock { recorded.count }
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let stub: Stub = try lock.withLock {
            recorded.append(request)

            if stubs.count > 1 {
                return stubs.removeFirst()
            }
            guard let last = stubs.first else {
                throw MockError.noStubsRemaining
            }
            if !repeatsLastStub {
                stubs.removeFirst()
            }
            return last
        }

        if let error = stub.error {
            throw error
        }

        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: stub.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: stub.headers
        )!

        return (stub.data, response)
    }

    enum MockError: Error, Equatable {
        case noStubsRemaining
        case transportFailure
    }
}
