//
//  HTTPClientTests.swift
//  MatchMateTests
//

import XCTest
@testable import MatchMate

final class HTTPClientTests: XCTestCase {

    private var client: URLSessionHTTPClient!
    private let url = URL(string: "https://test.example/api/?page=1")!

    override func setUp() {
        super.setUp()
        client = URLSessionHTTPClient(session: URLProtocolStub.makeSession())
    }

    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    func test_get_success_decodesBody() async throws {
        URLProtocolStub.set(statusCode: 200, data: RandomUserJSON.page(count: 2))

        let response: RandomUserResponse = try await client.get(url)

        XCTAssertEqual(response.results.count, 2)
    }

    func test_get_429_mapsToRateLimited() async {
        URLProtocolStub.set(statusCode: 429, data: Data("<html>slow down</html>".utf8))
        await assert(url, throws: .rateLimited)
    }

    func test_get_503_mapsToServer() async {
        URLProtocolStub.set(statusCode: 503, data: Data())
        await assert(url, throws: .server(503))
    }

    func test_get_malformedBody_mapsToDecoding() async {
        URLProtocolStub.set(statusCode: 200, data: Data("not json".utf8))
        await assert(url, throws: .decoding)
    }

    func test_get_transportError_mapsToConnectivity() async {
        URLProtocolStub.set(error: URLError(.notConnectedToInternet))
        await assert(url, throws: .connectivity)
    }

    private func assert(_ url: URL, throws expected: AppError, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            let _: RandomUserResponse = try await client.get(url)
            XCTFail("expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? AppError, expected, file: file, line: line)
        }
    }
}
