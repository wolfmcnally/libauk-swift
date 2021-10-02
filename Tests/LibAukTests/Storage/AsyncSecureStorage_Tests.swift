//
//  File.swift
//  
//
//  Created by Wolf McNally on 10/1/21.
//

import Foundation
import XCTest
import LibWally
import Web3
@testable import LibAuk

class AsyncSecureStorage_Tests: XCTestCase {
    private var storage: AsyncSecureStorage!
    private var keychain: AsyncKeychainMock!

    func setup() async throws {
        keychain = AsyncKeychainMock()
        storage = AsyncSecureStorage(keychain: keychain)
        LibAuk.create(keyChainGroup: "com.bitmark.autonomy")
        try await keychain.set(Encryption.privateKey(), forKey: Constant.KeychainKey.encryptionPrivateKey, isSync: true)
    }
    
    func testCreateKeySuccessfully() async throws {
        try await setup()
        
        try await storage.createKey()
        
        XCTAssertNotNil(keychain.getData(Constant.KeychainKey.ethIdentityKey))
        XCTAssertTrue(keychain.getSync(Constant.KeychainKey.ethIdentityKey)!)
        XCTAssertNotNil(keychain.getData(Constant.KeychainKey.ethInfoKey))
        XCTAssertTrue(keychain.getSync(Constant.KeychainKey.ethInfoKey)!)
    }
    
    func testIsWalletCreatedSuccessfully() async throws {
        try await setup()

        let mnemomic = try BIP39Mnemonic(words: "daring mix cradle palm crowd sea observe whisper rubber either uncle oak")
        try await storage.saveKeyInfo(mnemonic: mnemomic)
        let a = try await storage.isWalletCreated
        XCTAssertTrue(a)
    }
    
    func testGetETHAddressSuccessfully() async throws {
        try await setup()
        
        let mnemomic = try BIP39Mnemonic(words: "daring mix cradle palm crowd sea observe whisper rubber either uncle oak")
        try await storage.saveKeyInfo(mnemonic: mnemomic)
        let address = try await storage.ethAddress
        XCTAssertEqual(address, "0xA00cbE6a45102135A210F231901faA6c05D51465")
    }
    
    func testSignMessageSuccessfully() async throws {
        try await setup()
        
        let words = "daring mix cradle palm crowd sea observe whisper rubber either uncle oak"
        let keyIdentity = try await KeyIdentity(words: Encryption.encrypt(words.utf8, keychain: keychain), passphrase: "")
        let keyIdentityData = try JSONEncoder().encode(keyIdentity)
        try await keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)
        
        let message = "hello"
        let (v, r, s) = try await storage.sign(message: message.bytes)
        XCTAssertEqual(v, 1)
        XCTAssertEqual(Data(r).hexString, "87996ffe97e732c1e20463a5858a03c9ca4084117dfbc95c5f7dd79c766ef7f9")
        XCTAssertEqual(Data(s).hexString, "3cbc5e6025e1c5a1b49406c59c6e64c81af18d0b9b122bf5b227bab7af3e0aa8")
    }
    
    func testSignTransactionSuccessfully() async throws {
        try await setup()
        
        let words = "daring mix cradle palm crowd sea observe whisper rubber either uncle oak"
        let keyIdentity = try await KeyIdentity(words: Encryption.encrypt(words.utf8, keychain: keychain), passphrase: "")
        let keyIdentityData = try JSONEncoder().encode(keyIdentity)
        try await keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)
        
        let tx = EthereumTransaction(
            nonce: 1,
            gasPrice: EthereumQuantity(quantity: 21.gwei),
            gas: 21000,
            to: try EthereumAddress(hex: "0xCeb523d2cE54b34af420cab27e10eD56ebcc93DE", eip55: true),
            value: EthereumQuantity(quantity: 1.eth)
        )
        let signedTx = try await storage.signTransaction(transaction: tx, chainId: 0)
        XCTAssertTrue(signedTx.verifySignature())
        XCTAssertEqual(signedTx.chainId, 0)
        XCTAssertEqual(signedTx.nonce, 1)
        XCTAssertEqual(signedTx.gasPrice, EthereumQuantity(quantity: 21.gwei))
        XCTAssertEqual(signedTx.to?.hex(eip55: true), "0xCeb523d2cE54b34af420cab27e10eD56ebcc93DE")
        XCTAssertEqual(signedTx.value, EthereumQuantity(quantity: 1.eth))
    }
    
    func testExportSeedSuccessfully() async throws {
        try await setup()
        
        let words = "daring mix cradle palm crowd sea observe whisper rubber either uncle oak"
        let keyIdentity = try await KeyIdentity(words: Encryption.encrypt(words.utf8, keychain: keychain), passphrase: "")
        let keyIdentityData = try JSONEncoder().encode(keyIdentity)
        try await keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)

        let keyInfo = KeyInfo(fingerprint: "0a3df912", ethAddress: "0xA00cbE6a45102135A210F231901faA6c05D51465", creationDate: Date(timeIntervalSince1970: 1628656699))
        let keyInfoData = try JSONEncoder().encode(keyInfo)
        try await keychain.set(keyInfoData, forKey: Constant.KeychainKey.ethInfoKey, isSync: true)
        
        let seed = try await storage.seed
        XCTAssertEqual(seed.data.hexString, "3791c0c7cfa34583e61fd4bcc8e3b24b")
        XCTAssertEqual(seed.name, "0a3df912")
        XCTAssertEqual(seed.creationDate, Date(timeIntervalSince1970: 1628656699))
        XCTAssertEqual(seed.ur.string, "ur:crypto-seed/otadgdemmertsttkotfelsvacttyrfspvlprgraosecyhsbwghfraxisdyhseoieiyeseheyonbtqzhd")
    }
    
    func testExportMnemonicWordsSuccessfully() async throws {
        try await setup()

        let words = "daring mix cradle palm crowd sea observe whisper rubber either uncle oak"
        let keyIdentity = try await KeyIdentity(words: Encryption.encrypt(words.utf8, keychain: keychain), passphrase: "")
        let keyIdentityData = try JSONEncoder().encode(keyIdentity)
        try await keychain.set(keyIdentityData, forKey: Constant.KeychainKey.ethIdentityKey, isSync: true)
        let mnemonicWords = try await storage.mnemonicWords
        XCTAssertEqual(mnemonicWords.joined(separator: " "), "daring mix cradle palm crowd sea observe whisper rubber either uncle oak")
    }
}
