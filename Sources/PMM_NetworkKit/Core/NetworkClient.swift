//
//  NetworkClient.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public protocol NetworkClient {
    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response
}


