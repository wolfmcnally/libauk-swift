//
//  Constant.swift
//  
//
//  Created by Ho Hien on 8/9/21.
//

import Foundation

struct Constant {
    
    static let ethDerivationPath = "m/44'/60'/0'/0/0"
    
    struct KeychainKey {
        static func personaPrefix(at index: Int) -> String {
            "persona.\(index)"
        }

        static let seed = "seed"
        static let ethInfoKey = "ethInfo"
    }
}
