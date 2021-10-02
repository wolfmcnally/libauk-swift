//
//  KeyCreator.swift
//  
//
//  Created by Ho Hien on 8/9/21.
//

import Foundation
import LibWally

class KeyCreator {
    
    private class func createMnemonicWords(completion: @escaping ((mnemonic: String?, error: Bool)) -> Void) {
        
        let bytesCount = 16
        var randomBytes = [UInt8](repeating: 0, count: bytesCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
        
        if status == errSecSuccess {
            
            let data = Data(randomBytes)
            let hex = data.hexString
            
            if let entropy = try? BIP39Mnemonic.Entropy(hex: hex) {
                if let mnemonic = try? BIP39Mnemonic(entropy: entropy) {
                    var words = (mnemonic.words.description).replacingOccurrences(of: "\"", with: "")
                    words = words.replacingOccurrences(of: ",", with: "")
                    words = words.replacingOccurrences(of: "[", with: "")
                    words = words.replacingOccurrences(of: "]", with: "")
                    completion((words, false))
                } else {
                    completion((nil, true))
                }
            } else {
                completion((nil, true))
            }
        } else {
            completion((nil, true))
        }
    }
    
    static func createEncryptedWords(keychain: KeychainProtocol = Keychain(), completion: @escaping ((mnemonic: Data?, error: Bool)) -> Void) {
        Self.createMnemonicWords { (mnemonic, _) in
            guard let mnemonic = mnemonic, !mnemonic.isEmpty, let encryptedWords = Encryption.encrypt(mnemonic.utf8, keychain: keychain) else {
                completion((nil, false))
                return
            }

            completion((encryptedWords, false))
        }
    }
}

extension KeyCreator {
    
    static func createMnemonicWords() -> String {
        let bytesCount = 16
        var randomBytes = [UInt8](repeating: 0, count: bytesCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
        guard status == errSecSuccess else {
            fatalError()
        }
        let hex = Data(randomBytes).hexString
        let entropy = try! BIP39Mnemonic.Entropy(hex: hex)
        let mnemonic = try! BIP39Mnemonic(entropy: entropy)
        return mnemonic.words.joined(separator: " ")
    }
    
    static func createEncryptedWords(keychain: AsyncKeychainProtocol = AsyncKeychain()) async throws -> Data {
        let mnemonic = createMnemonicWords()
        return try await Encryption.encrypt(mnemonic.utf8, keychain: keychain)
    }
}
