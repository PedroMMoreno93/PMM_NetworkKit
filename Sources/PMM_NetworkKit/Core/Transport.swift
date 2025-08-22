//
//  Transport.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public protocol Transport {
    func perform(
        _ request: URLRequest
    ) async throws -> (HTTPURLResponse, Data)
}
