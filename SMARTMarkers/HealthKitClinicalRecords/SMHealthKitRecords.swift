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
        
        guard let choice = result.stepResult(forStepIdentifier: ksm_step_review)?.results?.first as? ORKChoiceQuestionResult,
        let dataResults = result.stepResult(forStepIdentifier: ksm_step_auth)?.results as? [HKClinicalRecordResult] else {
            return nil
        }
        
        
        let clinicalTypes = (choice.choiceAnswers as! [String]).map { HKObjectType.clinicalType(forIdentifier: HKClinicalTypeIdentifier(rawValue: $0))! }
        
        var fhirResources = [DomainResource]()
        var errors = [Error]()
        
        for type in clinicalTypes {
            if let healthKitRecord = dataResults.filter ({ $0.identifier == type.identifier }).first {
                do {
                    if let resources = try healthKitRecord.clinicalRecords?.compactMap({ try $0.fhirResource?.sm_asR4() }) {
                        fhirResources.append(contentsOf: resources)
                    }
                } catch {
                    errors.append(error)
                }
            }
        }
        
        return fhirResources.isEmpty ? nil : SMART.Bundle.sm_with(fhirResources)

    }
}
