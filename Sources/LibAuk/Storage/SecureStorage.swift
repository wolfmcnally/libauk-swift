//
//  SecureStorage.swift
//  
//
//  Created by Ho Hien on 8/9/21.
//

import Foundation
import Combine
import LibWally
//import CryptoKit
import Web3

public protocol SecureStorageProtocol {
    func createKey() -> AnyPublisher<Void, Error>
    func isWalletCreated() -> AnyPublisher<Bool, Error>
    func getETHAddress() -> AnyPublisher<String, Error>
    func sign(message: Bytes) -> AnyPublisher<(v: UInt, r: Bytes, s: Bytes), Error>
    func signTransaction(transaction: EthereumTransaction, chainId: EthereumQuantity) -> AnyPublisher<EthereumSignedTransaction, Error>
    func exportSeed() -> AnyPublisher<Seed, Error>
    func exportMnemonicWords() -> AnyPublisher<[String], Error>
}

class SecureStorage: SecureStorageProtocol {
    
    private let keychain: KeychainProtocol
    
    init(keychain: KeychainProtocol = Keychain()) {
        self.keychain = keychain
    }
    
    func createKey() -> AnyPublisher<Void, Error> {
        Future<Data, Error> { promise in
            guard self.keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true) == nil else {
                promise(.failure(LibAukError.keyCreationExistingError(key: "createETHKey")))
                return
            }
            
            KeyCreator.createEncryptedWords(keychain: self.keychain) { (encryptedWords, error) in
                guard let encryptedWords = encryptedWords else {
                    promise(.failure(LibAukError.keyCreationError))
                    return
                }
                
                let keyIdentity = KeyIdentity(words: encryptedWords, passphrase: "")
                
                do {
                    let keyIdentityData = try JSONEncoder().encode(keyIdentity)
                    self.keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)
                    promise(.success(encryptedWords))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .compactMap { [unowned self] encryptedWords in
            Encryption.decrypt(encryptedWords, keychain: self.keychain)?.utf8
        }
        .tryMap { try BIP39Mnemonic(words: $0) }
        .tryMap { [unowned self] in
            try self.saveKeyInfo(mnemonic: $0)
        }
        .eraseToAnyPublisher()
    }
    
    func isWalletCreated() -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            guard let infoData = self.keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true),
                  (try? JSONDecoder().decode(KeyInfo.self, from: infoData)) != nil else {
                promise(.success(false))
                return
            }
            
