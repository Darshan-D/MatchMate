//
//  Logging.swift
//  MatchMate
//

import Foundation
import os

/// Central `os.Logger` accessors. Replaces ad-hoc `print` calls so log output is
/// categorised, level-aware, and stripped from release builds by the unified logging system.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "MatchMate"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let repository = Logger(subsystem: subsystem, category: "repository")
}
