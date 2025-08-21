//
//  Transport.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public protocol Transport {
    func perform(_ request: URLRequest) async throws -> (HTTPURLResponse, Data)
}

public final class URLSessionTransport: Transport {
    private let session: URLSession
    
    
    public init(session: URLSession) { self.session = session }
    
    
    public func perform(_ request: URLRequest) async throws -> (HTTPURLResponse, Data) {
        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.transport(underlying: URLError(.badServerResponse))
            }
            return (http, data)
        } catch {
            // Map common URLErrors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cancelled: throw NetworkError.cancelled
                case .notConnectedToInternet, .dataNotAllowed: throw NetworkError.noConnection
                case .timedOut: throw NetworkError.timeout
                default: break
                }
            }
            throw NetworkError.transport(underlying: error)
        }
    }
}
