//
//  Latch.swift
//  Latch
//
//  Created by  Danielle Lancashireon 02/09/2015.
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
    for items that only need be accesible while the application is in the 
    foreground. 
    
    Data with this attribute will migrate to a new device when using encrypted
    backups.
    */
    case WhenUnlocked
    
    /**
    Data can only be accessed once the device has been unlocked after a restart.
    This is recommended for items that need to be accesible by background
    applications.
    
    Data with this attribute will migrate to a new device
    when using encrypted backups.
    */
    case AfterFirstUnlock
    
    /**
    Data can always be accessed regardless of the lock state of the device. 
    This is **not recommended** for anything except system use.
    
    Items with this attribute will migrate to a new device when using encrypted 
    backups.
    */
    case Always
    
    /**
    Data can only be accessed while the device is unlocked. This is recommended 
    for items that only need be accesible while the application is in the 
    foreground.
    
    Items with this attribute will never migrate to a new device, so after
    a backup is restored to a new device, these items will be missing.
    */
    case WhenUnlockedThisDeviceOnly
    
    /**
    Data can only be accessed once the device has been unlocked after a restart.
    This is recommended for items that need to be accessible by background
    applications.
    
    Items with this attribute will never migrate to a new device, so after a 
    backup is restored to a new device these items will be missing.
    */
    case AfterFirstUnlockThisDeviceOnly
    
    /**
    Data can always be accessed regardless of the lock state of the device. 
    This option is not recommended for anything except system use. 
    
    Items with this attribute will never migrate to a new device, so after a 
    backup is restored to a new device, these items will be missing.
    */
    case AlwaysThisDeviceOnly

    /**
    Create a new LatchAccessibility value using a kSecAttrAccessible value.
    
    :param: rawValue A CFString representing a kSecAttrAccessible value.
    */
    public init?(rawValue: CFString) {
        switch rawValue as NSString {
        case kSecAttrAccessibleWhenUnlocked:
            self = .WhenUnlocked
        case kSecAttrAccessibleAfterFirstUnlock:
            self = .AfterFirstUnlock
        case kSecAttrAccessibleAlways:
            self = .Always
        case kSecAttrAccessibleWhenUnlockedThisDeviceOnly:
            self = .WhenUnlockedThisDeviceOnly
        case kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly:
            self = .AfterFirstUnlockThisDeviceOnly
        case kSecAttrAccessibleAlwaysThisDeviceOnly:
            self = .AlwaysThisDeviceOnly
        default:
            return nil
        }

    }
    
    /**
    Get the rawValue of the current enum type. Will be a kSecAttrAccessible value.
    */
    public var rawValue: CFString {
        switch self {
        case .WhenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .AfterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .Always:
            return kSecAttrAccessibleAlways
        case .WhenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .AfterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .AlwaysThisDeviceOnly:
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
    private var state: LatchState
    
    /**
    Create a new instance of Latch with a service, accessGroup, and accessibility.
    
    :param: service       The keychain access service to use for records.
    :param: accessGroup   The keychain access group to use - ignored on the iOS simulator.
    :param: accessibility The accessibility class to use for records.
    
    :returns: An instance of Latch.
    */
    public init(service: String, accessGroup: String? = nil, accessibility: LatchAccessibility = .AfterFirstUnlockThisDeviceOnly) {
        state = LatchState(service: service, accessGroup: accessGroup, accessibility: accessibility)
    }
    
    // MARK - Getters
    
    /**
    Retreives the data for a given key, or returns nil.
    */
    public func dataForKey(key: String) -> NSData? {
        var query = baseQuery(forKey: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne as String
        query[kSecReturnData as String] = true
    
        var dataRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionaryRef, &dataRef)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Latch failed to retrieve data for key '\(key)', error: \(status)")
        }

        return dataRef as? NSData
    }
    
    // MARK - Setters
    
    /**
    Set a string value for a given key.
    */
    public func setObject(object: String, forKey key: String) -> Bool {
        if let data = object.dataUsingEncoding(NSUTF8StringEncoding) {
            return setObject(data, forKey: key)
        }
        
        return false
    }
    
    /**
    Set an NSCoding compliant object for a given key.
    */
    public func setObject(object: NSCoding, forKey key: String) -> Bool {
        let data = NSKeyedArchiver.archivedDataWithRootObject(object)
        return setObject(data, forKey: key)
    }
    
    /**
    Set an NSData blob for a given key.
    */
    public func setObject(object: NSData, forKey key: String) -> Bool {
        var query = baseQuery(forKey: key)
        
        var update = [String : AnyObject]()
        update[kSecValueData as String] = object
        update[kSecAttrAccessible as String] = state.accessibility.rawValue
        
        var status = errSecSuccess
        if dataForKey(key) != nil { // Data already exists, we're updating not writing.
            status = SecItemUpdate(query, update)
        }
        else { // No existing data, write a new item.
            for (key, value) in update {
                query[key] = value
            }
            
            status = SecItemAdd(query, nil)
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
    public func removeObjectForKey(key: String) -> Bool {
        let query = baseQuery(forKey: key)
        
        if dataForKey(key) != nil {
            let status = SecItemDelete(query)
            if status != errSecSuccess {
                print("Latch failed to remove data for key '\(key)', error: \(status)")
                return false
            }
            
            return true
        }
        
        return false
    }
    
    /**
    Remove all objects from the keychain for the current app.
    */
    public func resetKeychain() -> Bool {
        let query = [kSecClass as String : kSecClassGenericPassword as String]
        let status = SecItemDelete(query)
        if status != errSecSuccess {
            print("Latch failed to reset keychain, error: \(status)")
            return false
        }
        
        return true
    }
    
    // MARK - Private
    
    private func baseQuery(forKey key: String) -> [String : AnyObject] {
        var query = [String : AnyObject]()
        if state.service.characters.count > 0 {
            query[kSecAttrService as String] = state.service
        }
        query[kSecClass as String] = kSecClassGenericPassword as String
        query[kSecAttrAccount as String] = key
        
        #if TARGET_OS_IOS && !TARGET_OS_SIMULATOR
            // Ignore the access group if running on the iPhone simulator.
            //
            // Apps that are built for the simulator aren't signed, so there's no keychain access group
            // for the simulator to check. This means that all apps can see all keychain items when run
            // on the simulator.
            //
            // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
            // simulator will return -25243 (errSecNoAccessForItem).
            
            if state.accessGroup?.characters.count > 0 {
                query[kSecAttrAccessGroup as String] = state.accessGroup
            }
        #endif

        return query
    }
}