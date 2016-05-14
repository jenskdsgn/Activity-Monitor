//
//  ATInputStream.swift
//  Monitoring Application
//
//  Created by Jens Klein on 23.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation

/// Error enum that can happen in the process of parsing
/// - SensorCodeNotFoundInConfiguration: A sensor code could not found in the `ATConfiguration` object
enum ATInputStreamParserError : ErrorType {
    case SensorCodeNotFoundInConfiguration(sensorCodeNotFound: String)
}

/// Interface for the Parser
protocol ATInputStreamParser {
    func parse(data: NSData) throws -> (sensor: ATSensor, value: ATSensorValue)
}


/**
Specific parser that fullfils the designed protocol needs
Implement new parser if the protocol changes
*/
class ATInputStreamParserImpl : ATInputStreamParser {
    
    /* Implementation of the `ATInputStreamParser` Protocoll
    - Parameter data: The bytestream to be parsed
    - Returns: Tuple consisting of the sensor and the value
    - Throws: ATInputParseError object
    */
    func parse(data: NSData) throws -> (sensor: ATSensor, value: ATSensorValue){
        
        var packetNo : UInt32 = 0
        var sensorType : UInt8 = 0
        var sensorValueInt : UInt32 = 0
        var sensorExponent : UInt8 = 0
        var relTime : UInt32 = 0
        
        data.getBytes( &packetNo, range: NSMakeRange(0,4) )
        data.getBytes( &sensorType, range: NSMakeRange(4,1) )
        data.getBytes( &sensorValueInt, range: NSMakeRange(5,4) )
        data.getBytes( &sensorExponent, range: NSMakeRange(9,1) )
        data.getBytes( &relTime, range: NSMakeRange(10,4) )
        
        let atSensor : ATSensor
        
        let sensorsFiltered = atConfiguration.sensors.filter({ $0.code == sensorType})
        guard sensorsFiltered.count == 1 else {
            throw ATInputStreamParserError.SensorCodeNotFoundInConfiguration(
                sensorCodeNotFound: sensorType.description
            )
        }
        
        atSensor = sensorsFiltered[0]

        let value : Float = Float(sensorValueInt) * pow( 10.0, -Float(sensorExponent) )
        
        return (
            atSensor,
            ATSensorValue(value: value, relTime: relTime, packetNo: packetNo)
        )
    }    
}
