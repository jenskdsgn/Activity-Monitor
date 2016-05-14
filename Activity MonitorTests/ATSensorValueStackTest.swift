//
//  ATSensorValueStackTest.swift
//  Monitoring Application
//
//  Created by Jens Klein on 24.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import XCTest
import Foundation

class ATSensorValueStackTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    
    
    override func tearDown() {
        
        if let current = ATSensorValueStack.current() {
            ATSensorValueStack.destroy(current)
        }        

        super.tearDown()
    }
    
    
    /*
     * Test if the management of the stack builder is as expected
     * This becomes more important when using multiple stacks but 
     * as described this should be future-proof.
     */
    
    func testCreationAndReleasing() {
        
        // Must be nil because it wasnt created yet
        XCTAssertNil( ATSensorValueStack.current() )
        
        // created must the current ATSensorValueStack
        let createdStack = ATSensorValueStack.create(ATInputStreamParserImpl())
        
        // current is now the recently created on
        XCTAssertTrue(createdStack == ATSensorValueStack.current()!)
        
        // destroy and check current for nil
        ATSensorValueStack.destroy(createdStack)
        XCTAssertNil(ATSensorValueStack.current())
    }
    
    
    
    /*
     * Test for valid data. The Stream should be parsed and pushed on
     * top of the stack with rel time 0 (since this is the first package)
     * the value expected and parsed should be almost the same, saying
     * it must be less than 0.001.
     */
    
    func testParserForValidStream() {
        
        // valid TestData (little endian)
        let validbytes : [UInt8] = [
            0x01, 0x00, 0x00, 0x00,                 // counter stream
            (atConfiguration.sensors.first?.code)!, // sensor code
            0x01, 0x02, 0x00, 0x00,                 // value unsigned long 258
            0x02,                                   // comma offset
            0x01, 0x00, 0x00, 0x00,                 // rel time value
        ]
        let validTestData = NSData(bytes: validbytes, length: validbytes.count)
        
        ATSensorValueStack.create(ATInputStreamParserImpl())
        ATSensorValueStack.current()!.parseAndPush(validTestData)
        
        // check if value was pushed
        let tuples = ATSensorValueStack.current()!.tuplesForSensor(atConfiguration.sensors.first!)
        
        XCTAssertTrue(tuples.count == 1)
        
        XCTAssertTrue( abs(tuples[0].y - Double(5.13)) < 0.001  )
        XCTAssertEqual(tuples[0].x, 0.0)
        
    }
    
    
    
    /*
     * Test for invalid data. In this case a nonexisting sensortype code is used
     * Application shouldn't crash, just dont push that value on the stack
     */
    
    func testParserForInvalidStream() {
        
        // valid TestData (little endian)
        let invalidbytes : [UInt8] = [
            0x01, 0x00, 0x00, 0x00,     // counter stream
            0xFF,                       // NONEXISTING SENSOR CODE
            0x01, 0x02, 0x00, 0x00,     // value unsigned long 258
            0x02,                       // comma offset
            0x01, 0x00, 0x00, 0x00,     // rel time value
        ]
        let invalidTestData = NSData(bytes: invalidbytes, length: invalidbytes.count)
        
        ATSensorValueStack.create(ATInputStreamParserImpl())
        ATSensorValueStack.current()!.parseAndPush(invalidTestData)
        
        // check if value was pushed
        let tuples = ATSensorValueStack.current()!.tuplesForSensor(atConfiguration.sensors.first!)
        
        XCTAssertTrue(tuples.count == 0)
        
    }
    
    func testEmptyStack() {
        
        ATSensorValueStack.create(ATInputStreamParserImpl())
        let sensorTuples = ATSensorValueStack.current()!.tuplesForSensor(atConfiguration.sensors[0])
        
        XCTAssertTrue(sensorTuples.count == 0)
    }    
    
}
