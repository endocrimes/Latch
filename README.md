# Latch
A simple Swift 2.0 Keychain Wrapper for iOS, watchOS 2, and OS X.

# Usage
A proper example of how to use Latch can be seen in the [tests](https://github.com/DanielTomlinson/Latch/blob/master/LatchTests/LatchTests.swift).

```swift
import Latch

let latch = Latch(service: "co.rocketapps.latch.example")
latch.setObject("super_secret_token", forKey: "FBAccessToken")

let tokenData = latch.dataForKey("FBAccessToken")
let token = NSString(data: tokenData, encoding: NSUTF8StringEncoding)

print(token)
```

# Documentation
You can find full documentation for Latch [here](https://danieltomlinson.github.io/Latch), or use the inline documentation.

# Installation
Latch can be installed using [CocoaPods](https://cocoapods.org), [Carthage](https://github.com/Carthage/Carthage.git), or git submodules.

## Cocoapods
1. Add `pod "Latch"` to your podfile
2. Run `pod install`

## Carthage
1. Add `github "DanielTomlinson/Latch"` to your Cartfile
2. `$ carthage update`
3. Copy the frameworks into your Xcode project

## Git Submodules
1. `$ git submodule add https://github.com/DanielTomlinson/Latch.git`
2. `$ git submodule update --init --recursive`
3. Add the project

# Contributing

## Issues
Issues and feature requests are welcome, although the intention is to keep Latch lightweight.

## Submitting Pull Requests
1. Fork it ( http://github.com/DanielTomlinson/Latch/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

