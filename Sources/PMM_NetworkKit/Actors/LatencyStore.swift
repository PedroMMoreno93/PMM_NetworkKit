//
//  LatencyStore.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

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
