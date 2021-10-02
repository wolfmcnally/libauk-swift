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
    
    static func sha256hash(_ text: String) -> String {
        let digest = SHA256.hash(data: text.utf8)
        
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    static func checksum(_ data: Data) -> String {
        let hash = SHA256.hash(data: Data(SHA256.hash(data: data)))
        let checksum = Data(hash).subdata(in: Range(0...3))
        return checksum.hexString
    }
    
    static func privateKey() -> Data {
        P256.Signing.PrivateKey().rawRepresentation
    }
    
    static func encrypt(_ data: Data, keychain: KeychainProtocol = Keychain()) -> Data? {
        guard let key = keychain.getData(Constant.KeychainKey.encryptionPrivateKey, isSync: true) else { return nil }
        
        return try? ChaChaPoly.seal(data, using: SymmetricKey(data: key)).combined
    }
    
    static func decrypt(_ data: Data, keychain: KeychainProtocol = Keychain()) -> Data? {
        guard let key = keychain.getData(Constant.KeychainKey.encryptionPrivateKey, isSync: true),
            let box = try? ChaChaPoly.SealedBox.init(combined: data) else { return nil }
                
        return try? ChaChaPoly.open(box, using: SymmetricKey(data: key))
    }
    
}

extension Encryption {
    static func encrypt(_ data: Data, keychain: AsyncKeychainProtocol = AsyncKeychain()) async throws -> Data {
        guard let key = try await keychain.getData(Constant.KeychainKey.encryptionPrivateKey, isSync: true) else {
            throw EncryptionError.noEncryptionKey
        }
        return try ChaChaPoly.seal(data, using: SymmetricKey(data: key)).combined
    }
    
    static func decrypt(_ data: Data, keychain: AsyncKeychainProtocol = AsyncKeychain()) async throws -> Data {
        guard let key = try await keychain.getData(Constant.KeychainKey.encryptionPrivateKey, isSync: true) else {
            throw EncryptionError.noEncryptionKey
        }
        let box = try ChaChaPoly.SealedBox.init(combined: data)
        return try ChaChaPoly.open(box, using: SymmetricKey(data: key))
    }
}

public enum EncryptionError: Swift.Error {
    case noEncryptionKey
}
