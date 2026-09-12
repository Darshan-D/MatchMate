//
//  URLProtocolStub.swift
//  MatchMateTests
//

import Foundation

/// Intercepts requests on a `URLSession` so `URLSessionHTTPClient` can be tested end to end
/// without hitting the network.
final class URLProtocolStub: URLProtocol {

    struct Stub {
        var statusCode: Int
        var data: Data
        var error: URLError?
    }

    nonisolated(unsafe) private static var stub: Stub?
    private static let lock = NSLock()

    static func set(statusCode: Int = 200, data: Data = Data(), error: URLError? = nil) {
        lock.withLock { stub = Stub(statusCode: statusCode, data: data, error: error) }
    }

    static func reset() {
        lock.withLock { stub = nil }
    }

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let stub = Self.lock.withLock { Self.stub }

        if let error = stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: stub?.statusCode ?? 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub?.data ?? Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
