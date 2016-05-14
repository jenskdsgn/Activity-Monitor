//
//  ATDevice.swift
//  Monitoring Application
//
//  Created by Jens Klein on 23.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation


/**
States the ATDevice can have
- Started: Recording on the device was started
- Stopped: Recording on the device was stopped
- Disconnected: The device was disconnected
- NotCompatible: The Bluetooth device is not compatible as an `Activity Tracker`
*/
enum ATDeviceState {
    case Started, Ready, Stopped, Disconnected, NotCompatible
}

/**
Represents an Activity Tracker device.
As there may be only one connected Activity Tracker this is a singleton
*/
class ATDevice  {
    
    /// Singleton instance
    static let sharedInstance = ATDevice()
    
    /**
    Some bluetooth devices havent flushed their stream completely 
    in this case, if set to `true` the first stream is discarded
    */
    static let tossFirstStream = true
    
    /// Indicates if the first stream was already discarded
    var receivedFirstStream = false
    
    /**
    Public computed property that searches for a connected `BTPeripheral` 
    and computes the state of the `ATDevice`
    */
    var atDeviceState : ATDeviceState {
        if btPeripheral == nil || !btPeripheral!.isConnected {
            return .Disconnected
        }
        if (btPeripheral!.isCompatible != nil) && btPeripheral!.isCompatible! {
            
            if isRecording {
                return .Started
            } else {
                return .Ready
            }
        } else {
            return .NotCompatible
        }
    }
    

    /// Property if the device is currently recording with attached observer
    private var isRecording = false {
        didSet {
            NSNotificationCenter
                .defaultCenter()
                .postNotificationName(ATRecordingStateChangedNotification, object: nil)
        }
    }
    

    /// Requests the Activity Tracker device as an `BTPeripheral`
    private var btPeripheral : BTPeripheral? {
        return BTManager.sharedInstance.activityTracker
    }
    
    private init(){}
    
    /**
    Delegate that gets called when a new Stream was received
    - Parameter data: The raw data stream that was received
    */
    func receivedNewStream(data: NSData) {
        if !receivedFirstStream {
            receivedFirstStream = true
        } else {
            ATSensorValueStack.current()!.parseAndPush(data)
        }
    }
    
    /// Starts the recording
    func start() {
        
        if let activityTracker = btPeripheral {
            receivedFirstStream = false
            ATSensorValueStack.create(atConfiguration.parser)
            
            activityTracker.subscribeWithHandler(
                atConfiguration.rxCharacteristic.UUIDString,
                newData: { data, error in
                    if let _data = data {
                        self.receivedNewStream(_data)
                    } else {
                        // handle error
                    }
                }
            )
            
            activityTracker.write(
                NSData(bytes: atConfiguration.commands.startSequence, length: 1),
                characteristicUUIDString: atConfiguration.txCharacteristic.UUIDString,
                completion: { error in
                    if let err = error {
                        print(err)
                        self.isRecording = false
                    } else {
                        self.isRecording = true
                    }
                }
            )
        } else {
            isRecording = false
        }
    }
    
    /// Stops the recording
    func stop() {
        
        ATSensorValueStack.current()!.finish()
        
        
        if let activityTracker = btPeripheral {
            
            activityTracker.write(
                NSData(bytes: atConfiguration.commands.stopSequence, length: 1),
                characteristicUUIDString: atConfiguration.txCharacteristic.UUIDString,
                completion: { error in
                    if let err = error {
                        print(err)
                    }
                }
            )
        }
        isRecording = false
    }
    
    /**
     Sends a reset sequence to the Activity Tracker device and starts again
     - SeeAlso: `start()`
     */
    func resetAndStart() {

        receivedFirstStream = false
        if let activityTracker = btPeripheral {
            
            activityTracker.write(
                NSData(bytes: atConfiguration.commands.resetSequence, length: 1),
                characteristicUUIDString: atConfiguration.txCharacteristic.UUIDString,
                completion: { error in
                    if let err = error {
                        print(err)
                        self.stop()
                    } else {
                        self.start()
                    }
                }
            )
        } else {
            isRecording = false
        }
    }
    
}


/*
 *  Extending Classes and Protocols here for special usage
 */

extension BTPeripheral {
    var isCompatible : Bool? {
        if self is BTPeripheralAdapter {
            let adapter = self as! BTPeripheralAdapter
            
            if let services =  adapter.peripheral.services {
                
                // check if servies contain the desired service from configuration
                if services.filter({ $0.UUID == atConfiguration.serviceUUID}).isEmpty {
                    return false
                }
                
                for service in services {
                    if let characteristics = service.characteristics {
                        
                        // check for desired characteristics
                        if characteristics.filter({ $0.UUID == atConfiguration.rxCharacteristic }).isEmpty {               return false
                        }
                        if characteristics.filter({ $0.UUID == atConfiguration.txCharacteristic }).isEmpty {               return false
                        }
                        return true
                    }
                }
            }
        }
        return nil
    }
}

extension BTManager {
    var activityTracker : BTPeripheral? {
        for peripheral in self.btPeripherals {
            if peripheral.isCompatible != nil && peripheral.isCompatible! {
                return peripheral
            }
        }
        return nil
    }
}
