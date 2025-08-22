//
//  RetryInterceptor.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public struct RetryInterceptor: Interceptor {
    private let policy: RetryPolicy
    
    public init(policy: RetryPolicy = RetryPolicy()) {
        self.policy = policy
    }
    
    public func didReceive(
        _ result: Result<(HTTPURLResponse, Data), Error>,
        for request: URLRequest,
        endpoint: any Endpoint
    ) async -> Result<(HTTPURLResponse, Data), Error> {
        var attempt = 0
        var currentResult = result
        
        while attempt < policy.maxRetries {
            guard shouldRetry(result: currentResult)
            else {
                break
            }
            
            attempt += 1
            
            // Exponential backoff with jitter
            let delay = policy.baseDelay * pow(2.0, Double(attempt - 1))
            let jitter = Double.random(in: 0...(delay * 0.1))
            let wait = delay + jitter
            
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            
            // ⚠️ Volvemos a ejecutar la request
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse {
                    currentResult = .success((http, data))
                } else {
                    currentResult = .failure(NetworkError.transport(underlying: URLError(.badServerResponse)))
                }
            } catch {
                currentResult = .failure(error)
            }
        }
        
        return currentResult
    }
    
    private func shouldRetry(
        result: Result<(HTTPURLResponse, Data), Error>
    ) -> Bool {
        switch result {
        case .success(let (response, _)):
            return policy.retryableStatusCodes.contains(response.statusCode)
        case .failure(let error):
            if let net = error as? NetworkError {
                switch net {
                case .timeout:
                    return true
                case .transport(let underlying):
                    if let urlError = underlying as? URLError {
                        return policy.retryableErrors.contains(urlError.code)
                    }
                    return false
                default: return false
                }
            }
            return false
        }
    }
}
