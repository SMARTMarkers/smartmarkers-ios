//
//  OMRON+InstrumentProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/14/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

open class OMRON: Instrument {
    
    public internal(set) final var auth: OAuth2!
    
    public init(authSettings: [String:Any]) {

        self.auth = OAuth2CodeGrant(settings: authSettings)
        self.auth.forgetTokens()
        self.auth.logger = OAuth2DebugLogger(.trace)
        self.ip_title = "OMRON Blood Pressure"
    }
    
    public var ip_title: String
    
    public var ip_identifier: String? {
        return "omron-blood-pressure"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_Coding("omron-blood-pressure", "http://omronhealthcare.com", "OMRON Blood Pressure")
    }
    
    public var ip_version: String? {
        return "0.1"
    }
    
    public var ip_publisher: String?
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? {
        return [
            FHIRSearchParamRelationship(Observation.self, ["code": ip_code!.sm_searchableToken()!])
        ]
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let omronTaskViewController = OmronTaskViewController(auth: auth)
        callback(omronTaskViewController, nil)
        
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let omronTaskViewController = OmronTaskViewController(auth: auth)
        callback(omronTaskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let dict = result.stepResult(forStepIdentifier: "OMRONFetchStep")?.firstResult?.userInfo {
            let diastolic = dict["diastolic"] as! Int
            let systolic  = dict["systolic"]  as! Int
            let bp = Observation.sm_BloodPressure(systolic: systolic, diastolic: diastolic, date: Date())
            return SMART.Bundle.sm_with([bp])
        }
        return nil
    }
    
    
    
}
