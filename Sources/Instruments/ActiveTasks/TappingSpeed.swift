//
//  TappingSpeed.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 4/19/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class TappingSpeed: Instrument {
    
    static let resultStepIdentifiers = [
            "tapping.left",
            "tapping.right"
        ]
    
    let handOption: ORKPredefinedTaskHandOption!
    
    let duration: TimeInterval!
    
    public var sm_title: String
    
    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_reportSearchOptions: [FHIRReportOptions]?
    
    public var usageDescription: String?

    public init(hand: ORKPredefinedTaskHandOption, duration: TimeInterval = 10, usageDescription: String? = nil) {
        self.handOption = hand
        self.duration = duration
        self.usageDescription = usageDescription
        let i: Instruments.ActiveTasks = (hand == .right) ? .FingerTappingSpeed_Right : (hand == .left) ? .FingerTappingSpeed_Left : .FingerTappingSpeed
        self.sm_title = i.description
        self.sm_code = i.coding
        self.sm_identifier = sm_code?.code?.string
        self.sm_reportSearchOptions = [
            FHIRReportOptions(Observation.self, ["code": sm_code!.sm_searchableToken()!]),
            FHIRReportOptions(DocumentReference.self, ["type": sm_code!.sm_searchableToken()!])
        ]
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.twoFingerTappingIntervalTask(withIdentifier: sm_identifier!, intendedUseDescription: usageDescription, duration: duration, handOptions: handOption, options: [])
        let taskViewController = InstrumentTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        var resources = [BundleEntry]()
        let instant = Instant.now

        for id in TappingSpeed.resultStepIdentifiers {
            
            guard let tappingResult = result.stepResult(forStepIdentifier: id)?.firstResult as? ORKTappingIntervalResult else {
                continue
            }
            
            if let samples = tappingResult.samples?.map({ $0.sm_asCSVString() }) {
                
                let hand = (id.hasSuffix("right")) ? "Right" : "Left"
                let title = "Tapping Finger \(hand)"
                let csv = ORKTappingSample.csvHeader + "\n" + samples.joined(separator: "\n")
                let concept = CodeableConcept.sm_From([sm_code!], text: "Finger Tapping Speed")
                let document = DocumentReference.sm_Reference(title: title, concept: concept, instant: instant, csvString: csv)
                let bundleEntry = BundleEntry()
                let uuid = "urn:uuid:\(UUID().uuidString)"
                bundleEntry.resource = document
                bundleEntry.fullUrl = FHIRURL(uuid)
                bundleEntry.request = BundleEntryRequest(method: .POST, url: FHIRURL("DocumentReference")!)
                resources.append(bundleEntry)
            }

        }
        
        if !resources.isEmpty {
            
            let references = resources.map { (entry) -> Reference in
                let reference = Reference()
                reference.reference = "DocumentReference/\(entry.fullUrl!.absoluteString)".fhir_string
                return reference
            }
            
            let ob = Observation()
            ob.code = CodeableConcept.sm_From([sm_code!], text: "Finger Tapping Speed")
            ob.status = .final
            ob.effectiveDateTime = DateTime.now
            let activity = Coding.sm_Coding("activity", kHL7ObservationCategory, "Activity")
            ob.category = [CodeableConcept.sm_From([activity], text: "Activity")]
            ob.derivedFrom = references
            
            //Observtion Entry
            let uuid = "urn:uuid:\(UUID().uuidString)"
            let observationBundleEntry = BundleEntry()
            observationBundleEntry.resource = ob
            observationBundleEntry.fullUrl = FHIRURL(uuid)
            observationBundleEntry.request = BundleEntryRequest(method: .POST, url: FHIRURL("Observation")!)
            resources.append(observationBundleEntry)
            
            let bundle = SMART.Bundle()
            bundle.entry = resources
            bundle.type = BundleType.transaction
            return bundle
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
