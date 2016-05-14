//
//  SyncData.swift
//  Monitoring Application
//
//  Created by Jens Klein on 26.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation
import SwiftyJSON


let defaultSettings = SyncSettings(
    serverAddress: NSURL(string: "http://Jenss-iMac:8080")
)

/// Holds the settings used by the `SyncData` class
struct SyncSettings {
    var serverAddress  : NSURL!
}


/**
Collects all the requiered data for the sync process and 
serializes it into a JSON stream. Also holds the settings
for the sync.
*/
class SyncData {
    
    /// Beside the default settings the user can alter these
    static var userDefinedSettings : SyncSettings?
    
    /// Public computed property that returns the appropiate settings
    static var settings : SyncSettings {
        if userDefinedSettings != nil {
            return userDefinedSettings!
        } else {
            return defaultSettings
        }
    }
    
    
    // only use static class
    private init(){}
    
    
    /**
    Takes a `UserInfo` and `ATSensorValueStack` object and serializes it into a JSON stream
    - Parameter userInfo: Information entered by the user
    - Parameter sensorData: Data collected during the recording session
    - Returns: JSON stream
    */
    static func JSONData(userInfo: UserInfo, sensorData: ATSensorValueStack?) -> JSON?  {
        
        if let data = sensorData {
        
            // create empty json object
            var json = JSON([:])
            
            json["person"] = [
                "id" : userInfo.assignedID != nil ? userInfo.assignedID! : userInfo.id,
                "name" : userInfo.name != nil ? userInfo.name! : ""
            ]
            
            json["activity"] = [:]
            json["activity"]["start_time"].int = Int(data.startTime!.timeIntervalSince1970)
            json["activity"]["end_time"].int = Int(data.endTime!.timeIntervalSince1970)
            json["activity"]["info"].string = userInfo.comments != nil ? userInfo.comments! : ""
            json["activity"]["sensors"] = [:]
            
            for sensor in data.sensors {
                json["activity"]["sensors"][sensor.name] = [:]
                json["activity"]["sensors"][sensor.name]["x_unit"].string = "Seconds"
                json["activity"]["sensors"][sensor.name]["y_unit"].string = sensor.unit!
                json["activity"]["sensors"][sensor.name]["values"].arrayObject = data.tuplesForSensor(sensor).map({
                    ["rel_time" : $0.x, "value" : $0.y]
                })
            }
        
            return json
        }
        return nil
    }
    
}