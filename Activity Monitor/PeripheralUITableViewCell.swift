//
//  PeripheralUITableViewCell.swift
//  Monitoring Application
//
//  Created by Jens Klein on 20.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import UIKit

/// Custom table cell that presents a general bluetooth device
class PeripheralUITableViewCell: UITableViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var connectionButton: UIButton!
    @IBOutlet weak var checkIcon: UIImageView!

    
    private var showConnected = false
    
    /// Returns a bool wether a certain bluetooth device is connected or not
    var connected: Bool {
        get {
            return showConnected
        }
        set(newValue) {
            showConnected = newValue
            let title = newValue ? "disconnect" : "connect"
            connectionButton.setTitle(title, forState: .Normal)
            checkIcon.hidden = !newValue
        }
    }
    
    /// When a touch event was triggered on an unconnected device this callback gets called
    var onConnectPressed: (() -> ())?
    
    /// When a touch event was triggered on a connected device this callback gets called
    var onDisconnectPressed: (() -> ())?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        connected = false
        setIconTint(checkIcon, color: self.tintColor)
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
    
    /// Callback when the connect button on the right of the cell is triggered
    @IBAction func connectButtonPressed() {
        if connected {
            if let callback = onDisconnectPressed {
                callback()
            }
        } else {
            if let callback = onConnectPressed {
                callback()
            }
        }
    }
}
