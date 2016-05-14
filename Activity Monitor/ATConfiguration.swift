//
//  ATConfiguration.swift
//  Monitoring Application
//
//  Created by Jens Klein on 22.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation
import CoreBluetooth



// Configuration for a specific Activity Tracker Device
// Defined in ATConfiguration.swift
// easily exchangable if desired later
let atConfiguration = ATConfiguration(
    serviceUUIDString:      "6E400001-B5A3-F393-E0A9-E50E24DCCA9E",
    txCharacteristicString: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E",
    rxCharacteristicString: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E",
    commands: ATCommands(
        startSequence: [0x01],
        stopSequence:  [0x00],
        resetSequence: [0x02]
    ),
    sensors: [
        ATSensor(name: "EDA",              unit: "µS",  description: "Conductance", code: 0x03),
        ATSensor(name: "Heartrate",        unit: "BPM", description: "Heartrate",   code: 0x04),
        ATSensor(name: "Room Temperature", unit: "°C",  description: "Temperature", code: 0x01),
        ATSensor(name: "Acceleration",     unit: "g",   description: "g-Force",     code: 0x02),
    ],
    parser: ATInputStreamParserImpl()
)

/// Holds the information about remote Peripheral
struct ATConfiguration {
    
    /// Service UUID that defines the service to listen on
    let serviceUUID : CBUUID!
    
    /// The Bluetooth LE characteristic to transmit streams
    let txCharacteristic : CBUUID!
    
    /// The Bluetooth LE characteristic to receive streams
    let rxCharacteristic : CBUUID!
    
    /// Commands to operate the remote peripheral
    let commands : ATCommands!
    
    /// Sensors that are installed on the remote peripheral
    let sensors : [ATSensor]!
    
    /// Parser implementation that is able to convert a bytestream into an `ATSensorValue`
    let parser : ATInputStreamParser!
    
    /// Init all properties
    init(
        serviceUUIDString: String,
        txCharacteristicString : String,
        rxCharacteristicString : String,
        commands: ATCommands,
        sensors: [ATSensor],
        parser: ATInputStreamParser
    ) {
        serviceUUID = CBUUID(string: serviceUUIDString)
        txCharacteristic = CBUUID(string: txCharacteristicString)
        rxCharacteristic = CBUUID(string: rxCharacteristicString)
        self.commands = commands
        self.sensors = sensors
        self.parser = parser
    }
}

/// Holds the known commands to be supported by the remote peripheral
struct ATCommands {
    /// Sequence to be send to the remote peripheral to initiate a recording
    let startSequence : [UInt8]!
    
    /// Sequence to be send to the remote peripheral to stop a recording
    let stopSequence : [UInt8]!
    
    /// Sequence to be send to the remote peripheral to reset the device
    let resetSequence : [UInt8]!
}

/// Holds all information that a sensor has
struct ATSensor {
    
    /// Display name of the sensor
    let name : String!
    
    /// Display unit for y axis
    let unit : String!
    
    /// Display the type of value
    let description : String!
    
    /// Sensor value as identificator
    let code : UInt8
}
