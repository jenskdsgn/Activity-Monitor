//
//  ATSensorValueStack.swift
//  Monitoring Application
//
//  Created by Jens Klein on 23.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation

/**
The Sensorstack holds all sensor reads for all Sensors

Right now the implementation is like only having one instance
but to make it easier in the future to save and load stacks
locally you may want multiple instance of that class so
this is implementented "Model-like"
*/
class ATSensorValueStack : NSObject{
    
    /// In the future there may be mutltiple stacks. This property holds the current stack in use
    private static var currentStack : ATSensorValueStack?
    
    /**
    A stream from an Activity Tracker must be parsed into an `ATSensorValue`.
    This propertie holds the class that can properly parse the bytestream
    */
    private let parser : ATInputStreamParser!
    
    /// This stack is a `Dictionary` with a sensor as key and and `ATSensorValue` array as value
    private var stack = [ ATSensor : [ATSensorValue]  ]()
    
    /**
    When the first value was pushed on the stack, this property holds the relative time
    of the first packet in milliseconds since the Activity Tracker started
     */
    private var firstValueAtRelTime : UInt32?
    
    /**
    When the first value was pushed on the stack, this property holds the absolute time
    of the first packet. Absolute time is written by the App
    */
    private var firstValueAtAbsTime : NSDate?
    
    /**
    When the finish method was called and the recording was stopped, this property holds
    the absolute time of this event
    */
    private var stoppedAtTime : NSDate?
    
    /// This callback gets called when a new sensor value was successfully parsed and pushed on the stack
    private var newValueCallback: ((ATSensor)->())?
    
    /**
    Public computed property that returns the start time
    - SeeAlso: `firstValueAtAbsTime` property
    */
    var startTime : NSDate? {
        return firstValueAtAbsTime
    }
    
    /**
    Public computed property that returns the endTime.
    - SeeAlso: `stoppedAtTime`
    */
    var endTime : NSDate? {
        return stoppedAtTime
    }
    
    ///Public computed property that returns the duration calculated from start and last value
    var durationInSeconds : Double {
        var secondsTillStarted : Double = 0.0
        stack.forEach {
            $0.1.forEach {
                secondsTillStarted = max( Double($0.relTimestamp - firstValueAtRelTime!)/1000.0, secondsTillStarted )
            }
        }
        return secondsTillStarted
    }
    
    /// Public computed Property that returns all `ATSensors` that get pushed on the stack
    var sensors : [ATSensor] {
        return Array(stack.keys)
    }
    
    /**
    Returns the sensor values for a specific sensor. 
    - Parameter sensor: declares for which sensor the value should be returned
    - Returns: An array of tuples with their x (Time) and y value
    */
    func tuplesForSensor(sensor: ATSensor) -> [(x: Double, y: Double)] {
        var tuples = [(x: Double, y: Double)]()
        
        if let values = stack[sensor] {
            for value in values {
                
                // POTENTIAL PITFALL: after about 50 days of operation the microcontroller will overflow 
                // and start again with "0".
                var secondsTillStarted = Double((value.relTimestamp - firstValueAtRelTime!))/1000.0
                if secondsTillStarted < 0.001 { secondsTillStarted = 0.000 } // rounding double errors away
                tuples.append( (
                    x: secondsTillStarted,
                    y: Double(value.value!)
                ) )
            }
        }
        return tuples
    }
    
    /// Initialises an `ATSensorValueStack` object with a depenecy injected parser
    private init(parser: ATInputStreamParser){
        self.parser = parser
    }
    
    /// Returns the current `ATSensorValueStack` object
    static func current() -> ATSensorValueStack? {
        return currentStack
    }
    
    /**
    Creates and returns a new `ATSensorValueStack` object based on
    the `ATConfiguration`
    - Parameter parser: A parser bject that can convert a bytestream into a an `ATSensorValue`
    - Returns: the created stack-object
    - SeeAlso: `ATConfiguration.swift`
    */
    static func create(parser : ATInputStreamParser) -> ATSensorValueStack {
        currentStack = ATSensorValueStack(parser: parser)
        for sensor in atConfiguration.sensors {
            currentStack!.stack[sensor] = []
        }
        return currentStack!
    }
    
    /**
     Destroys an existing `ATSensorValueStack` object
     - Parameter stack: The stack object that should be destroyed
     */
    static func destroy(stack: ATSensorValueStack) {
        currentStack = nil
    }
    
    /**
     Converts the bytestream into an `ATSensorValue` and pushes it on the stack
     - Parameter data: The bytestream as an `NSData` object
    */
    func parseAndPush(data: NSData) {
        if firstValueAtAbsTime == nil {
            firstValueAtAbsTime = NSDate()
        }
        
        if let parsedData = try? atConfiguration.parser.parse(data){
            if firstValueAtRelTime == nil {
                firstValueAtRelTime = parsedData.value.relTimestamp
            } else {
                firstValueAtRelTime = min(firstValueAtRelTime!, parsedData.value.relTimestamp)
            }
            stack[parsedData.sensor]!.append(parsedData.value)
            
            if let callback = newValueCallback {
                callback(parsedData.sensor)
            }
        } else {
            // error handling
        }
    }
    
    /**
    Sets the finish time
    - SeeAlso: stoppedAtTime
    */
    func finish() {
        stoppedAtTime = NSDate()
    }
    
    /**
    Subscribes to get called when a new value was pushed
    - Parameter handler: This function gets called when a new value was pushed with a sensor as the parameter
    - SeeAlso: newValueCallbkack
    */
    func subscribeForNewValue(handler: (ATSensor)->()) {
        newValueCallback = handler
    }
}


extension ATSensor : Hashable, Equatable {
    var hashValue : Int {
        return (self.name+self.unit).hash
    }
}

func == (lhs: ATSensor, rhs: ATSensor) -> Bool {
    return lhs.name == rhs.name && lhs.unit == rhs.unit
}