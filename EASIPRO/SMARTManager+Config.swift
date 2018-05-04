//
//  SMARTManager+Patient.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 01/05/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

extension SMARTManager {
    
    public class func patientClient() -> Client {
        
        let settings_smart = [
            "client_name" : "EASI PRO",
            "client_id"   : "7c5dc7c9-74ca-451a-bd3d-eeb21bb66e93",
            "redirect"    : "easipro-home://callback",
            "scope"       : "openid profile launch/patient patient/*.*"
        ]
        let base_url_smart = URL(string: "https://launch.smarthealthit.org/v/r3/sim/eyJrIjoiMSIsImIiOiIyZTI3YzcxZS0zMGM4LTRjZWItOGMxYy01NjQxZTA2NmMwYTQifQ/fhir")!
        return SMARTManager.client(with: base_url_smart, settings: settings_smart)
        
    }
    
    public class func practitionerClient() -> Client {
        
        let baseURL = URL(string: "https://launch.smarthealthit.org/v/r3/sim/eyJoIjoiMSIsImkiOiIxIiwiZSI6InNtYXJ0LVByYWN0aXRpb25lci03MTAzMjcwMiJ9/fhir")!
        let settings = [ "client_name" : "EASIPRO",
                         "redirect"    : "easipro-clinic://callback",
                         "scope"       : "openid profile user/*.*",
                         "client_id"   : "7c5dc7c9-74ca-451a-bd3d-eeb21bb66e93",
                         ]
        return SMARTManager.client(with: baseURL, settings: settings)
    }
    
    
    
	
	
}
