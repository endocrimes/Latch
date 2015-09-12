# Latch
A simple Swift 2.0 Keychain Wrapper for iOS, watchOS 2, and OS X.

# Usage
A proper example of how to use Latch can be seen in the [tests](https://github.com/endocrimes/Latch/blob/master/LatchTests/LatchTests.swift).

```swift
import Latch

let latch = Latch(service: "co.rocketapps.latch.example")
latch.setObject("super_secret_token", forKey: "FBAccessToken")

let tokenData = latch.dataForKey("FBAccessToken")
let token = NSString(data: tokenData, encoding: NSUTF8StringEncoding)

print(token)
```

# Installation
Latch can be installed using [CocoaPods](https://cocoapods.org), [Carthage](https://github.com/Carthage/Carthage.git), or git submodules.

## Cocoapods
1. Add `pod "Latch"` to your podfile
2. Run `pod install`

## Carthage
1. Add `github "endocrimes/Latch"` to your Cartfile
2. `$ carthage update`
3. Copy the frameworks into your Xcode project

## Git Submodules
1. `$ git submodule add https://github.com/endocrimes/Latch.git`
2. `$ git submodule update --init --recursive`
3. Add the project

