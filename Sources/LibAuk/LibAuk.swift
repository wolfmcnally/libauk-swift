//
//  LibAuk.swift
//
//
//  Created by Ho Hien on 8/9/21.
//

import LibWally

public class LibAuk {
    
    public static var shared: LibAuk!
    
    public static func create(keyChainGroup: String) {
        guard Self.shared == nil else {
            return
        }
        
        Self.shared = LibAuk(keyChainGroup: keyChainGroup)
    }
    
    let keyChainGroup: String

    private init(keyChainGroup: String) {
        self.keyChainGroup = keyChainGroup
    }
    
    public func storage(at index: Int) -> SecureStorageProtocol {
        let keychain = Keychain(prefix: Constant.KeychainKey.personaPrefix(at: index))
        return SecureStorage(keychain: keychain)
    }
}
