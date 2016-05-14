//
//  ConnectionPopupViewController.swift
//  Monitoring Application
//
//  Created by Jens Klein on 19.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import UIKit

/// Controller for managing the bluetooth connections
class ConnectionPopupViewController: UIViewController, UITableViewDataSource {
    
    /// Spinner indicating that scanning is in process
    @IBOutlet weak var scanSpinner: UIActivityIndicatorView!
    
    /// Text label that gives textual feedback about the scanning process
    @IBOutlet weak var statusLabel: UILabel!
    
    /// Table view that hold all `PeripheralUITableViewCell`
    @IBOutlet weak var tableView: UITableView!
    
    /// The Bluetooth Manager singeton
    let btManager = BTManager.sharedInstance
    
    /// notification center to setup the observer
    let notificationCenter = NSNotificationCenter.defaultCenter()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup
        tableView.dataSource = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // add notification for Bluetooth state changed
        notificationCenter.addObserver(
            self,
            selector: "btStateChanged:",
            name:BTStateChangedNotification,
            object: nil
        )
        
        // add notification when the device list has changed
        notificationCenter.addObserver(
            self,
            selector: "btPeripheralsListChanged:",
            name:BTPeripheralsListChangedNotification,
            object: nil
        )
        updateAppearance()
        btManager.startScan()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        notificationCenter.removeObserver(self)
        btManager.stopScan()
    }

    /** Method that gets called when the general bluetooth state has changed
     - Parameter note : `NSNotification` that hold userInfo dictionary
     */
    func btStateChanged(note: NSNotification) {
        updateAppearance()
    }
    
    /// Updates appearance based on the `BTManger` instance
    func updateAppearance() {
        switch btManager.btState {
        case .Off:
            scanSpinner.hidden = true
            statusLabel.text = "Turn Bluetooth on"
            break
        case .On:
            scanSpinner.hidden = false
            statusLabel.text = "Scanning"
            break
        case .NotSupported:
            scanSpinner.hidden = true
            statusLabel.text = "Your device does not support BLE"
            break
        }
    }
    
    /** Gets called when the list of scanned Bluetooth devices has changed
     - Parameter note : `NSNotification` that hold userInfo dictionary
    */
    func btPeripheralsListChanged(note: NSNotification){
        tableView.reloadData()
    }
    
    /** creates a user alert that has an OK button
    - Parameter title: The title of the popup
    - Parameter message: The message below the title
    */
    func showErrorMessage(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .Alert
        )
        let okAction = UIAlertAction(title: "OK",
            style: .Default, handler: nil
        )
        alertController.addAction(okAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let btPeripheral = btManager.btPeripherals[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier("btPeripheralCell", forIndexPath: indexPath) as! PeripheralUITableViewCell

        cell.nameLabel?.text = btPeripheral.name
        cell.connected = btPeripheral.isConnected
        
        cell.onConnectPressed = {
            btPeripheral.connect({
                    self.tableView.reloadData()
                }, onError: { message in
                    self.showErrorMessage("Ooops", message: message)
                }
            )
        }
        cell.onDisconnectPressed = { 
            btPeripheral.disconnect()
        }
        
        return cell;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return btManager.btPeripherals.count
    }
    
}



















