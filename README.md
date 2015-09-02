# Latch
A simple Swift 2.0 Keychain Wrapper for iOS

# Usage

A proper example of how to use Latch can be seen in the [tests](https://github.com/DanielTomlinson/Latch/blob/master/LatchTests/LatchTests.swift).

```swift
let latch = Latch(service: "co.rocketapps.latch.example")
latch.setObject("super_secret_token", forKey: "FBAccessToken")

let tokenData = latch.dataForKey("FBAccessToken")
let token = NSString(data: tokenData, encoding: NSUTF8StringEncoding)

print(token)
```
