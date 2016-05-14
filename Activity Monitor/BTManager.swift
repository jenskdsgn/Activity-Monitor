//
//  BTManager.swift
//  Monitoring Application
//
//  Created by Jens Klein on 20.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
Represents the state of the Bluetooth manager and with that the bluetooth state of the iPad
- NotSupported: The iPad does not support Bluetooth LE
- Off: Bluetooth has been turned off
- On: Bluetooth is on an ready to scan
*/
enum BTState {
    case NotSupported, Off, On
}

/// Manages the list of available devices and connections
class BTManager : NSObject, CBCentralManagerDelegate {


    /// Singleton for the `BTManger`
    static let sharedInstance = BTManager()
    
    /// central Manager from the System
    private var centralManager : CBCentralManager?
    
    /// Notification center that manages notification dispatches
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    
    /// Set of peripherals ever detected since last start
    private var peripherals = Set<CBPeripheral>()
    
    /// Callback when a connection attempt was successful
    private var onConnectionSuccess : (() -> ())?
    
    /// Callback when a connection attempt was unsuccessful
    private var onConnectionError : ((String) -> ())?    
    
    /// Computed property that returns the connected `CBPeripheral` (There can only be one max)
    private var connectedPeripherals : [CBPeripheral] {
        return peripherals.filter({ $0.state == .Connected })
    }
    
    /// Computed property that returns the BTState based on the central manager state
    var btState : BTState {
        return cbTobtManagerState(centralManager!.state)
    }
    
    /// Computed Property that returns the wrapped CBPeripheral in an BTPeripheral
    var btPeripherals : [BTPeripheral] {
        var outArray = [BTPeripheral]()

        peripherals.forEach({
            outArray.append(BTPeripheralAdapter.wrap($0))
        })
        
        return outArray.sort { $0.isConnected && !$1.isConnected }
    }


    /// Singleton construction
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Starts the scan for Bluetooth devices
    func startScan() {
        centralManager!.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    /// Stops the scan for Bluetooth devices
    func stopScan() {
        // remove all devices which are not connected
        peripherals.forEach {
            if $0.state != .Connected {
                peripherals.remove($0)
            }
        }
        centralManager!.stopScan()
    }    
    
    /** Used to connect a `CBPeripheral` using the `BTConnectionAttempt` class with inbuilt pool.
    From nature this is an async call
    - Parameter peripheral: The `CBPeripheral` that should be connected
    - Parameter onSuccess: Gets called when the connection was successful
    - Parameter onerror: Gets called with parameters that hold the error description when connection timed out
    */
    func _connectPeripheral(peripheral: CBPeripheral, onSuccess: ()->(), onError: (String)->()){
        
        // save resources and dont reconnect if connected
        if peripheral.state == .Connected {
            onSuccess()
            return
        }
        
        // check for devices that could block or drive the connection into a bad state
        for _peripheral in peripherals {
            if _peripheral.state == .Connected {
                if let deviceName = _peripheral.name {
                    onError("Disconnect \"\(deviceName)\" before you try to connect to another device.")
                } else {
                    onError("An unkown device is still connected")
                }
                return
            }
        }
        
        BTConnectionAttempt.createAttempt(peripheral, onSuccess: onSuccess, onError: onError, doConnect: {
            self.centralManager!.connectPeripheral(peripheral, options: nil)
        })
        
    }
    
    /** Disconnects a device
    - Parameter peripheral: The `CBPeripheral` that should be disconnected
    */
    func _disconnectPeripheral(peripheral: CBPeripheral) {
        centralManager!.cancelPeripheralConnection(peripheral)
    }
    
    /** Translates a `CBCentralManagerState`to and `BTState`
    - Parameter state: the `CBCentralMangerState` that needs to be translatet
    - Returns: The translated `BTState`
    */
    private func cbTobtManagerState(state: CBCentralManagerState) -> BTState {
        switch state {
        case .PoweredOff:
            return .Off
        case .Unsupported:
            return .NotSupported
        case .PoweredOn:
            return .On
        default:
            return .Off
        }
    }
    
    
    
    // MARK: CBCentralManagerDelegateProtocol
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == .PoweredOn {
            startScan()
        } else {
            stopScan()
        }
        notificationCenter.postNotificationName(BTStateChangedNotification, object: nil)
        notificationCenter.postNotificationName(BTPeripheralsListChangedNotification, object: nil)
    }
    
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        peripherals.insert( peripheral )
        notificationCenter.postNotificationName(BTPeripheralsListChangedNotification, object: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        BTConnectionAttempt.registerSuccessfulConnection(peripheral)
        
        notificationCenter.postNotificationName(BTPeripheralsListChangedNotification, object: nil)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {

        notificationCenter.postNotificationName(BTPeripheralsListChangedNotification, object: nil)
        notificationCenter.postNotificationName(BTDisconnectedDeviceNotification, object: nil)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {

        
    }
}