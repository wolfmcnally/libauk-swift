//
//  File.swift
//  
//
//  Created by Ho Hien on 8/9/21.
//

import Foundation

public enum AutonomyAccountError: Error {
    case keyCreationError
    case emptyKey
    case keyCreationExistingError(key: String)
    case keyDerivationError
    case other(reason: String)
}

extension AutonomyAccountError: LocalizedError {
    public var errorDescription: String? {
        errorMessage
    }

    public var failureReason: String? {
        errorMessage
    }

    public var recoverySuggestion: String? {
        errorMessage
    }

    var errorMessage: String {
        switch self {
        case .keyCreationError:
            return "create key error"
        case .emptyKey:
            return "empty Key"
        case .keyCreationExistingError:
            return "create key error: key exists"
        case .keyDerivationError:
            return "key derivation error"
        case .other(let reason):
            return reason
        }
    }
}
