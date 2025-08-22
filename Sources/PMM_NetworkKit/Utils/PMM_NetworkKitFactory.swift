//
//  PMM_NetworkKitFactory.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno on 22/8/25.
//

import Foundation
import os

public enum PMM_NetworkKitFactory {
    /// URLSessionTransport + Logging (+ optional retry)
    public static func makeDefault(
        baseURL: URL,
        timeout: TimeInterval = 30,
        defaultHeaders: [String: String] = ["Accept": "application/json"],
        session: URLSession = .shared,
        retryPolicy: RetryPolicy? = nil,
        interceptors extra: [Interceptor] = []
    ) -> NetworkClient {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let config = APIConfig(
            baseURL: baseURL,
            timeout: timeout,
            defaultHeaders: defaultHeaders,
            session: session,
            jsonDecoder: decoder,
            jsonEncoder: JSONEncoder()
        )

        let baseTransport = URLSessionTransport(session: session)
        
        var transport: any Transport = LoggingTransport(inner: baseTransport)

        if let policy = retryPolicy {
            transport = RetryingTransport(
                inner: transport,
                policy: policy,
                logger: Logger(subsystem: "com.pmm.networkkit", category: "retry")
            )
        }
        
        let interceptors: [Interceptor] = [LoggingInterceptor()] + extra
        return DefaultNetworkClient(
            config: config,
            transport: transport,
            interceptors: interceptors
        )
    }
}
