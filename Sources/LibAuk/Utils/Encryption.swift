//
//  Encryption.swift
//  GordianSigner
//
//  Created by Peter on 9/29/20.
//  Copyright © 2020 Blockchain Commons. All rights reserved.
//

import Foundation
import CryptoKit

enum Encryption {
    
    static func encrypt(_ data: Data, _ passcode: String) throws -> Data {
        let inputKey = SymmetricKey(data: passcode.utf8)
        let hkdfResultKey = HKDF<SHA256>.deriveKey(inputKeyMaterial: inputKey, outputByteCount: 64)
        
        return try ChaChaPoly.seal(data, using: hkdfResultKey).combined
    }
    
    static func decrypt(_ data: Data, _ passcode: String) throws -> Data {
        let box = try ChaChaPoly.SealedBox.init(combined: data)
                
        let inputKey = SymmetricKey(data: passcode.utf8)
        let hkdfResultKey = HKDF<SHA256>.deriveKey(inputKeyMaterial: inputKey, outputByteCount: 64)
        
        return try ChaChaPoly.open(box, using: hkdfResultKey)
    }
    
}
