//
//  DecodingStrategy.swift
//  PMM_NetworkKit
//
//  Created by Pedro M Moreno.
//

import Foundation

public enum DecodingStrategy<T> {
    case json(JSONDecoder?)
    case raw
    case custom((Data, HTTPURLResponse, JSONDecoder) throws -> T)
    
    
    public static func json() -> DecodingStrategy<T> { .json(nil) }
}
