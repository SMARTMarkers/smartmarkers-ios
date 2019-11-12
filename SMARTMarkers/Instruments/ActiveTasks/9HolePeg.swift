//
//  9HolePeg+InstrumentProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/15/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class NineHolePegTest: Instrument {

    static let stepIdentifiers      = [
        ORKHolePegTestDominantPlaceStepIdentifier,
        ORKHolePegTestDominantRemoveStepIdentifier,
        ORKHolePegTestNonDominantPlaceStepIdentifier,
        ORKHolePegTestNonDominantRemoveStepIdentifier
    ]
    
    public var sm_title: String

    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_resultingFhirResourceType: [FHIRSearchParamRelationship]?

    public init() {
        sm_title = "9 Hole Peg Test"
        sm_identifier = "9-hole-peg-test"
        sm_code = SMARTMarkers.Instruments.ActiveTasks.nineHolePegTest.coding
        sm_type = .ActiveTask
        sm_resultingFhirResourceType = [
            FHIRSearchParamRelationship(Observation.self, ["code": sm_code!.sm_searchableToken()!])
        ]
    }

    
    public func sm_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let tsk = ORKNavigableOrderedTask.holePegTest(withIdentifier: sm_identifier!, intendedUseDescription: nil, dominantHand: .left, numberOfPegs: 1, threshold: 0.2, rotated: false, timeLimit: 300, options: [])
        let tvc = ORKTaskViewController(task: tsk, taskRun: UUID())
        callback(tvc, nil)
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let tsk = ORKNavigableOrderedTask.holePegTest(withIdentifier: sm_identifier!, intendedUseDescription: nil, dominantHand: .left, numberOfPegs: 1, threshold: 0.2, rotated: false, timeLimit: 300, options: [])
        let tvc = ORKTaskViewController(task: tsk, taskRun: UUID())
        callback(tvc, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        let datetime = DateTime.now
        
        var totalTime: TimeInterval = 0.0
        var totalSuccesses = 0
        var totalFailures  = 0
        var totalDistance  = 0.0
        var csvString      = ""
        
        for stpId in NineHolePegTest.stepIdentifiers {
            
            let nonDominant    = stpId.hasPrefix("hole.peg.test.non.dominant") ? "NonDominant" : "Dominant"
            let move           = stpId.hasSuffix("place") ? "place" : "remove"
            if let htpResult   = result.stepResult(forStepIdentifier: stpId)?.firstResult as? ORKHolePegTestResult {
                totalDistance  += htpResult.totalDistance
                totalSuccesses += htpResult.totalSuccesses
                totalFailures  += htpResult.totalFailures
                totalTime      += htpResult.totalTime
                csvString      += "\n" + (htpResult.samples?.map ({ ($0 as! ORKHolePegTestSample).sm_asCSVString(hand: nonDominant, move: move) }).joined(separator: "\n") ?? "")
            }
        }
        
        if totalTime == 0.0 {
            return nil
        }
        
        
        print(totalTime)
        print(totalFailures)
        print(totalSuccesses)
        print(totalDistance)
        print(csvString)
        
        let observation = Observation.sm_pegHoleTest(totalTime: totalTime, totalDistance: totalDistance, success: totalSuccesses, failures: totalFailures, effective: datetime)
        let code = sm_code!
        let concept = CodeableConcept.sm_From([code], text: nil)

        let documentEntry = DocumentReference.sm_Reference(title: "Hole Peg Test Samples", concept: concept, creationDateTime: datetime, csvString: csvString).sm_asBundleEntry()
        observation.derivedFrom = [documentEntry.sm_asReference()]
        
        let bundle = SMART.Bundle()
        bundle.entry = [observation.sm_asBundleEntry(), documentEntry]
        bundle.type = BundleType.transaction
        return bundle
    }
    
  
    
    
    
    
}

extension Observation {
    
    class func sm_pegHoleTest(totalTime: Double, totalDistance: Double, success: Int, failures: Int, effective: DateTime) -> Observation {
        
        let code = Coding.sm_ResearchKit("hole.peg.test", "9 Peg Hole Test")
        let ob = Observation()
        ob.code = CodeableConcept.sm_From([code], text: nil)
        ob.status = .final
        ob.effectiveDateTime = effective
        
        // Category
        let activity = Coding.sm_Coding("activity", kHL7ObservationCategory, "Activity")
        ob.category = [CodeableConcept.sm_From([activity], text: "Activity")]
        
        
        //Total Success
        let successComponent = ObservationComponent()
        let scoding = Coding.sm_Coding("\(code.code!).success", "http://researchkit.org", "Total successful moves")
        successComponent.code = CodeableConcept.sm_From([scoding], text: nil)
        successComponent.valueInteger = FHIRInteger(integerLiteral: success)

        
        //Total Failures
        let failuresComponent = ObservationComponent()
        let fcoding = Coding.sm_Coding("\(code.code!).failure", "http://researchkit.org", "Total failed moves")
        failuresComponent.code = CodeableConcept.sm_From([fcoding], text: nil)
        failuresComponent.valueInteger = FHIRInteger(integerLiteral: failures)
        
        //Total Distance
        let distanceComponent = ObservationComponent()
        let dcoding = Coding.sm_Coding("\(code.code!).distance", "http://researchkit.org", "Total distance")
        distanceComponent.code = CodeableConcept.sm_From([dcoding], text: nil)
        distanceComponent.valueString = FHIRString(String(totalDistance))
        
        ob.component = [successComponent, failuresComponent, distanceComponent]
        
        //Total Time Taken
        let totalSecondsQuant       = Quantity()
        totalSecondsQuant.value     = FHIRDecimal(totalTime.description)
        totalSecondsQuant.system    = FHIRURL("http://unitsofmeasure.org")
        totalSecondsQuant.unit      = FHIRString("second")
        totalSecondsQuant.code      = FHIRString("second")
        ob.valueQuantity = totalSecondsQuant
        
        
        return ob
    }
    
}

extension ORKHolePegTestSample {
    
    func sm_asCSVString(hand: String, move: String) -> String {
        return "\(hand),\(move),\(time),\(distance)"
    }
}

extension Attachment {
    
    class func sm_withCSV(title: String, csvString: String, creationDateTime: DateTime) -> Attachment {
        
        let attachment = Attachment()
        attachment.contentType  = FHIRString("text/csv")
        attachment.creation     = creationDateTime
        attachment.title        = FHIRString(title)
        attachment.data         = Base64Binary(value: csvString.sm_base64encoded())
        return attachment
    }
}


extension DocumentReference {
    
    class func sm_Reference(title: String, concept: CodeableConcept, creationDateTime: DateTime, csvString: String) -> DocumentReference {
        let documentReference = DocumentReference()
        let attachment = Attachment.sm_withCSV(title: title, csvString: csvString, creationDateTime: creationDateTime)
        documentReference.content = [DocumentReferenceContent(attachment: attachment)]
        documentReference.status = .current
        documentReference.docStatus = .final
        documentReference.description_fhir = title.fhir_string
        documentReference.type = concept
        return documentReference
    }
}
