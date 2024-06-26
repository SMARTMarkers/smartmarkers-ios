//
//  StroopTest.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 4/19/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit

// Reference: https://europepmc.org/articles/PMC3828616

open class StroopTest: Instrument {
    
    var numberOfAttempts: Int!
    
    public var sm_title: String
    
    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_reportSearchOptions: [FHIRReportOptions]?
    
    public var usageDescription: String?
    
    public init(attempts: Int = 10, usageDescription: String? = nil) {
        
        self.numberOfAttempts = attempts
        self.usageDescription = usageDescription
        self.sm_title = "Stroop Test"
        self.sm_identifier = "stroop"
        self.sm_code = Instruments.ActiveTasks.StroopTest.coding
        self.sm_reportSearchOptions = [FHIRReportOptions(Observation.self, ["code": sm_code!.sm_searchableToken()!])]
        
    }
    public func sm_configure(_ settings: Any?) {
        
    }
    
	public func sm_taskController(config: InstrumentPresenterOptions?, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {

        let task = ORKOrderedTask.stroopTask(withIdentifier: sm_identifier!, intendedUseDescription: usageDescription, numberOfAttempts: numberOfAttempts, options: [])
        let taskViewController = InstrumentTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let stroopResults = result.stepResult(forStepIdentifier: sm_identifier!)?.results?.map({ $0 as! ORKStroopResult}) {
            let obs = Observation.sm_Stroop(self, result: stroopResults)
            return SMART.Bundle.sm_with([obs])
        }
        return nil
    }
}


extension Observation {
    
    class func sm_Stroop(_ instrument: StroopTest, result: [ORKStroopResult]) -> Observation {
        
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
