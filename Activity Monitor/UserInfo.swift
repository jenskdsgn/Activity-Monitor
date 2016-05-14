//
//  UserInfo.swift
//  Monitoring Application
//
//  Created by Jens Klein on 26.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import Foundation

/**
 User Info hold information about the user and also comments about a recording
 
 Right now the implementation is like only having one instance
 but to make it easier in the future to save and load stacks
 locally you may want multiple instance of that class so
 this is implementented "Model-like"
 */
class UserInfo : NSObject{
    
    /// In the future there may be mutltiple stacks. This property holds the current instance in use
    private static var currentInstance : UserInfo?

    /**
    ID that is given by the system
    - SeeAlso: `init`
    */
    var id : String!
    
    /// The ID given by the user
    var assignedID : String?
    
    /// The name of the user
    var name : String?
    
    /// Comments that are entered by the user
    var comments : String?
    
    /// Initialises and sets a calulated ID based on the hash of the current time
    private override init(){
        self.id = String(abs(NSDate().hash))
    }
    
    /**
     Returns the current `UserInfo` object
     - SeeAlso: `currentInstance`
     - Returns: The UserInfo - object currently in use
     */
    static func current() -> UserInfo? {
        return currentInstance
    }
    
    /**
     Creates and returns a new `UserInfo` object
     - Returns: the created `UserInfo` object
     */
    static func create() -> UserInfo {
        currentInstance = UserInfo()
        return currentInstance!
    }
    
    /**
     Destroys an existing `UserInfo` object
     - Parameter stack: The `UserInfo` object that should be destroyed
     */
    static func destroy(userInfo: UserInfo) {
        currentInstance = nil
    }
}