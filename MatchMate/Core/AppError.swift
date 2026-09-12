//
//  AppError.swift
//  MatchMate
//

import Foundation

/// The single error type surfaced to the presentation layer.
///
/// Lower layers throw their own concrete errors (`URLError`, `DecodingError`, SwiftData errors);
/// the data layer maps them onto these cases so the UI only ever switches over one enum.
enum AppError: Error, LocalizedError, Equatable {

    /// Any error becomes an `AppError`: pass one through untouched, treat anything else as a
    /// local persistence failure (the only non-mapped source that reaches a view model).
    init(_ error: Error) {
        self = (error as? AppError) ?? .persistence
    }

    /// No usable network connection (URLSession failure, offline).
    case connectivity
    /// Server asked us to back off (HTTP 429).
    case rateLimited
    /// Server-side failure (HTTP 5xx / unexpected status). Carries the status code.
    case server(Int)
    /// Response body could not be decoded into the expected shape.
    case decoding
    /// A local database read/write failed.
    case persistence
    /// Offline on a cold start with nothing cached — there is genuinely nothing to show.
    case offlineNoCache
    /// Offline and the user has scrolled past everything that was cached.
    case endOfCache

    var errorDescription: String? {
        switch self {
        case .connectivity:
            return "No internet connection. Showing saved profiles."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .server(let code):
            return "The server had a problem (\(code)). Showing saved profiles."
        case .decoding:
            return "Received unexpected data from the server."
        case .persistence:
            return "Couldn't save your changes locally."
        case .offlineNoCache:
            return "You're offline and there are no saved profiles yet."
        case .endOfCache:
            return "You're offline — that's all the profiles saved on this device."
        }
    }
}
