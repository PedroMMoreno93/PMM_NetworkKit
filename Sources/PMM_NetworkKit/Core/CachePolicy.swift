//
//  CachePolicy.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

//// CachePolicy (placeholder for future CacheInterceptor)
public enum CachePolicy: Sendable, Equatable {
    case networkOnly
    case cacheFirst(ttl: TimeInterval)
    case networkFirst(ttl: TimeInterval)
    case staleWhileRevalidate(ttl: TimeInterval)
}
