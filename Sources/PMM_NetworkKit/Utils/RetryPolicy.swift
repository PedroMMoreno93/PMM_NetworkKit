//
//  RetryPolicy.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public struct RetryPolicy: Sendable, Equatable {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let retryableStatusCodes: Set<Int>
    public let retryableErrors: [URLError.Code]

    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 0.5,
        retryableStatusCodes: Set<Int> = Set(500...599).union([429]),
        retryableErrors: [URLError.Code] = [.timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost]
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.retryableStatusCodes = retryableStatusCodes
        self.retryableErrors = retryableErrors
    }
}