            promise(.success(true))
        }
        .eraseToAnyPublisher()
    }
    
    func getETHAddress() -> AnyPublisher<String, Error> {
        Future<String, Error> { promise in
            guard let infoData = self.keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true),
                  let keyInfo = try? JSONDecoder().decode(KeyInfo.self, from: infoData) else {
                promise(.failure(LibAukError.emptyKey))
                return
            }
            
            promise(.success(keyInfo.ethAddress))
        }
        .eraseToAnyPublisher()
    }
    
    func sign(message: Bytes) -> AnyPublisher<(v: UInt, r: Bytes, s: Bytes), Error> {
        Future<(String, String), Error> { promise in
            guard let identityData = self.keychain.getData(Constant.KeychainKey.ethIdentityKey, isSync: true),
                  let keyIdentity = try? JSONDecoder().decode(KeyIdentity.self, from: identityData) else {
                promise(.failure(LibAukError.emptyKey))
                return
            }
            
            if let decryptedData = Encryption.decrypt(keyIdentity.words, keychain: self.keychain) {
                if let words = String(data: decryptedData, encoding: .utf8) {
                    promise(.success((words, keyIdentity.passphrase)))
                } else {
                    promise(.failure(LibAukError.other(reason: "Convert data error")))
                }
            } else {
                promise(.failure(LibAukError.other(reason: "Couldn't decrypt data")))
            }
        }
        .tryMap { [unowned self] (words, passphrase) in
            let mnemonic = try BIP39Mnemonic(words: words)
            let ethPrivateKey = try self.getEthereumPrivateKey(mnemonic: mnemonic, passphrase: passphrase)
            
            return try ethPrivateKey.sign(message: message)
        }
        .eraseToAnyPublisher()
    }
    
    func signTransaction(transaction: EthereumTransaction, chainId: EthereumQuantity) -> AnyPublisher<EthereumSignedTransaction, Error> {
        Future<(String, String), Error> { promise in
            guard let identityData = self.keychain.getData(Constant.KeychainKey.ethIdentityKey, isSync: true),
                  let keyIdentity = try? JSONDecoder().decode(KeyIdentity.self, from: identityData) else {
                promise(.failure(LibAukError.emptyKey))
                return
            }
            
            if let decryptedData = Encryption.decrypt(keyIdentity.words, keychain: self.keychain) {
                if let words = String(data: decryptedData, encoding: .utf8) {
                    promise(.success((words, keyIdentity.passphrase)))
                } else {
                    promise(.failure(LibAukError.other(reason: "Convert data error")))
                }
            } else {
                promise(.failure(LibAukError.other(reason: "Couldn't decrypt data")))
            }
        }
        .tryMap { [unowned self] (words, passphrase) in
            let mnemonic = try BIP39Mnemonic(words: words)
            let ethPrivateKey = try self.getEthereumPrivateKey(mnemonic: mnemonic, passphrase: passphrase)
            
            return try transaction.sign(with: ethPrivateKey, chainId: chainId)
        }
        .eraseToAnyPublisher()
    }
    
    func exportSeed() -> AnyPublisher<Seed, Error> {
        Future<Seed, Error> { promise in
            guard let identityData = self.keychain.getData(Constant.KeychainKey.ethIdentityKey, isSync: true),
                  let keyIdentity = try? JSONDecoder().decode(KeyIdentity.self, from: identityData),
                  let infoData = self.keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true),
                  let keyInfo = try? JSONDecoder().decode(KeyInfo.self, from: infoData) else {
                promise(.failure(LibAukError.emptyKey))
                return
            }
            
            if let decryptedData = Encryption.decrypt(keyIdentity.words, keychain: self.keychain) {
                if let words = String(data: decryptedData, encoding: .utf8),
                   let mnemonic = try? BIP39Mnemonic(words: words) {
                    promise(.success(Seed(data: mnemonic.entropy.data, creationDate: keyInfo.creationDate, name: keyInfo.fingerprint)))
                } else {
                    promise(.failure(LibAukError.other(reason: "Convert data error")))
                }
            } else {
                promise(.failure(LibAukError.other(reason: "Couldn't decrypt data")))
            }
        }
        .eraseToAnyPublisher()
    }

    func exportMnemonicWords() -> AnyPublisher<[String], Error> {
        Future<[String], Error> { promise in
            guard let identityData = self.keychain.getData(Constant.KeychainKey.ethIdentityKey, isSync: true),
                  let keyIdentity = try? JSONDecoder().decode(KeyIdentity.self, from: identityData) else {
                promise(.failure(LibAukError.emptyKey))
                return
            }

            if let decryptedData = Encryption.decrypt(keyIdentity.words, keychain: self.keychain) {
                if let words = String(data: decryptedData, encoding: .utf8),
                   let mnemonic = try? BIP39Mnemonic(words: words) {
                    promise(.success(mnemonic.words))
                } else {
                    promise(.failure(LibAukError.other(reason: "Convert data error")))
                }
            } else {
                promise(.failure(LibAukError.other(reason: "Couldn't decrypt data")))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveKeyInfo(mnemonic: BIP39Mnemonic) throws {
        let masterKey = try HDKey(seed: mnemonic.seedHex(passphrase: ""))
        let ethPrivateKey = try getEthereumPrivateKey(mnemonic: mnemonic)
        
        let keyInfo = KeyInfo(fingerprint: masterKey.fingerprint.hexString,
                              ethAddress: ethPrivateKey.address.hex(eip55: true),
                              creationDate: Date())

        let keyInfoData = try JSONEncoder().encode(keyInfo)
        keychain.set(keyInfoData, forKey: Constant.KeychainKey.ethInfoKey, isSync: true)
    }
    
    func getEthereumPrivateKey(mnemonic: BIP39Mnemonic, passphrase: String = "") throws -> EthereumPrivateKey {
        let masterKey = try HDKey(seed: mnemonic.seedHex(passphrase: ""))
        let derivationPath = try BIP32Path(string: Constant.ethDerivationPath)
        let account = try masterKey.derive(using: derivationPath)
        
        guard let privateKey = account.privKey?.data.bytes else {
            throw LibAukError.keyDerivationError
        }
        
        return try EthereumPrivateKey(privateKey)
    }
}
