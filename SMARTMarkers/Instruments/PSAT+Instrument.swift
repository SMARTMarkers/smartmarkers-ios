//
//  PSAT+Instrument.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/16/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class PSATPRO: Instrument {
    
    public init() {
        
    }
    
    public var ip_title: String {
        return "Paced Auditory Serial Additions Test"
    }
    
    public var ip_identifier: String? {
        return "pasat-pro"
    }
    
    public var ip_code: Coding? {
        return nil
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? {
        return nil
    }
    
    public var ip_publisher: String? {
        return "ResearchKit, Apple Inc"
    }
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        let task = ORKOrderedTask.psatTask(withIdentifier: String(describing:ip_identifier), intendedUseDescription: "Description", presentationMode: ORKPSATPresentationMode.auditory.union(.visual), interStimulusInterval: 3.0, stimulusDuration: 1.0, seriesLength: 60, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        guard let psatResult = result.stepResult(forStepIdentifier: "")?.firstResult as? ORKPSATResult else {
            return nil
        }
        
        
        return nil
    }
    
    
    
}


extension ORKPSATResult {
    
    func sm_asFHIR() -> Observation {
        
        let psat_code = (interStimulusInterval == 2.0) ? "psat-2" : "psat-3"
        
        let isAuditory = stimulusDuration == 0.0
        
        let code = Coding.sm_ResearchKit(psat_code, "9 Peg Hole Test")

        
        let ob = Observation()
        
        ob.status = .final
        

        
        // Category
        let activity = Coding.sm_Coding("activity", kHL7ObservationCategory, "Activity")
        ob.category = [CodeableConcept.sm_From([activity], text: "Activity")]
        
        ob.valueInteger = FHIRInteger(integerLiteral: totalCorrect)
        
        
        
        
        return ob
    }
}

extension ORKPSATSample {
    
    func sm_csvString() -> String {
        
        return ""
        
    }
    
}
