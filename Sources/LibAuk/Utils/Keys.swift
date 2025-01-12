//
//  File.swift
//  
//
//  Created by Ho Hien on 08/10/2021.
//

import Foundation
import LibWally
import Web3
import KukaiCoreSwift

class Keys {
    
    static func fingerprint(mnemonic: BIP39Mnemonic, passphrase: String = "") -> String? {
        guard let hdMasterKey = try? HDKey(seed: mnemonic.seedHex(passphrase: passphrase)) else { return nil }
        
        return hdMasterKey.fingerprint.hexString
    }
    
    static func validMnemonicArray(_ words: [String]) -> Bool {
        guard (try? BIP39Mnemonic(words: words)) != nil else { return false }
        
        return true
    }
    
    static func validMnemonicString(_ words: String) -> Bool {
        guard (try? BIP39Mnemonic(words: words)) != nil else { return false }
        
        return true
    }
    
    static func entropy(_ words: [String]) -> Data? {
        guard let mnemonic = try? BIP39Mnemonic(words: words) else { return nil }
        
        return mnemonic.entropy.data
    }
    
    static func entropy(_ words: String) -> Data? {
        guard let mnemonic = try? BIP39Mnemonic(words: words) else { return nil }
        
        return mnemonic.entropy.data
    }
    
    static func mnemonic(_ entropy: Data) -> BIP39Mnemonic? {
        let bip39entropy = BIP39Mnemonic.Entropy(entropy)

        return try? BIP39Mnemonic(entropy: bip39entropy)
    }
    
    static func ethereumPrivateKey(mnemonic: BIP39Mnemonic, passphrase: String = "") throws -> EthereumPrivateKey {
        let masterKey = try HDKey(seed: mnemonic.seedHex(passphrase: ""))
        let derivationPath = try BIP32Path(string: Constant.ethDerivationPath)
        let account = try masterKey.derive(using: derivationPath)
        
        guard let privateKey = account.privKey?.data.bytes else {
            throw LibAukError.keyDerivationError
        }
        
        return try EthereumPrivateKey(privateKey)
    }
    
    static func tezosWallet(mnemonic: BIP39Mnemonic, passphrase: String = "") -> HDWallet? {
        HDWallet.create(withMnemonic: mnemonic.words.joined(separator: " "), passphrase: passphrase)
    }
}
