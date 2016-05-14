//
//  HomeViewController.swift
//  Monitoring Application
//
//  Created by Jens Klein on 18.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import UIKit
import SwiftState
import SwiftChart

/// General view controller
class HomeViewController: UIViewController {
    
    /// Connect button for connecting a peripheral
    @IBOutlet weak var connectButton: UIButton!
    
    /// Start button for starting the recording
    @IBOutlet weak var startButton: UIButton!
    
    /// User data button to enter user data
    @IBOutlet weak var userDataButton: UIButton!
    
    /// Sync button to sync data to an external server
    @IBOutlet weak var syncButton: UIButton!
    
    /// Icon to emphazise connection meaning
    @IBOutlet weak var btleIcon: UIImageView!
    
    /// Icon to emphaszie the start function
    @IBOutlet weak var startIcon: UIImageView!
    
    /// Icon to emphazise the user data edit function
    @IBOutlet weak var editIcon: UIImageView!
    
    /// Icon to emphazise the sync function
    @IBOutlet weak var syncIcon: UIImageView!
    
    /// Vertical stack view to hold ChartViewContainer
    @IBOutlet weak var chartStack: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup this instance as a receiver
        setupNotifications()
        
        // Set the image color to white programmatically
        setIconTint(btleIcon, color: UIColor.whiteColor())
        setIconTint(startIcon, color: UIColor.whiteColor())
        setIconTint(editIcon, color: UIColor.whiteColor())
        setIconTint(syncIcon, color: UIColor.whiteColor())
        
