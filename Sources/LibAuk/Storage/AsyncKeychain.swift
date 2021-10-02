//
//  File.swift
//  
//
//  Created by Wolf McNally on 9/30/21.
//

import Foundation
import Security

protocol AsyncKeychainProtocol {
    func set(_ data: Data, forKey: String, isSync: Bool) async throws
    func getData(_ key: String, isSync: Bool) async throws -> Data?
    func remove(key: String, isSync: Bool) async throws
}

class AsyncKeychain: AsyncKeychainProtocol {
    let prefix: String?
    
    init(prefix: String? = nil) {
        self.prefix = prefix
    }
    
    func set(_ data: Data, forKey: String, isSync: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let syncAttr = isSync ? kCFBooleanTrue : kCFBooleanFalse
            let query = [
                kSecClass as String: kSecClassGenericPassword as String,
                kSecAttrSynchronizable as String: syncAttr!,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                kSecAttrAccessGroup as String: LibAuk.shared.keyChainGroup,
                kSecAttrAccount as String: buildKeyAttr(prefix: prefix, key: forKey),
                kSecValueData as String: data
            ] as [String: Any]

            SecItemDelete(query as CFDictionary)

            let status = SecItemAdd(query as CFDictionary, nil)

            guard status == noErr else {
                continuation.resume(throwing: KeychainError.osStatusError(status))
                return
            }
            continuation.resume()
        }
    }

    func getData(_ key: String, isSync: Bool) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            let syncAttr = isSync ? kCFBooleanTrue : kCFBooleanFalse
            let query = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrSynchronizable as String: syncAttr!,
                kSecAttrAccount as String: buildKeyAttr(prefix: prefix, key: key),
                kSecReturnData as String: kCFBooleanTrue!,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                kSecAttrAccessGroup as String: LibAuk.shared.keyChainGroup,
                kSecMatchLimit as String: kSecMatchLimitOne
            ] as [String: Any]

            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

            guard status == noErr else {
                continuation.resume(throwing: KeychainError.osStatusError(status))
                return
            }
            
            continuation.resume(returning: dataTypeRef as? Data)
        }
    }

    func remove(key: String, isSync: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let syncAttr = isSync ? kCFBooleanTrue : kCFBooleanFalse
            let query = [
                kSecClass as String: kSecClassGenericPassword as String,
                kSecAttrSynchronizable as String: syncAttr!,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                kSecAttrAccessGroup as String: LibAuk.shared.keyChainGroup,
                kSecAttrAccount as String: buildKeyAttr(prefix: prefix, key: key)
            ] as [String: Any]

            // Delete any existing items
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess else {
                continuation.resume(throwing: KeychainError.osStatusError(status))
                return
            }
            continuation.resume()
        }
    }

    private func buildKeyAttr(prefix: String?, key: String) -> String {
        if let prefix = prefix {
            return "\(prefix)_\(key)"
        } else {
            return key
        }
    }
}

public enum KeychainError: Swift.Error {
    case unknownError
    case osStatusError(OSStatus)
}
