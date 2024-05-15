//
//  PSAT+Instrument.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 3/16/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class PASAT: Instrument {
    
    let interStimulusInterval: TimeInterval
    
    public var sm_title: String

    public var sm_identifier: String?
    
    public var sm_version: String?
    
    public var sm_code: Coding?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_reportSearchOptions: [FHIRReportOptions]?

    public init(interStimulusInterval: TimeInterval) {
        self.interStimulusInterval = interStimulusInterval
        sm_title = "Paced Auditory Serial Additions Test"
        sm_identifier = "pasat"
        sm_code = Instruments.ActiveTasks.PSAT_2.coding
        sm_type = .ActiveTask
        sm_publisher = "ResearchKit.org"
        sm_reportSearchOptions = [
            FHIRReportOptions(Observation.self, ["code": "http://researchkit.org|psat-2,http://researchkit.org|psat-3"])
            ]
        
    }
    public func sm_configure(_ settings: Any?) {
        
    }
	
	public func sm_taskController(config: InstrumentPresenterOptions?, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {

        let task = ORKOrderedTask.psatTask(withIdentifier: String(describing:sm_identifier), intendedUseDescription: "Description", presentationMode: ORKPSATPresentationMode.auditory.union(.visual), interStimulusInterval: self.interStimulusInterval, stimulusDuration: 1.0, seriesLength: 10, options: [])
        let taskViewController = InstrumentTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        guard let psatResult = result.stepResult(forStepIdentifier: "psat")?.firstResult as? ORKPSATResult else {
            return nil
        }
        let psat_code = (psatResult.interStimulusInterval == 2.0) ? "psat-2" : "psat-3"
        let isAuditory = psatResult.stimulusDuration == 0.0 ? "PSAT Auditory" : "PSAT Visual"
        let code = Coding.sm_ResearchKit(psat_code, isAuditory)
        let concept = CodeableConcept.sm_From([code], text: isAuditory)

        var csv = ORKPSATSample.csvHeader + "\n"
        var totalTime = 0.0
        for sample in psatResult.samples ?? [] {
            csv += sample.sm_csvString() + "\n"
            totalTime += sample.time
        }
        
        let observation = psatResult.sm_asFHIR(title: self.sm_title, totalTime: totalTime)
        let instant = Instant.now
        let documentEntry = DocumentReference.sm_Reference(title: "PSAT Test Samples", concept: concept, instant: instant, csvString: csv).sm_asBundleEntry()
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
