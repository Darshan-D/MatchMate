//
//  ProfileRepositoryError.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

enum ProfileRepositoryError: Error {
    case network(URLError)
    case decoding(Error)
    case persistence(Error)
    case offlineNoMoreData
}
