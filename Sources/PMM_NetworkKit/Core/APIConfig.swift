//
//  APIConfig.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public struct APIConfig: Sendable {
    public var baseURL: URL
    public var timeout: TimeInterval
    public var defaultHeaders: [String: String]
    public var session: URLSession
    public var jsonDecoder: JSONDecoder
    public var jsonEncoder: JSONEncoder

    public init(
        baseURL: URL,
        timeout: TimeInterval = 30,
        defaultHeaders: [String: String] = [:],
        session: URLSession = .shared,
        jsonDecoder: JSONDecoder = .init(),
        jsonEncoder: JSONEncoder = .init()
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.defaultHeaders = defaultHeaders
        self.session = session
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }
}
