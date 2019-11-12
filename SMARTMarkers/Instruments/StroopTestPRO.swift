//
//  StroopTestPRO.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 4/19/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit

// Reference: https://europepmc.org/articles/PMC3828616

open class StroopTestPRO: ActiveInstrumentProtocol {
    
    var numberOfAttempts: Int!
    
    public init(attempts: Int = 10) {
        numberOfAttempts = attempts
        ip_title = "Stroop Test"
    }

    public var ip_taskDescription: String?
    
    public var ip_title: String
    
    public var ip_identifier: String? {
        return "stroop"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_ResearchKit(ip_identifier!, "Stroop Test")
    }
    
    public var ip_version: String?
    
    public var ip_publisher: String?
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]?
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.stroopTask(withIdentifier: ip_identifier!, intendedUseDescription: ip_taskDescription, numberOfAttempts: numberOfAttempts, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {

        let task = ORKOrderedTask.stroopTask(withIdentifier: ip_identifier!, intendedUseDescription: ip_taskDescription, numberOfAttempts: numberOfAttempts, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let stroopResults = result.stepResult(forStepIdentifier: ip_identifier!)?.results?.map({ $0 as! ORKStroopResult}) {
            let obs = Observation.sm_Stroop(self, result: stroopResults)
            print(try! obs.sm_jsonString())
            return SMART.Bundle.sm_with([obs])
        }
        return nil
    }
}


extension Observation {
    
    class func sm_Stroop(_ instrument: StroopTestPRO, result: [ORKStroopResult]) -> Observation {
        
        let observation = Observation()
        observation.effectiveDateTime = result.last!.endDate.fhir_asDateTime()
        observation.status = .final
        observation.category = [CodeableConcept.sm_ObservationCategorySurvey()]
        observation.code = CodeableConcept.sm_From(instrument)
        observation.component = result.map { $0.sm_ObservationComponent() }
        return observation
    }
    
}

extension ORKStroopResult {
    
    func sm_ObservationComponent() -> ObservationComponent {
        
        //TODO: Record congruence, incongruence factor
        //Need to also record: congruence, incongruence along with time taken
        let testDuration = endTime - startTime
        let component = ObservationComponent()
        let duration = Duration()
        duration.value = FHIRDecimal(Decimal(floatLiteral: testDuration))
        component.code = CodeableConcept.sm_From([Coding.sm_ResearchKit("stroop", "stroop test result")], text: nil)
        duration.code = FHIRString("second")
        duration.system = FHIRURL("http://unitsofmeasure.org")
        component.valueQuantity = duration
        return component
    }
    
}
