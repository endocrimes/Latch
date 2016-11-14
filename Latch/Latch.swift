//
//  Latch.swift
//  Latch
//
//  Created by Daniel Tomlinson on 02/09/2015.
//  Copyright © 2015 Rocket Apps. All rights reserved.
//

import Foundation
import Security

/**
LatchAccessibility defines the access restrictions for the underlying
keychain items. It maps 1:1 with kSecAttrAccessible values.
*/
public enum LatchAccessibility: RawRepresentable {
    /**
    Data can only be accessed while the device is unlocked. This is recommended
    for items that only need be accessible while the application is in the
    foreground.

    Data with this attribute will migrate to a new device when using encrypted
    backups.
    */
    case whenUnlocked

    /**
    Data can only be accessed once the device has been unlocked after a restart.
    This is recommended for items that need to be accessible by background
    applications.

    Data with this attribute will migrate to a new device
    when using encrypted backups.
    */
    case afterFirstUnlock

    /**
    Data can always be accessed regardless of the lock state of the device.
    This is **not recommended** for anything except system use.

    Items with this attribute will migrate to a new device when using encrypted
    backups.
    */
    case always

    /**
    Data can only be accessed while the device is unlocked. This is recommended
    for items that only need be accessible while the application is in the
    foreground.

    Items with this attribute will never migrate to a new device, so after
    a backup is restored to a new device, these items will be missing.
    */
    case whenUnlockedThisDeviceOnly

    /**
    Data can only be accessed once the device has been unlocked after a restart.
    This is recommended for items that need to be accessible by background
    applications.

    Items with this attribute will never migrate to a new device, so after a
    backup is restored to a new device these items will be missing.
    */
    case afterFirstUnlockThisDeviceOnly

    /**
    Data can always be accessed regardless of the lock state of the device.
    This option is not recommended for anything except system use.

    Items with this attribute will never migrate to a new device, so after a
    backup is restored to a new device, these items will be missing.
    */
    case alwaysThisDeviceOnly

    /**
    Create a new LatchAccessibility value using a kSecAttrAccessible value.

    :param: rawValue A CFString representing a kSecAttrAccessible value.
    */
    public init?(rawValue: CFString) {
        switch rawValue as NSString {
        case kSecAttrAccessibleWhenUnlocked:
            self = .whenUnlocked
        case kSecAttrAccessibleAfterFirstUnlock:
            self = .afterFirstUnlock
        case kSecAttrAccessibleAlways:
            self = .always
        case kSecAttrAccessibleWhenUnlockedThisDeviceOnly:
            self = .whenUnlockedThisDeviceOnly
        case kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly:
            self = .afterFirstUnlockThisDeviceOnly
        case kSecAttrAccessibleAlwaysThisDeviceOnly:
            self = .alwaysThisDeviceOnly
        default:
            return nil
        }

    }

    /**
    Get the rawValue of the current enum type. Will be a kSecAttrAccessible value.
    */
    public var rawValue: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .always:
            return kSecAttrAccessibleAlways
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .alwaysThisDeviceOnly:
            return kSecAttrAccessibleAlwaysThisDeviceOnly
        }
    }
}

private struct LatchState {
    var service: String
    var accessGroup: String?
    var accessibility: LatchAccessibility
}

/**
Latch is a simple abstraction around the iOS and OS X keychain API.
Multiple Latch instances can use the same service, accessGroup, and
accessibility attributes.
*/
public struct Latch {
    fileprivate var state: LatchState

    /**
    Create a new instance of Latch with a service, accessGroup, and accessibility.

    :param: service       The keychain access service to use for records.
    :param: accessGroup   The keychain access group to use - ignored on the iOS simulator.
    :param: accessibility The accessibility class to use for records.

    :returns: An instance of Latch.
    */
    public init(service: String, accessGroup: String? = nil, accessibility: LatchAccessibility = .afterFirstUnlockThisDeviceOnly) {
        state = LatchState(service: service, accessGroup: accessGroup, accessibility: accessibility)
    }

    // MARK - Getters

    /**
    Retreives the data for a given key, or returns nil.
    */
    public func data(forKey key: String) -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnData] = true as AnyObject?

        var dataRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &dataRef)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Latch failed to retrieve data for key '\(key)', error: \(status)")
        }

        return dataRef as? Data
    }

    /**
    Retreives the string value for a given key. It will return nil if the data
    is not a UTF8 encoded string.
    */
    public func string(forKey key: String) -> String? {
        guard let data = data(forKey: key) else { return nil }
        return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String
    }

    // MARK - Setters

    /**
    Set a string value for a given key.
    */
    @discardableResult public func set(_ object: String, forKey key: String) -> Bool {
        print("object: \(object)")
        print("key: \(key)")
        if let data = object.data(using: String.Encoding.utf8) {
            print("set data")
            return set(data, forKey: key)
        }
        else {
            print("failed to set data")
        }
        return false
    }

    /**
    Set an NSCoding compliant object for a given key.
    */
    @discardableResult public func set(_ object: NSCoding, forKey key: String) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        return set(data, forKey: key)
    }

    /**
    Set an NSData blob for a given key.
    */
    @discardableResult public func set(_ object: Data, forKey key: String) -> Bool {
        var query = baseQuery(forKey: key)

        var update = [NSString : AnyObject]()
        update[kSecValueData] = object as AnyObject?
        update[kSecAttrAccessible] = state.accessibility.rawValue

        var status = errSecSuccess
        if data(forKey: key) != nil { // Data already exists, we're updating not writing.
            status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        }
        else { // No existing data, write a new item.
            for (key, value) in update {
                query[key] = value
            }

            status = SecItemAdd(query as CFDictionary, nil)
        }

        if status != errSecSuccess {
            print("Latch failed to set data for key '\(key)', error: \(status)")
            return false
        }

        return true
    }

    /**
    Remove an object from the keychain for a given key.
    */
    @discardableResult public func removeObject(forKey key: String) -> Bool {
        let query = baseQuery(forKey: key)

        if data(forKey: key) != nil {
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess {
                print("Latch failed to remove data for key '\(key)', error: \(status)")
                return false
            }

            return true
        }

        return false
    }

    #if os(iOS) || os(watchOS)
    /**
    Remove all objects from the keychain for the current app. Only available on
    iOS and watchOS.
    */
    @discardableResult public func resetKeychain() -> Bool {
        let query:[String: AnyObject] = [kSecClass as String : kSecClassGenericPassword]
        
        let status = SecItemDelete(query as CFDictionary)
        print("status: \(status)")
        if status != errSecSuccess {
            print("Latch failed to reset keychain, error: \(status)")
            return false
        }

        return true
    }
    #endif

    // MARK - Private

    fileprivate func baseQuery(forKey key: String) -> [NSString : AnyObject] {
        var query = [NSString : AnyObject]()
        if !state.service.isEmpty {
            query[kSecAttrService] = state.service as AnyObject?
        }
        query[kSecClass] = kSecClassGenericPassword
        query[kSecAttrAccount] = key as AnyObject?
        query[kSecAttrGeneric] = key as AnyObject?

        #if TARGET_OS_IOS && !TARGET_OS_SIMULATOR
        // Ignore the access group if running on the iPhone simulator.
        //
        // Apps that are built for the simulator aren't signed, so there's no keychain access group
        // for the simulator to check. This means that all apps can see all keychain items when run
        // on the simulator.
        //
        // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
        // simulator will return -25243 (errSecNoAccessForItem).

        if !state.accessGroup?.isEmpty {
            query[kSecAttrAccessGroup] = state.accessGroup
        }
        #endif

        return query
    }
}
