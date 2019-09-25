//
//  File.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 4/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class SpatialSpanMemoryPRO: ActiveInstrumentProtocol {
    

    let initialSpan: Int
    
    let minimumSpan: Int
    
    let maximumSpan: Int
    
    let playSpeed: TimeInterval
    
    let maxTests: Int
    
    let maxConsecutiveFailures: Int
    
    public init(initialSpan: Int = 3, minimumSpan: Int = 3, maximumSpan: Int = 15, playSpeed: TimeInterval = 1.0, maximumTests: Int = 5, maximumConsecutiveFailures: Int = 3) {
        
        self.initialSpan = initialSpan
        self.minimumSpan = minimumSpan
        self.maximumSpan = maximumSpan
        self.playSpeed = playSpeed
        self.maxTests = maximumTests
        self.maxConsecutiveFailures = maximumConsecutiveFailures
    }
    
    public var ip_taskDescription: String?
    
    public var ip_title: String {
        return "Spatial Span Memory"
    }
    
    public var ip_identifier: String? {
        return "cognitive.memory.spatialspan"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_ResearchKit("cognitive.memory.spatialspan", "Spatial Span Memory")
    }
    
    public var ip_version: String?
    
    public var ip_publisher: String?
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? {
        if let token = ip_code?.sm_searchableToken() {
            return [FHIRSearchParamRelationship(Observation.self, ["code": token])]
        }
        return nil
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.spatialSpanMemoryTask(withIdentifier: ip_identifier!, intendedUseDescription: nil, initialSpan: initialSpan, minimumSpan: minimumSpan, maximumSpan: maximumSpan, playSpeed: playSpeed, maximumTests: maximumSpan, maximumConsecutiveFailures: 3, customTargetImage: nil, customTargetPluralName: nil, requireReversal: false, options: [])
        
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
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
