//
//  Interceptor.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public protocol Interceptor {
    func prepare(
        _ request: URLRequest,
        endpoint: any Endpoint
    ) async throws -> URLRequest
    
    func willSend(
        _ request: URLRequest,
        endpoint: any Endpoint
    ) async
    
    func didReceive(
        _ result: Result<(HTTPURLResponse, Data), Error>,
        for request: URLRequest,
        endpoint: any Endpoint
    ) async -> Result<(HTTPURLResponse, Data), Error>
}

public extension Interceptor {
    func prepare(_ request: URLRequest, endpoint: any Endpoint) async throws -> URLRequest { request }
    func willSend(_ request: URLRequest, endpoint: any Endpoint) async {}
}
