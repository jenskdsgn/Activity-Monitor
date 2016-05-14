//
//  BTConnectionTimeoutManager.swift
//  Monitoring Application
//
//  Created by Jens Klein on 22.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation
import CoreBluetooth

/// A Pool of connection attempts and connection attempt in one class
class BTConnectionAttempt : NSObject{
    
    /// Pool of connection attempts
    private static var pool = [BTConnectionAttempt]()
    
    /// describes the timeout of a connection attempt in seconds
    private static let timeoutValue : Double = 10
    
    /// describes the maxmium pool size
    private static let poolMaxSize : Int = 10
    
    /// Timer to check for timeozt
    private var timer : NSTimer!
    
    /// Peripheral on which the attempt should be on
    private let peripheral : CBPeripheral!
    
    /// Callback for the successful connection attempt
    private let onSuccess : (()->())!
    
    /// Callback for an failed connection attempt
    private let onError : ((String)->())!
    
    /// initialiser that performs the connection attempt after creation
    private init(peripheral: CBPeripheral, onSuccess: ()->(), onError: (String)->(), doConnect: ()->()) {
        self.peripheral = peripheral
        self.onSuccess = onSuccess
        self.onError = onError
        super.init()
        
        doConnect()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(
            NSTimeInterval(BTConnectionAttempt.timeoutValue),
            target: self,
            selector: "connectionTimedOut:",
            userInfo: [peripheral: peripheral],
            repeats: false
        )
    }
    
    /// Pops the associated timer from the queue
    deinit {
        timer.invalidate()
        timer = nil
    }    
    
    /**
    Gets called by the timer if no connection was established and the time ran out
    - Parameter timer: Timer object associated with the attempt
    */
    func connectionTimedOut(timer: NSTimer){
        BTConnectionAttempt.pool
            .filter({ $0.peripheral == timer.userInfo?.peripheral })
            .forEach { $0.onError("Connection Timeout") }
        
        BTConnectionAttempt.pool =
            BTConnectionAttempt.pool.filter{
                $0.peripheral != timer.userInfo?.peripheral
            }
    }
    
    /**
    Initiates an connection attempt
    - Parameter peripheral: peripheral to connect
    - Parameter onSuccess: Callback when attempt was successful
    - Parameter onError: Callback when error occured with message as argument
    - Parameter doConnect: Closure for the actual call to connect
    */
    static func createAttempt(
        peripheral: CBPeripheral,
        onSuccess: ()->(),
        onError: (String)->(),
        doConnect: ()->()) {
        // discard if peripheral is already trying to connect
        if pool.filter({ $0.peripheral == peripheral }).count > 0 {
            return
        }
        
        // reject if pool is all in use
        if pool.count >= poolMaxSize {
            onError("Too many connection attempts at the moment.")
            return
        }
        
        pool.append(
            BTConnectionAttempt(
                peripheral: peripheral, onSuccess: onSuccess, onError: onError, doConnect:  doConnect
            )
        )
    }
    
    /** 
    Since the connection itself is not performed in this class, the manager class must notify
    this instance with this method that the connection was successful
    - Parameter peripheral: The peripheral which was connected successfully
    */
    static func registerSuccessfulConnection(peripheral: CBPeripheral) {
        pool.filter({ $0.peripheral == peripheral}).forEach{ $0.onSuccess() }        
        pool = pool.filter{ $0.peripheral != peripheral }        
    }
    
}