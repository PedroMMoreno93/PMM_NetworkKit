//
//  RetryingTransport.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno on 22/8/25.
//

import Foundation
import os

public final class RetryingTransport: Transport {
    private let inner: Transport
    private let policy: RetryPolicy
    private let logger: Logger?

    public init(
        inner: Transport,
        policy: RetryPolicy = .init(),
        logger: Logger? = nil
    ) {
        self.inner = inner
        self.policy = policy
        self.logger = logger
    }

    public func perform(
        _ request: URLRequest
    ) async throws -> (HTTPURLResponse, Data) {
        var attempt = 0
        while true {
            try Task.checkCancellation()
            do {
                let (http, data) = try await inner.perform(request)
                if attempt < policy.maxRetries && policy.retryableStatusCodes.contains(http.statusCode) {
                    attempt += 1
                    let delay = backoffDelay(for: attempt)
                    logRetry("status=\(http.statusCode)", attempt: attempt, delay: delay)
                    try await sleep(seconds: delay)
                    continue
                }
                return (http, data)
            } catch {
                if let urlError = unwrapURLError(error),
                   policy.retryableErrors.contains(urlError.code),
                   attempt < policy.maxRetries {
                    attempt += 1
                    let delay = backoffDelay(for: attempt)
                    logRetry("URLError=\(urlError.code.rawValue)", attempt: attempt, delay: delay)
                    try await sleep(seconds: delay)
                    continue
                }
                throw error
            }
        }
    }

    private func backoffDelay(
        for attempt: Int
    ) -> TimeInterval {
        let base = policy.baseDelay * pow(2, Double(max(0, attempt - 1)))
        let jitter = Double.random(in: 0...(base * 0.1))
        return base + jitter
    }

    private func sleep(
        seconds: TimeInterval
    ) async throws {
        try Task.checkCancellation()
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func unwrapURLError(
        _ error: Error
    ) -> URLError? {
        if let url = error as? URLError { return url }
        if let net = error as? NetworkError,
           case .transport(let underlying) = net,
           let url = underlying as? URLError { return url }
        return nil
    }

    private func logRetry(
        _ reason: String,
        attempt: Int,
        delay: TimeInterval
    ) {
        logger?.debug("♻️ retry attempt #\(attempt) in \(String(format: "%.2f", delay))s (reason: \(reason, privacy: .public))")
    }
}
