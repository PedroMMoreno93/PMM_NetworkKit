//
//  AnyEncodable.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

internal struct AnyEncodable: Encodable {
    private let box: (Encoder) throws -> Void
    
    init(_ value: Encodable) {
        self.box = value.encode
    }
    
    func encode(
        to encoder: Encoder
    ) throws {
        try box(encoder)
    }
}

internal func dynamicJSONDecode<T>(_ type: T.Type, from data: Data, using decoder: JSONDecoder) throws -> T {
    if let decodableType = T.self as? Decodable.Type {
        let decoded = try decoder.decode(decodableType, from: data)
        if let typed = decoded as? T { return typed }
        throw DecodingError.typeMismatch(T.self, .init(codingPath: [], debugDescription: "Decoded type mismatch"))
    } else {
        throw DecodingError.typeMismatch(T.self, .init(codingPath: [], debugDescription: "Type does not conform to Decodable"))
    }
}
