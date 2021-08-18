//
//  LibAuk.swift
//
//
//  Created by Ho Hien on 8/9/21.
//

import LibWally

public class LibAuk {
    
    static var shared: LibAuk!
    
    static func create(keyChainGroup: String) {
        guard Self.shared == nil else {
            return
        }
        
        Self.shared = LibAuk(keyChainGroup: keyChainGroup)
    }
    
    let keyChainGroup: String

    private init(keyChainGroup: String) {
        self.keyChainGroup = keyChainGroup
    }
    
    // Call this function on launching app
    public func initEncryption() -> Bool {
        let keychain = Keychain()
        if keychain.getData(Constant.KeychainKey.encryptionPrivateKey) == nil {
            let privateKey = Encryption.privateKey()
            let success = keychain.set(privateKey, forKey: Constant.KeychainKey.encryptionPrivateKey)
            return success
        } else {
            return true
        }
    }
    
    public let storage: SecureStorageProtocol = SecureStorage()
}