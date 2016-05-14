//
//  FlowStateMachine.swift
//  Monitoring Application
//
//  Created by Jens Klein on 19.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation
import SwiftState

/**
Represent the states of the application
- Initial: Starting point of the machine
- Connected: A Bluetooth device is connected
- Started: A recording was started
- Synced: The recorded data was published to the server of choice
- Finished: The recording was stopped
*/
enum FlowState: StateType {
    case Initial, Connected, Started, Synced, Finished
}

/**
Represent events that can occour during runtime
- Connect: event when a device was connected to the system
- Disconnect: event when a device was disconnected from the system
- Start: event when the recording was started
- Sync: event when syncing was successful
- Finish: event when the recording was stoppped
*/
enum FlowEvent: EventType {
    case Connect, Disconnect, Start, Sync, Finish
}

/// State machine for the flow during the use of the application
class FlowStateMachine {
    
    /// Actual state machine defined by state types, event types and routes
    static let machine = StateMachine<FlowState, FlowEvent>(state: .Initial) { machine in
        
        machine.addRoutes(event: FlowEvent.Connect, transitions: [
            .Initial => .Connected
        ])
        
        machine.addRoutes(event: FlowEvent.Disconnect, transitions: [
            .Started => .Finished,
            .Connected => .Initial,
            
        ])
        
        machine.addRoutes(event: FlowEvent.Start, transitions: [
            .Connected => .Started,
        ])
        
        machine.addRoutes(event: FlowEvent.Finish, transitions: [
            .Started => .Finished
        ])
        
        
        machine.addRoutes(event: FlowEvent.Sync, transitions: [
            .Finished => .Synced
        ])
        
        machine.addRoute(.Any => .Initial)
        
        
        machine.addErrorHandler { event, fromState, toState, userInfo in
            print("[ERROR] \(fromState) => \(toState)")
        }
    }
    
}