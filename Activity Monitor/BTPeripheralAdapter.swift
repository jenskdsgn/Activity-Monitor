//
//  BTPeripheralAdapter.swift
//  Monitoring Application
//
//  Created by Jens Klein on 20.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation
import CoreBluetooth


/**
Interface for a Bluetooth device
Hides the complexity of CBPeripheral
and CoreBluetooth
*/
protocol BTPeripheral{
    var name : String { get }
    var isConnected : Bool { get }
    
    func connect(onSuccess: ()->(), onError: (String)->())
    func disconnect()
    
    func write(
        data: NSData,
        characteristicUUIDString: String,
        completion: (NSError?)->()
    )
    
    func subscribeWithHandler(
        characteristicUUIDString: String,
        newData: (NSData?, NSError?)->()
    )
}




/// Adapts CBPeripheral to a simpler BTPeripheral class
class BTPeripheralAdapter : NSObject, BTPeripheral, CBPeripheralDelegate {
    
    /// The `CBPeripheral`to be adapted
    internal let peripheral : CBPeripheral!
    
    /// An array holding all wrapped `CBPeripherals` used
    private static var adapterCache = [BTPeripheralAdapter]()
    
    /** When a device has more than one services the discovery of all characteristic
    is ready when all services were scanned. This property holds the number of services
    left to scan
    */
    private var numberOfServicesLeftToScan : Int = 0
    
    /// Gets called when all services were discovered
    private var discoveredDoneCallback : ((NSError?)->())?
    
    /// gets called when a new bytestream was registered by this instance
    private var newDataCallback : ((NSData?, NSError?)->())?
    
    /// inits object. may only be called by the wrap method
    private init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        
        super.init()
        
        self.peripheral.delegate = self
    }
    
    /// Name of the device. If not supplied "unkwon"
    var name : String {
        if let name = peripheral.name {
            return name
        } else {
            return "Unkown"
        }
    }
    
    /// When connected this is true otherwise false
    var isConnected : Bool {
        return peripheral.state == .Connected
    }
    
    /** wraps a `CBPeripheral` and initialises a BTPeripheral object
    - Parameter: peripheral to be wrapped
    - Returns: Wrapped peripheral in `BTPeripheral`
    */
    static func wrap(peripheral: CBPeripheral) -> BTPeripheral {
        for _peripheral in adapterCache {
            if _peripheral.peripheral == peripheral {
                return _peripheral as BTPeripheral
            }
        }
        let btPeripheral = BTPeripheralAdapter(peripheral: peripheral)
        adapterCache.append(btPeripheral)
        return btPeripheral as BTPeripheral
    }
    
    /// Instance method to connect the device
    func connect(onSuccess: () -> (), onError: (String) -> ()) {
        BTManager.sharedInstance._connectPeripheral(
            self.peripheral,
            onSuccess: {
                self.discoverAll{ error in
                    if let err = error {
                        onError(err.description)
                    } else {
                        onSuccess()
                    }
                }
            },
            onError: onError
        )
    }
    
    /// Instance method to disconnect the device
    func disconnect() {
        BTManager.sharedInstance._disconnectPeripheral(self.peripheral)
    }
    
    
    /** Discovers als Services and their characteristics
    - Parameter completion: Callback that gets called when fully discovered
    */
    private func discoverAll( completion: (NSError?) -> () ) {
        peripheral.discoverServices(nil)
        discoveredDoneCallback = completion
    }
    
    /// Triggers the Observer to notify new fully discovered devices are available
    private func notifyDiscovered() {
        NSNotificationCenter.defaultCenter().postNotificationName(
            BTConnectedDeviceFullyDiscoveredNotification,
            object: nil
        )
    }
    
    /** Writing to the remote peripheral
    - Parameter data: Bytestream to be written
    - Parameter characteristicUUIDString: String that hold the id of the txCharacteristic
    - Parameter completion: Callback that gets called when process is completed.`NSError` is present
     if not successful
    */
    func write(data: NSData, characteristicUUIDString: String, completion: (NSError?)->() ) {
        
        if let characteristic = characteristicByUUIDString(characteristicUUIDString) {
            peripheral.writeValue(data, forCharacteristic: characteristic, type: .WithoutResponse)
        } else {
            completion(
                NSError(
                    domain: NSBundle.mainBundle().bundleIdentifier!,
                    code: 2000,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Device offers doesn't offer that characteristic"
                    ]
                )
            )
        }
        completion(nil)
    }
    
    /** One interesseted object or class can subcribe to the `BTPeripheral` to receive new streams
    - Parameter characteristicsUUIDString: The rxCharacteristic of the remote Peripheral
    - Parameter newData: Callback with new data or error as argument
    */
    func subscribeWithHandler( characteristicUUIDString: String, newData: (NSData?, NSError?)->() ) {
        if let characteristic = characteristicByUUIDString(characteristicUUIDString) {
            newDataCallback = newData
            peripheral.setNotifyValue(true, forCharacteristic: characteristic)
        } else {
            newData( nil,
                NSError(
                    domain: NSBundle.mainBundle().bundleIdentifier!,
                    code: 2000,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Device offers doesn't offer that characteristic"
                    ]
                )
            )
        }        
    }
    
    
    
    // MARK: HELPER FUNCTION
    private func characteristicByUUIDString(uuidString: String) -> CBCharacteristic? {
        let uuid = CBUUID(string: uuidString)
        if peripheral.services == nil {return nil}
        for service in peripheral.services! {
            if service.characteristics == nil {return nil }
            for characteristic in service.characteristics! {
                if characteristic.UUID == uuid {
                    return characteristic
                }
            }
        }
        return nil
    }
    
    // MARK: CBPeripheralDelegateProtocol
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let services = peripheral.services {
            services.forEach{ service in
                peripheral.discoverCharacteristics(nil, forService: service)
            }
            numberOfServicesLeftToScan = services.count
        } else {
            if let err = error {
                discoveredDoneCallback!(err)
            } else {
                discoveredDoneCallback!(
                    NSError(
                        domain: NSBundle.mainBundle().bundleIdentifier!,
                        code: 1000,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Device offers no services"
                        ]
                    )
                )
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if --numberOfServicesLeftToScan <= 0 {
            discoveredDoneCallback!(nil)
            notifyDiscovered()
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        //print(characteristic.value)
        if let err = error {
            newDataCallback!(nil, err)
        } else {
            newDataCallback!(characteristic.value, nil)
        }
    }
    

    
    
}



