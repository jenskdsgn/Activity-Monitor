//
//  FlowStateMachine.swift
//  Monitoring Application
//
//  Created by Jens Klein on 19.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import XCTest
import SwiftState

class FlowStateMachineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        FlowStateMachine.machine <- .Initial
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    // Test if in initial state initially, duh!!
    func testInitialState(){
        // inital state is initial
        XCTAssertEqual(FlowStateMachine.machine.state, FlowState.Initial)
    }
    
    // Test some events
    func testFlowEvents(){
        // From initial -> Connect = Connected
        FlowStateMachine.machine <-! .Connect
        XCTAssertEqual(FlowStateMachine.machine.state, FlowState.Connected)
        
        // From Connected -> Disconnect = Initial
        FlowStateMachine.machine <-! .Disconnect
        XCTAssertEqual(FlowStateMachine.machine.state, FlowState.Initial)
        
        // From Initial -> Connect = Connected
        FlowStateMachine.machine <-! .Connect
        XCTAssertEqual(FlowStateMachine.machine.state, FlowState.Connected)
        
        // From Connected -> Start = Started
        FlowStateMachine.machine <-! .Start
        XCTAssertEqual(FlowStateMachine.machine.state, FlowState.Started)
        
        // From Started -> Disconnect = Stopped
        FlowStateMachine.machine <-! .Disconnect
        XCTAssertEqual(FlowStateMachine.machine.state, FlowState.Finished)
        
        // From Stopped -> Sync = Synced
        FlowStateMachine.machine <-! .Sync
        XCTAssertEqual(FlowStateMachine.machine.state, FlowState.Synced)
        
    }
    

}
