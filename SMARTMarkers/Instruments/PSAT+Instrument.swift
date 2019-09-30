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
        let task = ORKOrderedTask.psatTask(withIdentifier: String(describing:ip_identifier), intendedUseDescription: "Description", presentationMode: ORKPSATPresentationMode.auditory.union(.visual), interStimulusInterval: 3.0, stimulusDuration: 1.0, seriesLength: 10, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        guard let psatResult = result.stepResult(forStepIdentifier: "psat")?.firstResult as? ORKPSATResult else {
            return nil
        }
        let psat_code = (psatResult.interStimulusInterval == 2.0) ? "psat-2" : "psat-3"
        let isAuditory = psatResult.stimulusDuration == 0.0 ? "PSAT Auditory" : "PSAT Visual"
        let code = Coding.sm_ResearchKit(psat_code, isAuditory)
        let concept = CodeableConcept.sm_From([code], text: isAuditory)

        
        let dateTime = DateTime.now
        
        var csv = ORKPSATSample.csvHeader + "\n"
        var totalTime = 0.0
        for sample in psatResult.samples ?? [] {
            csv += sample.sm_csvString() + "\n"
            totalTime += sample.time
        }
        
        let observation = psatResult.sm_asFHIR(title: self.ip_title, totalTime: totalTime)
        
        let documentEntry = DocumentReference.sm_Reference(title: "PSAT Test Samples", concept: concept, creationDateTime: dateTime, csvString: csv).sm_asBundleEntry()
        observation.derivedFrom = [documentEntry.sm_asReference()]
        
        let bundle = SMART.Bundle()
        bundle.entry = [observation.sm_asBundleEntry(), documentEntry]
        bundle.type = BundleType.transaction

        return bundle
    }
    
    
    
}




extension ORKPSATResult {
    
    func sm_asFHIR(title: String, totalTime: TimeInterval) -> Observation {
        
        let psat_code = (interStimulusInterval == 2.0) ? "psat-2" : "psat-3"
        let isAuditory = stimulusDuration == 0.0
        
        let code = Coding.sm_ResearchKit(psat_code, title)

        let ob = Observation()
        ob.code = CodeableConcept.sm_From([code], text: title)
        
        ob.status = .final
        
        // Category
        let activity = Coding.sm_Coding("activity", kHL7ObservationCategory, "Activity")
        ob.category = [CodeableConcept.sm_From([activity], text: "Activity")]
        
        
        // Total Correct
        let numerator = Quantity()
        numerator.value = FHIRDecimal(integerLiteral: totalCorrect)
        let denominator = Quantity()
        denominator.value = FHIRDecimal(integerLiteral: length)
        let ratio = Ratio()
        ratio.numerator = numerator
        ratio.denominator = denominator
        ob.valueRatio = ratio
        
        return ob
    }
}

extension ORKPSATSample {
    
    static let csvHeader = "correct,answer,digit,time"
    
    func sm_csvString() -> String {
        
        return "\(isCorrect ? 1 : 0),\(answer),\(digit),\(time.description)"
        
    }
    
}
