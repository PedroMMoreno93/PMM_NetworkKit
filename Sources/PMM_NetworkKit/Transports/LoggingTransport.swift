//
//  LoggingTransport.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation
import os.log

public final class LoggingTransport: Transport {
    private let inner: Transport
    private let logger: Logger

    public init(
        inner: Transport,
        subsystem: String = "com.pmm.networkkit",
        category: String = "transport.log"
    ) {
        self.inner = inner
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func perform(
        _ request: URLRequest
    ) async throws -> (HTTPURLResponse, Data) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "?"
        logger.debug("🚚 attempt: \(method, privacy: .public) \(url, privacy: .public)")
        let t0 = Date()
        do {
            let (http, data) = try await inner.perform(request)
            let ms = Date().timeIntervalSince(t0) * 1000
            logger.debug("✅ attempt done: status=\(http.statusCode) bytes=\(data.count) in \(String(format: "%.2f", ms)) ms")
            return (http, data)
        } catch {
            let ms = Date().timeIntervalSince(t0) * 1000
            logger.error("❌ attempt failed in \(String(format: "%.2f", ms)) ms: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
