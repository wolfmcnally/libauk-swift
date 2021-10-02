//
//  File.swift
//  
//
//  Created by Wolf McNally on 10/1/21.
//

import Foundation
@testable import LibAuk

class AsyncKeychainMock: AsyncKeychainProtocol {
    var values: [String: (Data, Bool)] = [:]
    
    func set(_ data: Data, forKey: String, isSync: Bool) async throws {
        values[forKey] = (data, isSync)
    }
    
    func getData(_ key: String, isSync: Bool) async throws -> Data? {
        guard let value = values[key], value.1 == isSync else {
            return nil
        }
        
        return value.0
    }
    
    func remove(key: String, isSync: Bool) async throws {
        values.removeValue(forKey: key)
    }
    
    func getData(_ key: String) -> Data? {
        values[key]?.0
    }
    
    func getSync(_ key: String) -> Bool? {
        values[key]?.1
    }
}
