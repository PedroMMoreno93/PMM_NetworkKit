//
//  LoggingInterceptor.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation
import os.log

public struct LoggingInterceptor: Interceptor {
    private let logger: Logger
    private let redactHeaders: Set<String>
    
    
    public init(subsystem: String = "com.pmm.networkkit", category: String = "network", redactHeaders: Set<String> = ["Authorization"]) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.redactHeaders = redactHeaders
    }
    
    
    public func prepare(_ request: URLRequest, endpoint: any Endpoint) async throws -> URLRequest {
        request
    }
    
    
    public func willSend(_ request: URLRequest, endpoint: any Endpoint) async {
        guard (endpoint.tags.contains(.skipLogging)) == false else { return }
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        logger.debug("➡️ sending: \(method, privacy: .public) \(url, privacy: .public)")
        
        
        if let headers = request.allHTTPHeaderFields, headers.isEmpty == false {
            let pretty = headers.map { key, value -> String in
                let redacted = redactHeaders.contains(key) ? "(redacted)" : value
                return "\(key): \(redacted)"
            }.joined(separator: ", ")
            logger.debug("headers: \(pretty, privacy: .public)")
        }
        if let body = request.httpBody, body.isEmpty == false {
            logger.debug("body: \("\(body.count) bytes", privacy: .public)")
        }
    }
    
    
    public func didReceive(
        _ result: Result<(HTTPURLResponse, Data), Error>,
        for request: URLRequest,
        endpoint: any Endpoint
    ) async -> Result<(HTTPURLResponse, Data), Error> {
        guard (endpoint.tags.contains(.skipLogging)) == false else { return result }
        
        
        switch result {
        case .success(let (response, data)):
            logger.debug("✅ response: status=\(response.statusCode) bytes=\(data.count)")
        case .failure(let error):
            logger.error("❌ error: \(error.localizedDescription, privacy: .public)")
        }
        return result
    }
}
