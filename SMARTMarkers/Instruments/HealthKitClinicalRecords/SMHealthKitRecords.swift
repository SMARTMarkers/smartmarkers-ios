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
    
    public var sm_title: String
    
    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_resultingFhirResourceType: [FHIRSearchParamRelationship]?
    
    public init() {
        sm_title = "HealthKit Clinical Record"
        sm_type = .unknown
        sm_identifier = "com.apple.healthkit.clinicalrecords"
    }
    
    public func sm_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let taskViewController = HKClinicalRecordTaskViewController()
        callback(taskViewController, nil)
        
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let taskViewController = HKClinicalRecordTaskViewController()
        callback(taskViewController, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
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
