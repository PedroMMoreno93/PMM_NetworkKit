//
//  EndpointTag.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

/// Use tags to opt-in/out features (auth, cache, logging verbosity, etc.)
public struct EndpointTag: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    
    public static let requiresAuth = EndpointTag(rawValue: 1 << 0)
    public static let skipLogging = EndpointTag(rawValue: 1 << 1)
    public static let highPriority = EndpointTag(rawValue: 1 << 2)
}
