//
//  SpatialSpanMemory.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 4/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class SpatialSpanMemory: Instrument {
    
    let initialSpan: Int
    
    let minimumSpan: Int
    
    let maximumSpan: Int
    
    let playSpeed: TimeInterval
    
    let maxTests: Int
    
    let maxConsecutiveFailures: Int
    
    public var sm_title: String
    
    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_reportSearchOptions: [FHIRReportOptions]?
    
    public init(initialSpan: Int = 3, minimumSpan: Int = 3, maximumSpan: Int = 15, playSpeed: TimeInterval = 1.0, maximumTests: Int = 5, maximumConsecutiveFailures: Int = 3) {
        self.initialSpan = initialSpan
        self.minimumSpan = minimumSpan
        self.maximumSpan = maximumSpan
        self.playSpeed = playSpeed
        self.maxTests = maximumTests
        self.maxConsecutiveFailures = maximumConsecutiveFailures
        self.sm_title = "Spatial Span Memory"
        self.sm_identifier = "cognitive.memory.spatialspan"
        self.sm_code = Instruments.ActiveTasks.SpatialSpanMemory.coding
        self.sm_reportSearchOptions = [FHIRReportOptions(Observation.self, ["code": sm_code!.sm_searchableToken()!])]
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.spatialSpanMemoryTask(withIdentifier: sm_identifier!, intendedUseDescription: nil, initialSpan: initialSpan, minimumSpan: minimumSpan, maximumSpan: maximumSpan, playSpeed: playSpeed, maximumTests: maximumSpan, maximumConsecutiveFailures: 3, customTargetImage: nil, customTargetPluralName: nil, requireReversal: false, options: [])
        
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        
        callback(taskViewController, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let spatialMemoryResult = result.stepResult(forStepIdentifier: "cognitive.memory.spatialspan")?.firstResult as? ORKSpatialSpanMemoryResult {
            
            let score       = spatialMemoryResult.score
            let gameRecords = spatialMemoryResult.gameRecords
            let gamesCount = spatialMemoryResult.numberOfGames
            let failCount  = spatialMemoryResult.numberOfFailures
            
            let observation = Observation.sm_SpatialSpanMemory(score: score, date: spatialMemoryResult.endDate, instrument: self)
            return SMART.Bundle.sm_with([observation])
        }

        return nil
    }
    
    
}


extension ORKSpatialSpanMemoryResult {
    
    
}

extension ORKSpatialSpanMemoryGameRecord {
    
}


extension ORKSpatialSpanMemoryGameTouchSample {
    
}



extension Observation {
    
    class func sm_SpatialSpanMemory(score: Int, date: Date, instrument: Instrument?) -> Observation {
        
        let observation = Observation()
        if let instr = instrument {
            observation.code = CodeableConcept.sm_From(instr)
        }
        observation.status = .final
        observation.effectiveDateTime = date.fhir_asDateTime()
        observation.valueString = FHIRString(String(score))
        
        return observation
    }
    
}
