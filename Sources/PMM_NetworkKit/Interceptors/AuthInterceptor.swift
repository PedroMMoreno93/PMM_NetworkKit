//
//  AuthInterceptor.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public struct AuthInterceptor: Interceptor {
    private let tokenStore: TokenStore

    public init(tokenStore: TokenStore) {
        self.tokenStore = tokenStore
    }

    public func prepare(
        _ request: URLRequest,
        endpoint: any Endpoint
    ) async throws -> URLRequest {
        guard endpoint.tags.contains(.requiresAuth)
        else {
            return request
        }
        
        guard let token = await tokenStore.get()
        else {
            return request
        }

        var copy = request
        copy.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return copy
    }

    public func willSend(
        _ request: URLRequest,
        endpoint: any Endpoint
    ) async {
    }
    
    public func didReceive(
        _ result: Result<(HTTPURLResponse, Data), Error>,
        for request: URLRequest,
        endpoint: any Endpoint
    ) async -> Result<(HTTPURLResponse, Data), Error> {
        result
    }
}

/*
-----------
| EXAMPLE |
-----------
 
 struct UserDTO: Codable {
    let name: String
}

struct GetProfile: Endpoint {
  
    typealias Response = UserDTO
    
    var path: String { "/me" }
    var method: HTTPMethod {
        .get
    }
    var decoding: DecodingStrategy<Response> {
        .json()
    }
    
    // 👇 This endpoint requires authentication
    var tags: Set<EndpointTag> {
        [.requiresAuth]
    }
}


let tokenStore = TokenStore(initial: "abc.def.123") // i.e. initial token

@MainActor
let client = DefaultNetworkClient(
    config: APIConfig(baseURL: URL(string: "https://api.myapp.com")!),
    transport: URLSessionTransport(session: .shared),
    interceptors: [
        LoggingInterceptor(logResponseBody: true),
        AuthInterceptor(tokenStore: tokenStore)
    ]
)
 */
