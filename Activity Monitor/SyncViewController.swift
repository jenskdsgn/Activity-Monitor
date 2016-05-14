//
//  SyncViewController.swift
//  Monitoring Application
//
//  Created by Jens Klein on 26.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftState

/// View Controller that manages the sync operations
class SyncViewController: UIViewController {
    
    /// Textfield to display or enter the server address
    @IBOutlet weak var serverTextField: UITextField!
    
    /// Textview to display the JSON stream
    @IBOutlet weak var jsonTextView: UITextView!
    
    /// Spinner to indicate that syncing is in progress
    @IBOutlet weak var syncingIndicator: UIView!
    
    /// Computed Property that gets the current userInfo
    var userInfo : UserInfo {
        if UserInfo.current() != nil {
            return UserInfo.current()!
        } else {
            return UserInfo.create()
        }
    }
    
    /// caches the json Data
    private var jsonDataCache : JSON?
    
    
    /// Computed property that either generates JSON data or takes it from the cache
    var jsonData : JSON? {
        if jsonDataCache == nil {
            let json = SyncData.JSONData(
                userInfo,
                sensorData: ATSensorValueStack.current()!
            )
            jsonDataCache = json
        }
        return jsonDataCache        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupContent()
    }
    
    /// Sets up the default or already entered form content
    func setupContent() {
        serverTextField.text = SyncData.settings.serverAddress.absoluteString

        if let jsonString = jsonData?.rawString() {
            jsonTextView.text = jsonString
        } else {
            jsonTextView.text = "No Data"
        }

    }

    /// Sets up the correct display of the text view
    func setupTextView() {
        let borderColor = UIColor(
            colorLiteralRed: 204/255,
            green: 204/255,
            blue: 204/255,
            alpha: 1.0
        )
        
        jsonTextView.layer.borderWidth = CGFloat(0.5)
        jsonTextView.layer.borderColor = borderColor.CGColor
        jsonTextView.layer.cornerRadius = CGFloat(5.0)
    }

    /** Creates an alert with the message of the result
     - Parameter message: Message of the sync result
    */
    func alertSyncResult(message: String) {
    
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
    
    /** Method that get called when the cancel button was pressed
    - Parameter sender: The calling button
     */
    @IBAction func cancelPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    /** Method that get called when the sync button was pressed
     - Parameter sender: The calling button
     */
    @IBAction func syncPressed(sender: UIBarButtonItem) {
        // verify entered url
        if serverTextField.text != SyncData.settings.serverAddress.absoluteString {
            if let urlString = serverTextField.text {
                if let validURL = NSURL(string: urlString) {
                    var settings = SyncData.settings
                    settings.serverAddress = validURL
                    SyncData.userDefinedSettings = settings
                } else {
                    alertSyncResult("URL format not valid")
                }
            } else {
                alertSyncResult("No URL was supplied")
            }
        }
        
        let rawObject : AnyObject = jsonData!.rawValue
        
        syncingIndicator.hidden = false
        
        Alamofire.request(
            .POST,
            SyncData.settings.serverAddress,
            parameters: ["json_data": rawObject ],
            encoding: .JSON
            )
        .response { request, response, data, error in
            
            if let err = error {
                self.alertSyncResult(err.localizedDescription)
            } else {
                self.alertSyncResult("The Sync was successful")
                FlowStateMachine.machine <-! .Sync
                if let home = self.presentingViewController as? HomeViewController {
                    home.updateAppearanceByState()
                }
            }
            self.syncingIndicator.hidden = true
        }
    }
}




















