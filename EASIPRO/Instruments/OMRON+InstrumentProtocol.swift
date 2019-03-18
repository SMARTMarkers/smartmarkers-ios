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

open class OMRON: InstrumentProtocol {
    
    public var settings: [String: Any]?
    
    public init(authSettings: [String:Any]? = nil) {
        self.settings = authSettings
    }
    
    public var ip_title: String {
        return "OMRON Blood Pressure"
    }
    
    public var ip_identifier: String {
        return "omron-blood-pressure"
    }
    
    public var ip_code: Coding? {
        return nil
    }
    
    public var ip_version: String? {
        return "0.1"
    }
    
    public var ip_resultingFhirResourceType: [PROFhirLinkRelationship]? {
        return nil
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let omronTaskViewController = OmronTaskViewController(oauthSettings: settings!)
        
        callback(omronTaskViewController, nil)
        
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let dict = result.stepResult(forStepIdentifier: "OMRONFetchStep")?.firstResult?.userInfo {
            let diastolic = dict["diastolic"] as! Int
            let systolic  = dict["systolic"]  as! Int
            let bp = Observation.sm_BloodPressure(systolic: systolic, diastolic: diastolic, date: Date())
            let qrId = "urn:uuid:\(UUID().uuidString)"
            let entry = BundleEntry()
            entry.fullUrl = FHIRURL(qrId)
            entry.resource = bp
            entry.request = BundleEntryRequest(method: .POST, url: FHIRURL("Observation")!)
            let bundle = SMART.Bundle()
            bundle.entry = [entry]
            bundle.type = BundleType.transaction
            return bundle
        }
        return nil
    }
    
    
    
}
