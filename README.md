# Autonomy Account Vault

## Design

`LibAuk` holds the function to setup keychain group and can be used as the static provider of the module.
`SecureStorage` contains functions to create key and save into keychain, get eth address, sign transaction and export seed as UR format. This can be access by calling `LibAuk.shared.storage`

## Installation

AutonomyAccountVault is compatible with Swift Package Manager v5 (Swift 5 and above). Simply add it to the dependencies in your Package.swift.

dependencies: [
    .package(url: "https://github.com/bitmark-inc/libauk-swift.git", from: "1.0.0")
]

Init `LibAuk` with your keychain group and init encryption before using the `LibAuk.shared.storage`:

```
LibAuk.create(keychainGroup: "your_key_chain_group")
LibAuk.shared.initEncryption()
```


## License

Bitmark Inc.
