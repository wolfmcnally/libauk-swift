//
//  File.swift
//  
//
//  Created by Wolf McNally on 9/30/21.
//

import Foundation
import LibWally
import Web3

public protocol AsyncSecureStorageProtocol {
    func createKey() async throws
    var isWalletCreated: Bool { get async throws }
    var ethAddress: String { get async throws }
    func sign(message: Bytes) async throws -> (v: UInt, r: Bytes, s: Bytes)
    func signTransaction(transaction: EthereumTransaction, chainId: EthereumQuantity) async throws -> EthereumSignedTransaction
    var seed: Seed { get async throws }
    var mnemonicWords: [String] { get async throws }
}

class AsyncSecureStorage: AsyncSecureStorageProtocol {
    private let keychain: AsyncKeychainProtocol
    
    init(keychain: AsyncKeychainProtocol = AsyncKeychain()) {
        self.keychain = keychain
    }
    
    func createKey() async throws {
        guard try await keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true) == nil else {
            throw LibAukError.keyCreationExistingError(key: "createETHKey")
        }
        
        let encryptedWords = try await KeyCreator.createEncryptedWords(keychain: keychain)
        let keyIdentity = KeyIdentity(words: encryptedWords, passphrase: "")
        let keyIdentityData = try JSONEncoder().encode(keyIdentity)
        try await keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)
        let words = try await Encryption.decrypt(encryptedWords, keychain: keychain).utf8
        let mnemonic = try BIP39Mnemonic(words: words)
        try await saveKeyInfo(mnemonic: mnemonic)
    }
    
    var isWalletCreated: Bool {
        get async throws {
            try await keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true) != nil
        }
    }
    
    private var keyIdentity: KeyIdentity {
        get async throws {
            guard
                let identityData = try await keychain.getData(Constant.KeychainKey.ethIdentityKey, isSync: true),
                let keyIdentity = try? JSONDecoder().decode(KeyIdentity.self, from: identityData)
            else {
                throw LibAukError.emptyKey
            }
            
            return keyIdentity
        }
    }
    
    private var keyInfo: KeyInfo {
        get async throws {
            guard
                let infoData = try await keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true),
                let keyInfo = try? JSONDecoder().decode(KeyInfo.self, from: infoData)
            else {
                throw LibAukError.emptyKey
            }
            
            return keyInfo
        }
    }

    var ethAddress: String {
        get async throws {
            return try await keyInfo.ethAddress
        }
    }
    
    private var mnemonic: BIP39Mnemonic {
        get async throws {
            let words = try await Encryption.decrypt(keyIdentity.words, keychain: keychain).utf8
            return try BIP39Mnemonic(words: words)
        }
    }

    private var ethPrivateKey: EthereumPrivateKey {
        get async throws {
            try await getEthereumPrivateKey(mnemonic: mnemonic, passphrase: keyIdentity.passphrase)
        }
    }
    
    func sign(message: Bytes) async throws -> (v: UInt, r: Bytes, s: Bytes) {
        try await ethPrivateKey.sign(message: message)
    }

    func signTransaction(transaction: EthereumTransaction, chainId: EthereumQuantity) async throws -> EthereumSignedTransaction {
        try await transaction.sign(with: ethPrivateKey, chainId: chainId)
    }
    
    var seed: Seed {
        get async throws {
            let info = try await keyInfo
            return try await Seed(data: mnemonic.entropy.data, creationDate: info.creationDate, name: info.fingerprint)
        }
    }

    var mnemonicWords: [String] {
        get async throws {
            try await mnemonic.words
        }
    }

    func saveKeyInfo(mnemonic: BIP39Mnemonic) async throws {
        let masterKey = try HDKey(seed: mnemonic.seedHex(passphrase: ""))
        let ethPrivateKey = try getEthereumPrivateKey(mnemonic: mnemonic)
        
        let keyInfo = KeyInfo(fingerprint: masterKey.fingerprint.hexString,
                              ethAddress: ethPrivateKey.address.hex(eip55: true),
                              creationDate: Date())

        let keyInfoData = try JSONEncoder().encode(keyInfo)
        try await keychain.set(keyInfoData, forKey: Constant.KeychainKey.ethInfoKey, isSync: true)
    }
    
    private func getEthereumPrivateKey(mnemonic: BIP39Mnemonic, passphrase: String = "") throws -> EthereumPrivateKey {
        let masterKey = try HDKey(seed: mnemonic.seedHex(passphrase: ""))
        let derivationPath = try BIP32Path(string: Constant.ethDerivationPath)
        let account = try masterKey.derive(using: derivationPath)
        
        guard let privateKey = account.privKey?.data.bytes else {
            throw LibAukError.keyDerivationError
        }
        
        return try EthereumPrivateKey(privateKey)
    }
}
