//
//  TowerofHanoiInstrument.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 4/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class TowerOfHanoi: Instrument {
    
    let numberOfDisks: UInt!
    
    public var sm_title: String
    
    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_reportSearchOptions: [FHIRReportOptions]?
    
    public var usageDescription: String?
    
    public init(_ numberOfDisks: UInt = 3, usageDescription: String? = nil) {
        
        self.numberOfDisks = numberOfDisks
        self.sm_title = "Tower of Hanoi"
        self.sm_identifier = "towerOfHanoi"
        self.usageDescription = usageDescription
        self.sm_type = .ActiveTask
        self.sm_code = Instruments.ActiveTasks.TowerOfHanoi.coding
        self.sm_reportSearchOptions = [FHIRReportOptions(Observation.self, ["code": sm_code!.sm_searchableToken()!])]
    }
	
	
	public func sm_taskController(config: InstrumentPresenterOptions?, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {

        let task = ORKOrderedTask.towerOfHanoiTask(withIdentifier: sm_identifier!, intendedUseDescription: usageDescription, numberOfDisks: self.numberOfDisks, options: [])
        let taskViewController = InstrumentTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let tohResult = result.stepResult(forStepIdentifier: sm_identifier!)?.results?.first as? ORKTowerOfHanoiResult {
            let observation = Observation.sm_TowerOfHanoi(self, result: tohResult)
            return SMART.Bundle.sm_with([observation])
        }
        return nil
    }
}


extension Observation {
    
    public class func sm_TowerOfHanoi(_ toh: TowerOfHanoi, result: ORKTowerOfHanoiResult) -> Observation {
        let observation = Observation()
        observation.code = CodeableConcept.sm_From(toh)
        observation.status = .final
        observation.valueBoolean = FHIRBool(result.puzzleWasSolved)
        observation.category = [CodeableConcept.sm_ObservationCategorySurvey()]
        observation.effectiveDateTime = result.endDate.fhir_asDateTime()
        return observation
    }
    
}
