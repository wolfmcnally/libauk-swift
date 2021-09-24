//
//  SecureStorage_Tests.swift
//  
//
//  Created by Ho Hien on 8/10/21.
//

import Foundation
import XCTest
import LibWally
import Combine
import Web3
@testable import LibAuk

class SecureStorage_Tests: XCTestCase {
    
    private var cancelBag: Set<AnyCancellable>!
    private var storage: SecureStorage!
    private var keychain: KeychainMock!

    override func setUpWithError() throws {
        cancelBag = []
        keychain = KeychainMock()
        storage = SecureStorage(keychain: keychain)
        LibAuk.create(keyChainGroup: "com.bitmark.autonomy")
        keychain.set(Encryption.privateKey(), forKey: Constant.KeychainKey.encryptionPrivateKey, isSync: true)
    }

    override func tearDownWithError() throws {
        storage = nil
        keychain = nil
        cancelBag.removeAll()
    }
    
    func testCreateKeySuccessfully() throws {
        let receivedExpectation = expectation(description: "all values received")

        storage.createKey()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTAssertNotNil(self.keychain.getData(Constant.KeychainKey.ethIdentityKey))
                    XCTAssertTrue(self.keychain.getSync(Constant.KeychainKey.ethIdentityKey)!)
                    XCTAssertNotNil(self.keychain.getData(Constant.KeychainKey.ethInfoKey))
                    XCTAssertTrue(self.keychain.getSync(Constant.KeychainKey.ethInfoKey)!)

                    receivedExpectation.fulfill()
                case .failure(let error):
                    XCTFail("createKey failed \(error)")
                }

            }, receiveValue: { _ in })
            .store(in: &cancelBag)

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testIsWalletCreatedSuccessfully() throws {
        let mnemomic = try BIP39Mnemonic(words: "daring mix cradle palm crowd sea observe whisper rubber either uncle oak")
        try storage.saveKeyInfo(mnemonic: mnemomic)
        
        let receivedExpectation = expectation(description: "all values received")

        storage.isWalletCreated()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    receivedExpectation.fulfill()
                case .failure(let error):
                    XCTFail("IsWalletCreated failed \(error)")
                }

            }, receiveValue: { isCreated in
                XCTAssertTrue(isCreated)
            })
            .store(in: &cancelBag)

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    
    func testGetETHAddressSuccessfully() throws {
        let mnemomic = try BIP39Mnemonic(words: "daring mix cradle palm crowd sea observe whisper rubber either uncle oak")
        try storage.saveKeyInfo(mnemonic: mnemomic)

        let receivedExpectation = expectation(description: "all values received")
        
        storage.getETHAddress()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    receivedExpectation.fulfill()
                case .failure(let error):
                    XCTFail("getAddress failed \(error)")
                }

            }, receiveValue: { address in
                XCTAssertEqual(address, "0xA00cbE6a45102135A210F231901faA6c05D51465")
            })
            .store(in: &cancelBag)

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSignMessageSuccessfully() throws {
        let words = "daring mix cradle palm crowd sea observe whisper rubber either uncle oak"
        let keyIdentity = KeyIdentity(words: Encryption.encrypt(words.utf8, keychain: keychain)!, passphrase: "")
        let keyIdentityData = try JSONEncoder().encode(keyIdentity)
        keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)
        
        let message = "hello"
        let receivedExpectation = expectation(description: "all values received")
        
        storage.sign(message: message.bytes)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    receivedExpectation.fulfill()
                case .failure(let error):
                    XCTFail("sign messge failed \(error)")
                }

            }, receiveValue: { (v, r, s) in
                XCTAssertEqual(v, 1)
                XCTAssertEqual(Data(r).hexString, "87996ffe97e732c1e20463a5858a03c9ca4084117dfbc95c5f7dd79c766ef7f9")
                XCTAssertEqual(Data(s).hexString, "3cbc5e6025e1c5a1b49406c59c6e64c81af18d0b9b122bf5b227bab7af3e0aa8")
            })
            .store(in: &cancelBag)

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSignTransactionSuccessfully() throws {
        let words = "daring mix cradle palm crowd sea observe whisper rubber either uncle oak"
        let keyIdentity = KeyIdentity(words: Encryption.encrypt(words.utf8, keychain: keychain)!, passphrase: "")
        let keyIdentityData = try JSONEncoder().encode(keyIdentity)
        keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)
        
        let tx = EthereumTransaction(
            nonce: 1,
            gasPrice: EthereumQuantity(quantity: 21.gwei),
            gas: 21000,
            to: try EthereumAddress(hex: "0xCeb523d2cE54b34af420cab27e10eD56ebcc93DE", eip55: true),
            value: EthereumQuantity(quantity: 1.eth)
        )
        let receivedExpectation = expectation(description: "all values received")
        
        storage.signTransaction(transaction: tx, chainId: 0)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    receivedExpectation.fulfill()
                case .failure(let error):
                    XCTFail("signTx failed \(error)")
                }

            }, receiveValue: { signedTx in
                XCTAssertTrue(signedTx.verifySignature())
                XCTAssertEqual(signedTx.chainId, 0)
                XCTAssertEqual(signedTx.nonce, 1)
                XCTAssertEqual(signedTx.gasPrice, EthereumQuantity(quantity: 21.gwei))
                XCTAssertEqual(signedTx.to?.hex(eip55: true), "0xCeb523d2cE54b34af420cab27e10eD56ebcc93DE")
                XCTAssertEqual(signedTx.value, EthereumQuantity(quantity: 1.eth))
            })
            .store(in: &cancelBag)

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testExportSeedSuccessfully() throws {
        let words = "daring mix cradle palm crowd sea observe whisper rubber either uncle oak"
        let keyIdentity = KeyIdentity(words: Encryption.encrypt(words.utf8, keychain: keychain)!, passphrase: "")
        let keyIdentityData = try JSONEncoder().encode(keyIdentity)
        keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)
        
        let keyInfo = KeyInfo(fingerprint: "0a3df912", ethAddress: "0xA00cbE6a45102135A210F231901faA6c05D51465", creationDate: Date(timeIntervalSince1970: 1628656699))
        let keyInfoData = try JSONEncoder().encode(keyInfo)
        keychain.set(keyInfoData, forKey: Constant.KeychainKey.ethInfoKey, isSync: true)
        
        let receivedExpectation = expectation(description: "all values received")
        
        storage.exportSeed()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    receivedExpectation.fulfill()
                case .failure(let error):
                    XCTFail("exportSeed failed \(error)")
                }

            }, receiveValue: { seed in
                XCTAssertEqual(seed.data.hexString, "3791c0c7cfa34583e61fd4bcc8e3b24b")
                XCTAssertEqual(seed.name, "0a3df912")
                XCTAssertEqual(seed.creationDate, Date(timeIntervalSince1970: 1628656699))
                XCTAssertEqual(seed.ur.string, "ur:crypto-seed/otadgdemmertsttkotfelsvacttyrfspvlprgraosecyhsbwghfraxisdyhseoieiyeseheyonbtqzhd")
            })
            .store(in: &cancelBag)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testExportMnemonicWordsSuccessfully() throws {
        let words = "daring mix cradle palm crowd sea observe whisper rubber either uncle oak"
        let keyIdentity = KeyIdentity(words: Encryption.encrypt(words.utf8, keychain: keychain)!, passphrase: "")
        let keyIdentityData = try JSONEncoder().encode(keyIdentity)
        keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)

        let receivedExpectation = expectation(description: "all values received")

        storage.exportMnemonicWords()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    receivedExpectation.fulfill()
                case .failure(let error):
                    XCTFail("exportMnemonicWords failed \(error)")
                }

            }, receiveValue: { mnemonicWords in
                XCTAssertEqual(mnemonicWords.joined(separator: " "), "daring mix cradle palm crowd sea observe whisper rubber either uncle oak")
            })
            .store(in: &cancelBag)

        waitForExpectations(timeout: 1, handler: nil)
    }
}
