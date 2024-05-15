//
//  LocalAuth.swift
//  Easipro
//
//  Created by Raheel Sayeed on 19/01/18.
//  Copyright © 2018 Raheel Sayeed. All rights reserved.
//

import UIKit
import LocalAuthentication

public class LocalAuth: NSObject {
    
    public class func verifyDeviceUser(_ msg : String? = nil, _ callback: @escaping (_ successfulAuth: Bool, _ error: Error?) -> Void) {
        
        let context = LAContext()
        let verifyMsg = msg ?? "Practitioner: Authentication Required"
        var error : NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: verifyMsg, reply: { (success, eerror) in
                
                if success {
//                    smLog("successful authentication")
                    callback(true, error)
                    
                }
                else       {
                    
                    smLog("no successful authentication")
                    
                    switch eerror!._code {
                    case LAError.systemCancel.rawValue:
                        smLog("Auth cancelled by system")
                    case LAError.userCancel.rawValue:
                        smLog("Auth cancelled by User")
                    case LAError.userFallback.rawValue:
                        smLog("user selected custom password")
                    default:
                        smLog("Authentication failed")
                    }
                    
                    callback(false, error)
                    

                }
                
            })
        }
        else {
            
            callback(false, error)

        }
        
        
        
    }

}
