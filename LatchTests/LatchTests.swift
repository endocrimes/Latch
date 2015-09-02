//
//  LatchTests.swift
//  LatchTests
//
//  Created by  Danielle Lancashireon 02/09/2015.
//  Copyright © 2015 Rocket Apps. All rights reserved.
//

import XCTest
@testable import Latch

func data(string: String) -> NSData {
    return string.dataUsingEncoding(NSUTF8StringEncoding)!
}

func AssertSuccessfulWrite(ofData data: NSData?, forKey key: String, inLatch latch: Latch, file: String = __FILE__, line: UInt = __LINE__) {
    
    let read = latch.dataForKey(key)
    
    XCTAssertEqual(data, read, file: file, line: line)
}

class LatchTests: XCTestCase {
    var latch: Latch!
    
    override func setUp() {
        super.setUp()
        latch = Latch(service: "co.rocketapps.latch.tests")
        latch.resetKeychain()
    }
    
    override func tearDown() {
        latch = nil
        super.tearDown()
    }
    
    func test_can_write_string_to_keychain() {
        let testKey = "test_can_write_string_to_keychain"
        let testString = "Hello, world."
        
        latch.setObject(testString, forKey: testKey)
        
        let retreivedData = latch.dataForKey(testKey)
        
        XCTAssertNotNil(retreivedData)
        
        AssertSuccessfulWrite(ofData: data(testString), forKey: testKey, inLatch: latch)
    }
    
    func test_can_write_nsdata_to_keychain() {
        let testKey = "test_can_write_nsdata_to_keychain"
        let testString = "Hello, world."
        let testData = data(testString)
        
        latch.setObject(testData, forKey: testKey)
        
        AssertSuccessfulWrite(ofData: testData, forKey: testKey, inLatch: latch)
    }
    
    func test_can_write_nscoding_compliant_object_to_keychain() {
        let testKey = "test_can_write_nscoding_compliant_object_to_keychain"
        let testObject = ["hello" : "world"] as NSDictionary
        
        latch.setObject(testObject, forKey: testKey)
        
        AssertSuccessfulWrite(ofData: NSKeyedArchiver.archivedDataWithRootObject(testObject), forKey: testKey, inLatch: latch)
    }
    
    func test_can_read_nil_data_for_unset_key() {
        let testKey = "test_can_read_nil_data_for_unset_key"
        
        XCTAssertNil(latch.dataForKey(testKey))
    }
    
    func test_can_update_items() {
        let testKey = "test_can_update_items"
        let testString = "Hello, world."
        let testUpdateString = "World, Hello."
        
        latch.setObject(testString, forKey: testKey)
        
        // Assert initial set worked
        AssertSuccessfulWrite(ofData: data(testString), forKey: testKey, inLatch: latch)
        
        // Set item for the same key
        latch.setObject(testUpdateString, forKey: testKey)

        // Assert the update worked
        AssertSuccessfulWrite(ofData: data(testUpdateString), forKey: testKey, inLatch: latch)
    }
    
    func test_can_remove_object_for_key() {
        let testKey = "test_can_remove_object_for_key"
        let testObject = "Hello, world."
        
        latch.setObject(testObject, forKey: testKey)
        
        AssertSuccessfulWrite(ofData: data(testObject), forKey: testKey, inLatch: latch)
        
        latch.removeObjectForKey(testKey)
        
        AssertSuccessfulWrite(ofData: nil, forKey: testKey, inLatch: latch)
    }
    
    func test_safe_to_remove_object_for_an_unset_key() {
        let testKey = "test_safe_to_remove_object_for_an_unset_key"
        
        latch.removeObjectForKey(testKey)
    }
    
    func test_can_reset_keychain() {
        let values = [
            ("key1", data("value")),
            ("key2", data("yet another value")),
            ("key3", data("some other value"))
        ]
        
        for (key, data) in values {
            latch.setObject(data, forKey: key)
        }
        
        latch.resetKeychain()
        
        for (key, _) in values {
            AssertSuccessfulWrite(ofData: nil, forKey: key, inLatch: latch)
        }
    }
    
}
