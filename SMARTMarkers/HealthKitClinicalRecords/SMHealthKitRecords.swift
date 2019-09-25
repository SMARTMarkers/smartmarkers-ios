//
//  SMHealthKitRecords.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/20/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

@available(iOS 12.0, *)
public class SMHealthKitRecords: Instrument {
    
    
    
    public init() { }
    
    public var ip_title: String {
        return "HealthKit Clinical Record"
    }
    
    public var ip_identifier: String? {
        return "com.apple.healthkit.clinicalrecords"
    }
    
    public var ip_code: Coding? {
        return nil
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_publisher: String? {
        return nil
    }
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? {
        return nil
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let taskViewController = HKClinicalRecordTaskViewController()
        callback(taskViewController, nil)
        
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let dataResults = result.stepResult(forStepIdentifier: ksm_step_auth)?.results as? [HKClinicalRecordResult] {
            
            var domainResources = [DomainResource]()
            for healthKitRecord in dataResults  {
                do {
                    if let resources = try healthKitRecord.clinicalRecords?.compactMap ({ try $0.fhirResource?.sm_asR4() }) {
                        domainResources.append(contentsOf: resources)
                    }
                }
                catch {
                    print(error)
                }
            }
            
            domainResources.forEach { (d) in
                print(d.sm_resourceType())
                print(try? d.asJSON())
            }
            
            return domainResources.isEmpty ? nil : SMART.Bundle.sm_with(domainResources)
        }
        return nil
    }
}
