//
//  StudyTaskResult.swift
//  SMARTMarkers
//
//  Created by raheel on 5/6/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public class StudyTaskResult {
    
    let id: String
    let result: [InstrumentResult]
    
    init(sessionId: String, result: [InstrumentResult]) {
        self.id = sessionId
        self.result = result.sorted(by: { $0.metric.startTime < $1.metric.startTime })
        let resources = result.compactMap({ $0.resources() }).flatMap { $0 }
    }
    
    public var hasData: Bool {
        fhir != nil
    }
    
    public var discarded: Bool {
        for res in result {
            if res.metric.state == .discarded {
                return true
            }
        }
       return false
    }
    public lazy var taskMetrics: [TaskAttempt] = {
        result.compactMap({ $0.metric })
    }()
    
    public lazy var taskMetricsFHIR: [Observation] = {
        taskMetrics.map { $0.inFHIR(participant: nil) }
    
    }()
    
    public var fhir: [DomainResource]? {
        let resources = result.compactMap({ $0.resources() }).flatMap { $0 }
        return resources.isEmpty ? nil : resources
    }
    
    public var dated: Date  {
        result.last!.metric.startTime
    }
    
    public init(json: [String: Any]) throws {
        guard let sessionId = json["sessionId"] as? String,
              let results = json["sessionResult"] as? [[String: Any]] else {
            throw SMError.undefined(description: "Invalid StudyTaskResult json format")
        }
        
        let instrumentResults = try results.compactMap({ try InstrumentResult.init(serialized: $0) })
        self.result = instrumentResults
        self.id = sessionId
    }
    
    public func serialize(errors: inout [Error]?)  -> [String: Any]? {
        let instrumentResults = result.compactMap({ $0.serialize(errors: &errors) })
        return ["sessionId": id, "sessionResult": instrumentResults]
    }
    
}
