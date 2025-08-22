//
//  Endpoint.swift
//
//  Endpoint.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public protocol Endpoint {
    associatedtype Response
    
    var path: String { get }
    var method: HTTPMethod { get }
    var query: [String: String]? { get }
    var body: Encodable? { get }
    var headers: [String: String]? { get }
    
    /// Estrategia de decodificación de la respuesta
    var decoding: DecodingStrategy<Response> { get }
    
    /// Política de cacheo (se aplicará si existe un CacheInterceptor activo)
    var cachePolicy: CachePolicy { get }
    
    /// Metadatos (ej. tags como .requiresAuth, .skipCache)
    var tags: Set<EndpointTag> { get }
}

public extension Endpoint {
    var query: [String: String]? { nil }
    var body: Encodable? { nil }
    var headers: [String: String]? { nil }
    var cachePolicy: CachePolicy { .networkOnly }
    var tags: EndpointTag { [] }
}
