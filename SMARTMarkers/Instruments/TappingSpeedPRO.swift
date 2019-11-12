//
//  TappingSpeedPRO.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 4/19/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class TappingSpeed: ActiveInstrumentProtocol {
    
    static let resultStepIdentifiers = [
            "tapping.left",
            "tapping.right"
        ]
    
    let handOption: ORKPredefinedTaskHandOption!
    
    let duration: TimeInterval!

    public init(hand: ORKPredefinedTaskHandOption, duration: TimeInterval = 10) {
        self.handOption = hand
        self.duration = duration
        self.ip_title = "Tapping Speed Task"
    }
    
    public var ip_taskDescription: String?
    
    public var ip_title: String
    
    public var ip_identifier: String? {
        return "tappingspeed"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_ResearchKit(ip_identifier!, "Tapping Speed Task")
    }
    
    public var ip_version: String?
    
    public var ip_publisher: String?
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]?
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.twoFingerTappingIntervalTask(withIdentifier: ip_identifier!, intendedUseDescription: ip_taskDescription, duration: duration, handOptions: handOption, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.twoFingerTappingIntervalTask(withIdentifier: ip_identifier!, intendedUseDescription: ip_taskDescription, duration: duration, handOptions: handOption, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        var documentReferences = [DocumentReference]()
        for id in TappingSpeed.resultStepIdentifiers {
            
            guard let tappingResult = result.stepResult(forStepIdentifier: id)?.firstResult as? ORKTappingIntervalResult else {
                continue
            }
            
            let hand = (id.hasSuffix("right")) ? "Right" : "Left"
            let title = "Tapping Finger \(hand)"
            let code = Coding.sm_ResearchKit(tappingResult.identifier, title)
            let concept = CodeableConcept.sm_From([code], text: title)
            let dateTime = DateTime.now
            
            let ob = Observation()
            ob.code = concept
            ob.status = .final
            
            // Category
            let activity = Coding.sm_Coding("activity", kHL7ObservationCategory, "Activity")
            ob.category = [CodeableConcept.sm_From([activity], text: "Activity")]
            
            if let samples = tappingResult.samples?.map({ $0.sm_asCSVString() }) {
                let csv = ORKTappingSample.csvHeader + "\n" + samples.joined(separator: "\n")
                let document = DocumentReference.sm_Reference(title: title, concept: concept, creationDateTime: dateTime, csvString: csv)
                documentReferences.append(document)
            }

        }
        
        if !documentReferences.isEmpty {
            
            return SMART.Bundle.sm_with(documentReferences)
            
        }
        
        return nil
    }
}

extension ORKTappingSample {
    
    static let csvHeader = "buttonserial,timestamp,duration,location-x,location-y"
    
    func sm_asCSVString() -> String {
        
        return "\(buttonIdentifier.rawValue),\(timestamp),\(duration),\(location.x),\(location.y)"
    }
}
