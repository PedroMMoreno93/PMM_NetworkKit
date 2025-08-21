//
//  NetworkError.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation
public enum NetworkError: Error, LocalizedError {
    case cancelled
    case noConnection
    case timeout
    case server(status: Int, payload: Data?)
    case decoding(underlying: Error)
    case transport(underlying: Error)
    case unauthorized
    case forbidden
    case notFound
    case unacceptableStatus(code: Int, payload: Data?) // 4xx/5xx not mapped above
    
    
    public var errorDescription: String? {
        switch self {
        case .cancelled: return "The request was cancelled."
        case .noConnection: return "No internet connection."
        case .timeout: return "The request timed out."
        case .server(let status, _): return "Server error (status: \(status))."
        case .decoding(let underlying): return "Decoding error: \(underlying.localizedDescription)"
        case .transport(let underlying): return "Transport error: \(underlying.localizedDescription)"
        case .unauthorized: return "Unauthorized (401)."
        case .forbidden: return "Forbidden (403)."
        case .notFound: return "Not found (404)."
        case .unacceptableStatus(let code, _): return "Unacceptable status code: \(code)."
        }
    }
}

extension NetworkError: Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled),
             (.noConnection, .noConnection),
             (.timeout, .timeout),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound):
            return true

        case (.server(let l, _), .server(let r, _)):
            return l == r

        case (.unacceptableStatus(let l, _), .unacceptableStatus(let r, _)):
            return l == r

        // Para decoding/transport solo comparamos el “case”, no el underlying
        case (.decoding, .decoding),
             (.transport, .transport):
            return true

        default:
            return false
        }
    }
}
