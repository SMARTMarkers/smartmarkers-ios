//
//  StepCountInstrument.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 10/10/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class StepReport: Instrument {
    
    public init() {
        sm_type = .Device
        sm_title = "Step Count (HealthKit)"
        sm_code = Coding.sm_LOINC("41950-7", "Number of steps in 24 hour Measured")
        sm_resultingFhirResourceType = [FHIRSearchParamRelationship(Observation.self, ["code": sm_code!.sm_searchableToken()!])]
    }
    
    public var sm_title: String
    
    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_resultingFhirResourceType: [FHIRSearchParamRelationship]?
    
    public func sm_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let sa = StepActivity(Date(), nil)
        sa.store = HKHealthStore()
        let activityTaskView = ActivityTaskViewController(activity: sa)
        callback(activityTaskView, nil)
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let sa = StepActivity(Date(), nil)
        sa.store = HKHealthStore()
        let activityTaskView = ActivityTaskViewController(activity: sa)
        callback(activityTaskView, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let stepCountResult = result.stepResult(forStepIdentifier: "kSM.activity.fetch.StepCount")?.firstResult as? SMQuantitySampleResult {
            
            if let samples = stepCountResult.samples {
                let observation = Observation.sm_StepCount(count: 0, start: result.startDate, end: result.endDate, samples: samples)
                return SMART.Bundle.sm_with([observation])
            }
        }
        
        return nil
    }
    
    
    
}


extension Observation {
    
    class func sm_StepCount(count: Int, start: Date, end: Date, samples: [HKQuantitySample]) -> Observation {
        
        let observation = Observation()
        let stepCountCode = Coding.sm_LOINC("41950-7", "Number of steps in 24 hour Measured")
        observation.code = CodeableConcept.sm_From([stepCountCode], text: "Number of steps in 24 hour Measured")
        observation.category = [CodeableConcept.sm_Activity()]
        observation.status = .final
        
        let period = Period()
        period.start = start.fhir_asDateTime()
        period.end   = start.fhir_asDateTime()
        observation.effectivePeriod = period
        
        observation.component = samples.map { $0.sm_ObservationComponent() }
        return observation
    }
    
}

extension HKQuantitySample {
    
    func sm_stepCountFHIRQuantity() -> Quantity {
        
        let unit = HKUnit.count()
        let fhir_quantity = Quantity()
        fhir_quantity.value = FHIRDecimal("\(self.quantity.doubleValue(for: unit))")
        fhir_quantity.unit  = FHIRString(unit.unitString)
        return fhir_quantity
    }
    
    func sm_ObservationComponent() -> ObservationComponent {
        
        let component = ObservationComponent()
        component.valueQuantity = sm_stepCountFHIRQuantity()
        
        let stepCountCode = Coding.sm_LOINC("41950-7", "Number of steps in 24 hour Measured")
        component.code = CodeableConcept.sm_From([stepCountCode], text: "Number of steps in 24 hour Measured")
        
        let period = Period()
        period.start = startDate.fhir_asDateTime()
        period.end   = endDate.fhir_asDateTime()
        component.valuePeriod = period
        
        return component
    }
}


extension HKQuantitySample {
    
    func sm_process() {
        
        print(self.sampleType)
        print(self.endDate)
        print(self.endDate)
        print(self.count)
        print(self.quantity.doubleValue(for: HKUnit.count()))
        print(self.quantityType)
        print(self.uuid.uuidString)
        print(self.sourceRevision)
        print(self.device)
        print(self.metadata)
        print("----")
        
    }
    
}
