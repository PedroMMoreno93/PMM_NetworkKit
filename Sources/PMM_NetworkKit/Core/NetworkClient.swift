//
//  NetworkClient.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public protocol NetworkClient {
    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response
}

public final class DefaultNetworkClient: NetworkClient {
    private let config: APIConfig
    private let transport: Transport
    private let interceptors: [Interceptor]
    
    
    public init(config: APIConfig, transport: Transport, interceptors: [Interceptor] = []) {
        self.config = config
        self.transport = transport
        self.interceptors = interceptors
    }
    
    
    public func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        var request = try buildRequest(for: endpoint)
        
        
        // Interceptors: prepare
        for interceptor in interceptors {
            request = try await interceptor.prepare(request, endpoint: endpoint)
        }
        // Interceptors: willSend
        for interceptor in interceptors {
            await interceptor.willSend(request, endpoint: endpoint)
        }
        
        
        // Transport
        let baseResult: Result<(HTTPURLResponse, Data), Error>
        do {
            let (response, data) = try await transport.perform(request)
            baseResult = .success((response, data))
        } catch {
            baseResult = .failure(error)
        }
        
        
        // Interceptors: didReceive (same order for predictability)
        var processed = baseResult
        for interceptor in interceptors {
            processed = await interceptor.didReceive(processed, for: request, endpoint: endpoint)
        }
        
        
        switch processed {
        case .success(let (http, data)):
            try Self.assertAcceptableStatus(http: http, data: data)
            return try decode(endpoint: endpoint, http: http, data: data)
        case .failure(let error):
            throw mapError(error)
        }
    }
}

// MARK: - Request Building
private extension DefaultNetworkClient {
    func buildRequest<E: Endpoint>(for endpoint: E) throws -> URLRequest {
        var components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: true)
        let path = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        
        if let componentsPath = components?.path {
            components?.path = componentsPath + "/" + path
        } else {
            components?.path = "/" + path

        }
        
        if let query = endpoint.query, query.isEmpty == false {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else {
            throw NetworkError.transport(underlying: URLError(.badURL))
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = config.timeout
        
        
        // Headers: config defaults first, then endpoint overrides
        var headers = config.defaultHeaders
        if let extra = endpoint.headers, extra.isEmpty == false {
            for (k, v) in extra { headers[k] = v }
        }
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        
        
        // Body (JSON-encode Encodable if present)
        if let encodable = endpoint.body {
            do {
                let data = try config.jsonEncoder.encode(AnyEncodable(encodable))
                request.httpBody = data
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                throw NetworkError.transport(underlying: error)
            }
        }
        return request
    }
    
    static func assertAcceptableStatus(http: HTTPURLResponse, data: Data) throws {
        switch http.statusCode {
        case 200...299:
            return
        case 401: throw NetworkError.unauthorized
        case 403: throw NetworkError.forbidden
        case 404: throw NetworkError.notFound
        case 500...599: throw NetworkError.server(status: http.statusCode, payload: data)
        default: throw NetworkError.unacceptableStatus(code: http.statusCode, payload: data)
        }
    }
    
    func decode<E: Endpoint>(endpoint: E, http: HTTPURLResponse, data: Data) throws -> E.Response {
        switch endpoint.decoding {
        case .raw:
            if let cast = data as? E.Response { return cast }
            // Allow clients to declare Response == Data
            if E.Response.self == Data.self, let typed = data as? E.Response { return typed }
            throw NetworkError.decoding(underlying: DecodingError.typeMismatch(E.Response.self, .init(codingPath: [], debugDescription: "Expected Data response")))
            
            
        case .json(let maybeDecoder):
            do {
                let decoder = maybeDecoder ?? config.jsonDecoder
                // If Response is Void, allow empty body
                if E.Response.self == Void.self {
                    // swiftlint:disable:next force_cast
                    return () as! E.Response
                }
                // If Response == Data and Content-Type isn't JSON, return raw
                if E.Response.self == Data.self {
                    
                    if let responseData = data as? E.Response {
                        return responseData
                    } else {
                        throw NetworkError.decoding(
                            underlying: DecodingError.typeMismatch(
                                E.Response.self,
                                .init(codingPath: [], debugDescription: "Expected Data")
                            )
                        )
                    }
                }
                // Otherwise decode JSON
                // Note: Requires E.Response: Decodable in caller's usage
                // We'll attempt decoding dynamically
                // Use a type-erased decoding helper
                let value = try dynamicJSONDecode(E.Response.self, from: data, using: decoder)
                return value
            } catch {
                throw NetworkError.decoding(underlying: error)
            }
            
            
        case .custom(let block):
            do { return try block(data, http, config.jsonDecoder) }
            catch { throw NetworkError.decoding(underlying: error) }
        }
    }
    
    func mapError(_ error: Error) -> NetworkError {
        if let net = error as? NetworkError { return net }
        if let url = error as? URLError {
            switch url.code {
            case .cancelled: return .cancelled
            case .notConnectedToInternet, .dataNotAllowed: return .noConnection
            case .timedOut: return .timeout
            default: break
            }
        }
        return .transport(underlying: error)
    }
}