        updateAppearanceByState()
    }
    
    
    // MARK: Notifications
    
    /** Method that gets called when the general bluetooth state has changed 
    - Parameter note : `NSNotification` that hold userInfo dictionary
    */
    func btStateChanged(note: NSNotification) {
        let state = BTManager.sharedInstance.btState
        
        if state == BTState.Off || state == BTState.NotSupported {
            FlowStateMachine.machine <-! .Disconnect
            updateAppearanceByState()
        }
        
    }
    
    /** Method that gets called when any BTPeripheral was fully discovered
     - Parameter note : `NSNotification` that hold userInfo dictionary
     */
    func btConnectedDeviceFullyDiscovered(note: NSNotification) {
        if ATDevice.sharedInstance.atDeviceState == .Ready {
            FlowStateMachine.machine <-! .Connect
            updateAppearanceByState()
        }
    }
    
    /** Method that gets called when a Bluetooth device was disconnected
     - Parameter note : `NSNotification` that hold userInfo dictionary
     */
    func btDisconnectedDevice(note: NSNotification) {
        FlowStateMachine.machine <-! .Disconnect
        updateAppearanceByState()
    }
    
    /** Method that gets called when recording state has changed
     - Parameter note : `NSNotification` that hold userInfo dictionary
     */
    func atRecordingStateChanged(note: NSNotification) {
        switch ATDevice.sharedInstance.atDeviceState {
        case .Disconnected:
            FlowStateMachine.machine <-! .Disconnect
            break
        case .Stopped:
            FlowStateMachine.machine <-! .Finish
            break
        case .Started:
            FlowStateMachine.machine <-! .Start
            if let stack = ATSensorValueStack.current() {
                setupCharts()
                stack.subscribeForNewValue{ sensor in
                    self.updateCharts(sensor)
                }
            }
        case .NotCompatible:
            // alert if not compatible
            FlowStateMachine.machine <-! .Disconnect
            break
        case .Ready:
            if FlowStateMachine.machine.state == .Started {
                FlowStateMachine.machine <-! .Finish
            } else {
                FlowStateMachine.machine <-! .Connect
            }
            
            break
        }
        updateAppearanceByState()
    }
    
    /// Based on the state by the `FlowStateMachine` this method updates the appearance
    func updateAppearanceByState() {
        
        let state = FlowStateMachine.machine.state
        
        print(state)
        
        // defaults
        connectButton.enabled = true
        startButton.enabled = false
        userDataButton.enabled = false //change back to false
        syncButton.enabled = false // change back to false
        
        connectButton.setTitle( "Connect",  forState: .Normal)
        startButton.setTitle(   "Start",    forState: .Normal)
        userDataButton.setTitle("User Data",forState: .Normal)
        syncButton.setTitle(    "Sync",     forState: .Normal)
        
        if state ==  .Connected {
            startButton.enabled = true
        }
        
        if state == .Started {
            startButton.setTitle("End", forState: .Normal)
            startButton.enabled = true
            userDataButton.enabled = true
        }
        
        if state == .Finished || state == .Synced {
            startButton.setTitle("Finished", forState: .Normal)
            startButton.enabled = false
            userDataButton.enabled = true
            syncButton.enabled = true
        }
    }
    
    /** Updates the Chart that is associated with the sensor
    - Parameter sensor: Sensor that requieres an visual update
    */
    func updateCharts(sensor: ATSensor) {
        if let chartContainerArray = chartStack.subviews as? [ChartContainerUIView] {
            // update all x axises
            
            let xMax = ATSensorValueStack.current()!.durationInSeconds
            chartContainerArray.forEach{
                $0.chartView!.setXLabel(xMax)
                $0.chartView!.setNeedsDisplay()
            }
            
            for chartContainer in chartContainerArray.filter({ $0.sensorCode == sensor.code }){
                let chartSeries = ATSensorValueStack.current()!.tuplesForSensor(sensor)
                if !chartSeries.isEmpty {
                    chartContainer.chartView!.setDataTuples(chartSeries)
                }
            }
            
        }
    }
    
    /**
     Colorizes an icon in an an `UIImageView`
     - Parameter imageView: The image view that hold the icon to be colorized
     - Parameter color: The color to be applied on the icon
     */
    func setIconTint(imageView: UIImageView, color: UIColor) {
        imageView.image? = (imageView.image?.imageWithRenderingMode(.AlwaysTemplate))!
        imageView.tintColor = color
    }
    
    /// Sets this instance to an Observer using the observer pattern of the `Foundation framework
    func setupNotifications() {
        // add notification for Bluetooth state changed
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "btStateChanged:",
            name:BTStateChangedNotification,
            object: nil
        )
        
        // add notfication when a compatible device was discovered
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "btConnectedDeviceFullyDiscovered:",
            name:BTConnectedDeviceFullyDiscoveredNotification,
            object: nil
        )
        
        // add notfication when a compatible device was disconnected
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "btDisconnectedDevice:",
            name:BTDisconnectedDeviceNotification,
            object: nil
        )
        
        // add notfication when a recording state changed
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "atRecordingStateChanged:",
            name:ATRecordingStateChangedNotification,
            object: nil
        )

    }
    
    /// Initialises the chart views based on the `ATConfiguration`
    func setupCharts() {
        
        //remove if chartContainer exist
        chartStack.subviews
            .filter({ $0 is ChartContainerUIView })
            .forEach{ chartStack.removeArrangedSubview($0)  }

        // add new chartContainer according to the configuration
        for sensor in atConfiguration.sensors {
            let chartViewContainer = ChartContainerUIView()
            let chartView = chartViewContainer.chartView
            
            chartViewContainer.descriptionLabel.text = sensor.name
            chartViewContainer.yLabel.text = "\(sensor.description) [\(sensor.unit)]"
            chartViewContainer.sensorCode = sensor.code
            
            if sensor == atConfiguration.sensors.last {
                chartViewContainer.xLabel.text = "time in minutes"
            } else {
                //chartView.bottomInset = CGFloat(0.0)
                chartView.xLabelsFormatter = { i,f in return ""}
                chartViewContainer.xLabel.text = ""
            }
            
            chartView.yLabelsFormatter = { i,f in
                let nf = NSNumberFormatter()
                nf.numberStyle = .DecimalStyle
                nf.minimumFractionDigits = 0
                nf.maximumFractionDigits = 2
                return nf.stringFromNumber(f)!
            }
            
            chartStack.addArrangedSubview(chartViewContainer)
        }
    }
    
    /** Gets called when the start button was pressed 
    - Parameter sender: The calling button
    */
    @IBAction func startPressed(sender: UIButton) {
       let atDevice = ATDevice.sharedInstance
        
        switch FlowStateMachine.machine.state {
        case .Started:
            // REALLY want to stop? ALERT!!
            atDevice.stop()
            break
        case .Connected:
            atDevice.resetAndStart()
            break

        default:
            break
        }
        
    }
}