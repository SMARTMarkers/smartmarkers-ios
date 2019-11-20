//
//  OMRON+InstrumentProtocol.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 3/14/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

open class OMRON: Instrument {
    
    final var auth: OAuth2!
    
    var usageDescription: String?
    
    public var sm_title: String
    
    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_resultingFhirResourceType: [FHIRSearchParamRelationship]?
    
    public init(authSettings: [String:Any], usageDescription: String? = nil, callbackHandler: inout OAuth2?) {

        self.auth = OAuth2CodeGrant(settings: authSettings)
        self.auth.forgetTokens()
        self.auth.logger = OAuth2DebugLogger(.trace)
        self.sm_title = "OMRON Blood Pressure"
        self.sm_identifier = "omron-blood-pressure"
        self.sm_code = SMARTMarkers.Instruments.Web.OmronBloodPressure.coding
        self.sm_type = .WebRepository
        self.sm_resultingFhirResourceType = [
            FHIRSearchParamRelationship(Observation.self, ["code": sm_code!.sm_searchableToken()!])
        ]
        callbackHandler = self.auth
        
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let omronTaskViewController = OmronTaskViewController(auth: auth)
        callback(omronTaskViewController, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let dict = result.stepResult(forStepIdentifier: "OMRONFetchStep")?.firstResult?.userInfo {
            let diastolic = dict["diastolic"] as! Int
            let systolic  = dict["systolic"]  as! Int
            let bp = Observation.sm_BloodPressure(systolic: systolic, diastolic: diastolic, date: Date(), sourceCode: sm_code!)
            return SMART.Bundle.sm_with([bp])
        }
        return nil
    }
    
    
    
}
