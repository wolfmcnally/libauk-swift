# Autonomy Account Vault

## Design

`AutonomySecureStorage` contains functions to create key and save into keychain, get eth address, sign transaction and export seed as UR format.
`AutonomyAccountVault` holds the function to setup keychain group and can be used as the static provider of the module.

## Installation

AutonomyAccountVault is compatible with Swift Package Manager v5 (Swift 5 and above). Simply add it to the dependencies in your Package.swift.

dependencies: [
    .package(url: "https://github.com/bitmark-inc/autonomy-account-vault-swift.git", from: "1.0.0")
]

## License

Bitmark Inc.
