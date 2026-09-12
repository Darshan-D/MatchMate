//
//  AsyncTestSupport.swift
//  MatchMateTests
//

import XCTest

extension XCTestCase {
    /// Spins the cooperative thread pool until `condition` holds, failing after a bounded number
    /// of yields. Used to wait for `AsyncStream`-driven view-model updates without arbitrary sleeps.
    @MainActor
    func waitUntil(
        _ description: String = "condition",
        iterations: Int = 500,
        _ condition: () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<iterations {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("Timed out waiting for: \(description)", file: file, line: line)
    }

    /// Starts a long-running view-model task (`start()`) and cancels it at teardown, so the test
    /// body can drive assertions while the stream-observing loop runs in the background.
    @MainActor
    func startObserving(_ body: @escaping @MainActor () async -> Void) {
        let task = Task { await body() }
        addTeardownBlock { task.cancel() }
    }
}
