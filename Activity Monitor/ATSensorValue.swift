//
//  ATSensorValue.swift
//  Monitoring Application
//
//  Created by Jens Klein on 23.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation

/** 
Represents one sensor read
- relTimestamp: Milliseconds since the Activity Tracker Device started
- value: The sensor value
- packetNo: The Activity Tracker device gives each packet a consecutive integer
*/

class ATSensorValue {
    
    /// The timestamp since when the Activity Tracker was started in milliseconds
    let relTimestamp : UInt32
    
    /// The value that was read, aggregated and proccessed by the Activity Tracker
    let value : Float!
    
    /// The Activity Tracker sends consecutive packet numbers for every sensor read
    let packetNo : UInt32
    
    /// Initialises all properties
    init(value: Float, relTime: UInt32, packetNo : UInt32) {
        self.value = value
        self.relTimestamp = relTime
        self.packetNo = packetNo
    }
}
