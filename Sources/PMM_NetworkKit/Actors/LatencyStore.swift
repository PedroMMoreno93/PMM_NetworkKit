//
//  LatencyStore.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public actor LatencyStore {
    private var startTimes: [URL: Date]

    public init(
        startTimes: [URL : Date]  = [:]
    ) {
        self.startTimes = startTimes
    }
    
    public func markStart(_ url: URL) { startTimes[url] = Date() }

    public func elapsedMillis(
        for url: URL
    ) -> Double? {
        guard let start = startTimes.removeValue(forKey: url)
        else {
            return nil
        }
        return Date().timeIntervalSince(start) * 1000.0
    }
}
