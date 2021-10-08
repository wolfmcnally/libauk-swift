//
//  SecureStorage.swift
//  
//
//  Created by Ho Hien on 8/9/21.
//

import Foundation
import Combine
import LibWally
import Web3

public protocol SecureStorageProtocol {
    func createKey(name: String) -> AnyPublisher<Void, Error>
    func importKey(words: [String], name: String, creationDate: Date?) -> AnyPublisher<Void, Error>
    func isWalletCreated() -> AnyPublisher<Bool, Error>
    func getETHAddress() -> String?
    func sign(message: Bytes) -> AnyPublisher<(v: UInt, r: Bytes, s: Bytes), Error>
    func signTransaction(transaction: EthereumTransaction, chainId: EthereumQuantity) -> AnyPublisher<EthereumSignedTransaction, Error>
    func exportSeed() -> AnyPublisher<Seed, Error>
    func exportMnemonicWords() -> AnyPublisher<[String], Error>
    func removeKeys() -> AnyPublisher<Void, Error>
}

class SecureStorage: SecureStorageProtocol {
    
    private let keychain: KeychainProtocol
    
    init(keychain: KeychainProtocol = Keychain()) {
        self.keychain = keychain
    }
    
    func createKey(name: String) -> AnyPublisher<Void, Error> {
        Future<Seed, Error> { promise in
            guard self.keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true) == nil else {
                promise(.failure(LibAukError.keyCreationExistingError(key: "createETHKey")))
                return
            }
            
            guard let entropy = KeyCreator.createEntropy() else {
                promise(.failure(LibAukError.keyCreationError))
                return
            }
            
            do {
                let seed = Seed(data: entropy, name: name, creationDate: Date())
                let seedData = try JSONEncoder().encode(seed)
                
                self.keychain.set(seedData, forKey: Constant.KeychainKey.seed, isSync: true)
                promise(.success(seed))
            } catch {
                promise(.failure(error))
            }
        }
        .compactMap { seed in
            Keys.mnemonic(seed.data)
        }
        .tryMap { [unowned self] in
            try self.saveKeyInfo(mnemonic: $0)
        }
        .eraseToAnyPublisher()
    }
    
    func importKey(words: [String], name: String, creationDate: Date?) -> AnyPublisher<Void, Error> {
        Future<Seed, Error> { promise in
            guard self.keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true) == nil else {
                promise(.failure(LibAukError.keyCreationExistingError(key: "createETHKey")))
                return
            }
            
            if let entropy = Keys.entropy(words) {
                do {
                    let seed = Seed(data: entropy, name: name, creationDate: creationDate ?? Date())
                    let seedData = try JSONEncoder().encode(seed)
                    
                    self.keychain.set(seedData, forKey: Constant.KeychainKey.seed, isSync: true)
                    promise(.success(seed))
                } catch {
                    promise(.failure(error))
                }
            } else {
                promise(.failure(LibAukError.invalidMnemonicError))
            }
        }
        .compactMap { seed in
            Keys.mnemonic(seed.data)
        }
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
    
    func getETHAddress() -> String? {
        guard let infoData = self.keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true),
              let keyInfo = try? JSONDecoder().decode(KeyInfo.self, from: infoData) else {
            return nil
        }
        return keyInfo.ethAddress
    }
    
    func sign(message: Bytes) -> AnyPublisher<(v: UInt, r: Bytes, s: Bytes), Error> {
        Future<Seed, Error> { promise in
            guard let seedData = self.keychain.getData(Constant.KeychainKey.seed, isSync: true),
                  let seed = try? JSONDecoder().decode(Seed.self, from: seedData) else {
                promise(.failure(LibAukError.emptyKey))
                return
            }
            
            promise(.success(seed))
        }
        .compactMap {
            Keys.mnemonic($0.data)
        }
        .tryMap { (mnemonic) in
            let ethPrivateKey = try Keys.ethereumPrivateKey(mnemonic: mnemonic)
            return try ethPrivateKey.sign(message: message)
        }
        .eraseToAnyPublisher()
    }
    
    func signTransaction(transaction: EthereumTransaction, chainId: EthereumQuantity) -> AnyPublisher<EthereumSignedTransaction, Error> {
        Future<Seed, Error> { promise in
            guard let seedData = self.keychain.getData(Constant.KeychainKey.seed, isSync: true),
                  let seed = try? JSONDecoder().decode(Seed.self, from: seedData) else {
                promise(.failure(LibAukError.emptyKey))
                return
            }
            
            promise(.success(seed))
        }
        .compactMap {
            Keys.mnemonic($0.data)
        }
        .tryMap { mnemonic in
            let ethPrivateKey = try Keys.ethereumPrivateKey(mnemonic: mnemonic)
            
            return try transaction.sign(with: ethPrivateKey, chainId: chainId)
        }
        .eraseToAnyPublisher()
    }
    
    func exportSeed() -> AnyPublisher<Seed, Error> {
        Future<Seed, Error> { promise in
            guard let seedData = self.keychain.getData(Constant.KeychainKey.seed, isSync: true),
                  let seed = try? JSONDecoder().decode(Seed.self, from: seedData) else {
                promise(.failure(LibAukError.emptyKey))
                return
            }
            
            promise(.success(seed))
        }
        .eraseToAnyPublisher()
    }

    func exportMnemonicWords() -> AnyPublisher<[String], Error> {
        self.exportSeed()
            .compactMap { seed in
                Keys.mnemonic(seed.data)
            }
            .map { $0.words }
            .eraseToAnyPublisher()
    }
    
    func removeKeys() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            guard self.keychain.getData(Constant.KeychainKey.seed, isSync: true) != nil,
                  self.keychain.getData(Constant.KeychainKey.ethInfoKey, isSync: true) != nil else {
                promise(.failure(LibAukError.emptyKey))
                return
            }
            
            self.keychain.remove(key: Constant.KeychainKey.seed, isSync: true)
            self.keychain.remove(key: Constant.KeychainKey.ethInfoKey, isSync: true)

            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }

    
    func saveKeyInfo(mnemonic: BIP39Mnemonic) throws {
        let ethPrivateKey = try Keys.ethereumPrivateKey(mnemonic: mnemonic)
        
        let keyInfo = KeyInfo(fingerprint: Keys.fingerprint(mnemonic: mnemonic) ?? "",
                              ethAddress: ethPrivateKey.address.hex(eip55: true),
                              creationDate: Date())

        let keyInfoData = try JSONEncoder().encode(keyInfo)
        keychain.set(keyInfoData, forKey: Constant.KeychainKey.ethInfoKey, isSync: true)
    }
}
