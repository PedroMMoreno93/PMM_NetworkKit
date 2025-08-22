//
//  TokenStore.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public actor TokenStore {
    private var token: String?

    public init(
        initial: String? = nil
    ) {
        self.token = initial
    }

    public func set(
        _ new: String?
    ) {
        self.token = new
    }

    public func get() -> String? {
        token
    }
}
