//
//  LatchTests.swift
//  LatchTests
//
//  Created by Danielle Lancashire on 02/09/2015.
//  Copyright © 2015 Rocket Apps. All rights reserved.
//

import XCTest
@testable import Latch

func data(_ string: String) -> Data {
    return string.data(using: String.Encoding.utf8)!
}

func AssertSuccessfulWrite(ofData data: Data?, forKey key: String, inLatch latch: Latch, file: StaticString = #file, line: UInt = #line) {    
    let read = latch.data(forKey: key)
    XCTAssertEqual(data, read, file: file, line: line)
}

class LatchTests: XCTestCase {
    var latch: Latch!
    
    override func setUp() {
        super.setUp()
        latch = Latch(service: "co.rocketapps.latch.tests")
        #if os(iOS) || os(watchOS)
        latch.resetKeychain()
        #endif
    }
    
    override func tearDown() {
        latch = nil
        super.tearDown()
    }
    
    func test_can_write_string_to_keychain() {
        let testKey = "test_can_write_string_to_keychain"
        let testString = "Hello, world."
        
        latch.set(testString, forKey: testKey)
        let retreivedData = latch.data(forKey: testKey)
        
        XCTAssertNotNil(retreivedData)
        
        AssertSuccessfulWrite(ofData: data(testString), forKey: testKey, inLatch: latch)
    }

		func test_can_read_string_from_keychain() {
		    let testKey = "test_can_read_string_From_keychain"
				let testString = "Hello, world."

				latch.set(testString, forKey: testKey)
				let retreived = latch.string(forKey: testKey)

				XCTAssertNotNil(retreived)
				XCTAssertEqual(testString, retreived)
		}
    
    func test_can_write_nsdata_to_keychain() {
        let testKey = "test_can_write_nsdata_to_keychain"
        let testString = "Hello, world."
        let testData = data(testString)
        
        latch.set(testData, forKey: testKey)        
        AssertSuccessfulWrite(ofData: testData, forKey: testKey, inLatch: latch)
    }
    
    func test_can_write_nscoding_compliant_object_to_keychain() {
        let testKey = "test_can_write_nscoding_compliant_object_to_keychain"
        let testObject = ["hello" : "world"] as NSDictionary
        
        latch.set(testObject, forKey: testKey)

        
        AssertSuccessfulWrite(ofData: NSKeyedArchiver.archivedData(withRootObject: testObject), forKey: testKey, inLatch: latch)
    }
    
    func test_can_read_nil_data_for_unset_key() {
        let testKey = "test_can_read_nil_data_for_unset_key"
        
        XCTAssertNil(latch.data(forKey: testKey))
    }
    
    func test_can_update_items() {
        let testKey = "test_can_update_items"
        let testString = "Hello, world."
        let testUpdateString = "World, Hello."
        
        latch.set(testString, forKey: testKey)

        
        // Assert initial set worked
        AssertSuccessfulWrite(ofData: data(testString), forKey: testKey, inLatch: latch)
        
        // Set item for the same key
        latch.set(testUpdateString, forKey: testKey)

        // Assert the update worked
        AssertSuccessfulWrite(ofData: data(testUpdateString), forKey: testKey, inLatch: latch)
    }
    
    func test_can_remove_object_for_key() {
        let testKey = "test_can_remove_object_for_key"
        let testObject = "Hello, world."
        
        latch.set(testObject, forKey: testKey)
        
        AssertSuccessfulWrite(ofData: data(testObject), forKey: testKey, inLatch: latch)
        
        latch.removeObject(forKey: testKey)
        
        AssertSuccessfulWrite(ofData: nil, forKey: testKey, inLatch: latch)
    }
    
    func test_safe_to_remove_object_for_an_unset_key() {
        let testKey = "test_safe_to_remove_object_for_an_unset_key"
        
        latch.removeObject(forKey: testKey)
    }
    
    #if os(iOS) || os(watchOS)
    func test_can_reset_keychain() {
        let values = [
            ("key1", data("value")),
            ("key2", data("yet another value")),
            ("key3", data("some other value"))
        ]
        
        for (key, data) in values {
            latch.set(data, forKey: key)

        }
        
        latch.resetKeychain()
        
        for (key, _) in values {
            AssertSuccessfulWrite(ofData: nil, forKey: key, inLatch: latch)
        }
    }
    #endif
}
