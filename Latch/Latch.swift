//
//  Latch.swift
//  Latch
//
//  Created by Daniel Tomlinson on 02/09/2015.
//  Copyright © 2015 Rocket Apps. All rights reserved.
//

import Foundation
import Security

public enum LatchAccessibility {
    case WhenUnlocked
    case AfterFirstUnlock
    case Always
    case WhenUnlockedThisDeviceOnly
    case AfterFirstUnlockThisDeviceOnly
    case AlwaysThisDeviceOnly
    
    internal func toString() -> String {
        switch self {
        case .WhenUnlocked:
            return kSecAttrAccessibleWhenUnlocked as String
        case .AfterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock as String
        case .Always:
            return kSecAttrAccessibleAlways as String
        case .WhenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        case .AfterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        case .AlwaysThisDeviceOnly:
            return kSecAttrAccessibleAlwaysThisDeviceOnly as String
        }
    }
}

private struct LatchState {
    var service: String
    var accessGroup: String?
    var accessibility: LatchAccessibility
}

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
        update[kSecAttrAccessible as String] = state.accessibility.toString()
        
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