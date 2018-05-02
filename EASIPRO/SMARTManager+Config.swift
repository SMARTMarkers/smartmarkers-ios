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
	
	
	public func fetchPrescribing(callback: @escaping ([ProcedureRequest]?, Error?) -> Void) {
		
		guard let patient = patient else {
			callback(nil, nil)
			return
		}
		let searchParams = ["patient": patient.id!.string]
		search(type: ProcedureRequest.self, params: searchParams) { (requests, error) in
			if nil != error {
				callback(nil, error)
				return
			}
			
			if let requests = requests {
				
				let promeasures = requests.map({ (procedureRequest) -> PROMeasure2 in
					let title = procedureRequest.ep_titleCode ?? procedureRequest.ep_titleCategory ?? procedureRequest.id!.string
					let identifier = procedureRequest.id!.string
					
					let prom = PROMeasure2(title: title, identifier: identifier)
					prom.prescribingResource = procedureRequest
					return prom
				})
			}
			
		}
		
	}
    
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
    
    public class func smartClient() -> Client {
        
        let baseURL = URL(string: "https://launch.smarthealthit.org/v/r3/sim/eyJoIjoiMSIsImkiOiIxIiwiZSI6InNtYXJ0LVByYWN0aXRpb25lci03MTAzMjcwMiJ9/fhir")!
        let settings = [ "client_name" : "EASIPRO",
                         "redirect"    : "easipro-home://callback",
                         "scope"       : "openid profile user/*.*",
                         "client_id"   : "7c5dc7c9-74ca-451a-bd3d-eeb21bb66e93",
                         ]
        return SMARTManager.client(with: baseURL, settings: settings)
    }
    
    
    
	
	
}
