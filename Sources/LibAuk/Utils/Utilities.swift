//
//  File 2.swift
//  
//
//  Created by Ho Hien on 8/9/21.
//

import Foundation

extension String {
    var utf8: Data {
        data(using: .utf8)!
    }
}

extension Data {
    static func random(_ len: Int) -> Data {
        let values = (0 ..< len).map { _ in UInt8.random(in: 0 ... 255) }
        return Data(values)
    }

    var utf8: String {
        String(data: self, encoding: .utf8)!
    }

    var bytes: [UInt8] {
        var b: [UInt8] = []
        b.append(contentsOf: self)
        return b
    }
    
    var hexString: String {
        reduce("") { $0 + String(format: "%02x", $1) }
    }
    
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        for i in 0 ..< length {
            let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
