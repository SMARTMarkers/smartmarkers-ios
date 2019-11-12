//
//  TowerofHanoiInstrument.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 4/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class TowerOfHanoiPRO: Instrument {
    
    let numberOfDisks: UInt!
    
    public init(_ numberOfDisks: UInt = 0) {
        self.numberOfDisks = numberOfDisks
        self.ip_title = "Tower of Hanoi"
    }
    
    public var ip_title: String
    
    public var ip_identifier: String? {
        return "towerOfHanoi"
    }
    
    public var ip_taskDescription: String?
    
    public var ip_code: Coding? {
        return SMARTMarkers.Instruments.ActiveTasks.towerOfHanoi.coding
    }
    
    public var ip_version: String?
    
    public var ip_publisher: String?
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]?
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.towerOfHanoiTask(withIdentifier: ip_identifier!, intendedUseDescription: ip_taskDescription, numberOfDisks: self.numberOfDisks, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.towerOfHanoiTask(withIdentifier: ip_identifier!, intendedUseDescription: ip_taskDescription, numberOfDisks: self.numberOfDisks, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let tohResult = result.stepResult(forStepIdentifier: ip_identifier!)?.results?.first as? ORKTowerOfHanoiResult {
            let observation = Observation.sm_TowerOfHanoi(self, result: tohResult)
            return SMART.Bundle.sm_with([observation])
        }
        return nil
    }
}


extension Observation {
    
    public class func sm_TowerOfHanoi(_ toh: TowerOfHanoiPRO, result: ORKTowerOfHanoiResult) -> Observation {
        let observation = Observation()
        observation.code = CodeableConcept.sm_From(toh)
        observation.status = .final
        observation.valueBoolean = FHIRBool(result.puzzleWasSolved)
        observation.category = [CodeableConcept.sm_ObservationCategorySurvey()]
        observation.effectiveDateTime = result.endDate.fhir_asDateTime()
        return observation
    }
    
}
