//
//  Seed.swift
//  
//
//  Created by Ho Hien on 8/11/21.
//

import Foundation
import URKit

public struct Seed: Codable {
    let data: Data
    let creationDate: Date?
    var name: String
    
    func cbor(nameLimit: Int? = nil, noteLimit: Int? = nil) -> CBOR {
        var a: [OrderedMapEntry] = [
            .init(key: 1, value: CBOR.byteString(data.bytes))
        ]
        
        if let creationDate = creationDate {
            a.append(.init(key: 2, value: CBOR.date(creationDate)))
        }
        
        if !name.isEmpty {
            a.append(.init(key: 3, value: CBOR.utf8String(name)))
        }
        
        return CBOR.orderedMap(a)
    }
    
    var ur: UR {
        try! UR(type: "crypto-seed", cbor: cbor())
    }
}
