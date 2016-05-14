//
//  UserInfoViewController.swift
//  Monitoring Application
//
//  Created by Jens Klein on 26.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import UIKit


/// Controller for managing the user info form
class UserInfoViewController: UIViewController {
    
    /// Button on top right that is for saving
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    /// Textfield to display or enter the id
    @IBOutlet weak var idTextField: UITextField!
    
    /// Textfield to display or enter the name of the user
    @IBOutlet weak var nameTextField: UITextField!
    
    /// Textfield to display or enter comments
    @IBOutlet weak var commentsTextView: UITextView!
    
    /// Computed Property that gets the current userInfo
    var userInfo : UserInfo {
        if UserInfo.current() != nil {
            return UserInfo.current()!
        } else {
            return UserInfo.create()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupContent()
    }

    
    
    /** Method that gets called when the save button was pressed
    - Parameter sender: The calling button
    */
    @IBAction func savePressed(sender: UIBarButtonItem) {
        
        if let assignedID = idTextField.text {
            if assignedID.isEmpty {
                idTextField.text = nil
                userInfo.assignedID = nil
            } else {
                userInfo.assignedID = assignedID
            }
        }
        
        if let name = nameTextField.text {
            if name.isEmpty {
                userInfo.name = nil
            } else {
                userInfo.name = name
            }
        }

        
        if let comments = commentsTextView.text {
            if comments.isEmpty {
                userInfo.comments = nil
            } else {
                userInfo.comments = comments
            }
        }
        
        
    }

    /** Method that gets called when the cancel button was pressed
    - Parameter sender: The calling button
    */
    @IBAction func cancelPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: {
            
        })
    }
    
    /// Sets up the default or already entered form content
    func setupContent(){
        
        idTextField.placeholder = userInfo.id
        nameTextField.placeholder = "optional"
        
        if let assignedID = userInfo.assignedID {
            idTextField.text = assignedID
        }
        
        if let name = userInfo.name {
            nameTextField.text = name
        }
        
        if let comment = userInfo.comments {
            commentsTextView.text = comment
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
        
        commentsTextView.layer.borderWidth = CGFloat(0.5)
        commentsTextView.layer.borderColor = borderColor.CGColor
        commentsTextView.layer.cornerRadius = CGFloat(5.0)
    }

}
