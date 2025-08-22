//
//  LoggingInterceptor.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation
import os.log

actor LatencyStore {
    private var startTimes: [URL: Date] = [:]

    func markStart(_ url: URL) { startTimes[url] = Date() }

    func elapsedMillis(for url: URL) -> Double? {
        guard let start = startTimes.removeValue(forKey: url)
        else {
            return nil
        }
        return Date().timeIntervalSince(start) * 1000.0
    }
}

public struct LoggingInterceptor: Interceptor {
    private let logger: Logger
    private let redactHeaders: Set<String>
    private let logResponseBody: Bool
    
    
    // Store start times for latency measurement
    private static let latency = LatencyStore()

    
    public init(subsystem: String = "com.pmm.networkkit",
                category: String = "network",
                redactHeaders: Set<String> = ["Authorization"],
                logResponseBody: Bool = false) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.redactHeaders = redactHeaders
        self.logResponseBody = logResponseBody
    }
    
    
    public func prepare(_ request: URLRequest, endpoint: any Endpoint) async throws -> URLRequest {
        request
    }
    
    
    public func willSend(_ request: URLRequest, endpoint: any Endpoint) async {
        guard (endpoint.tags.contains(.skipLogging)) == false
        else {
            return
        }
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
        
        
        if let url = request.url {
            await LoggingInterceptor.latency.markStart(url)
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
            
            
            
            if let url = request.url, let ms = await LoggingInterceptor.latency.elapsedMillis(for: url) {
                logger.debug("⏱️ elapsed: \(String(format: "%.2f", ms)) ms")
            }
            
            if logResponseBody, let pretty = prettyPrintedJSON(data) {
                logger.debug("body:\n\(pretty, privacy: .public)")
            }
            
            
        case .failure(let error):
            logger.error("❌ error: \(error.localizedDescription, privacy: .public)")
        }
        return result
    }
    
    
    private func prettyPrintedJSON(_ data: Data) -> String? {
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted])
            return String(data: prettyData, encoding: .utf8)
        } catch {
            return String(data: data, encoding: .utf8) // fallback raw
        }
    }
}
