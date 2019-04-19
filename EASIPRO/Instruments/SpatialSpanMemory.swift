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


open class SpatialSpanMemoryPRO: InstrumentProtocol {
    
    public init() { }
    
    public var ip_title: String {
        return "Spatial Span Memory"
    }
    
    public var ip_identifier: String {
        return "org.researchkit.cognitive.memory.spatialspan"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_Coding("cognitive.memory.spatialspan", "http://researchkit.org", "Spatial Span Memory")
    }
    
    public var ip_version: String?
    
    public var ip_resultingFhirResourceType: [PROFhirLinkRelationship]?
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.spatialSpanMemoryTask(withIdentifier: ip_identifier, intendedUseDescription: nil, initialSpan: 3, minimumSpan: 2, maximumSpan: 15, playSpeed: 1.0, maximumTests: 5, maximumConsecutiveFailures: 3, customTargetImage: nil, customTargetPluralName: nil, requireReversal: false, options: [])
        
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let spatialMemoryResult = result.stepResult(forStepIdentifier: "cognitive.memory.spatialspan")?.firstResult as? ORKSpatialSpanMemoryResult {
            
            let score = spatialMemoryResult.score
//            let gameRecord = spatialMemoryResult.gameRecords
//            let gamesCount = spatialMemoryResult.numberOfGames
//            let failCount  = spatialMemoryResult.numberOfFailures
            
            let observation = Observation.sm_SpatialSpanMemory(score: score, date: spatialMemoryResult.endDate, instrument: self)
            return SMART.Bundle.sm_with([observation])
        }

        return nil
    }
    
    
}
