//
//  InstrumentResult.swift
//  SMARTMarkers
//
//  Created by raheel on 4/4/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

/**
 SubmissionBundle holds newly created reports for submission to the FHIR
 
 One `InstrumentResult` created for each PGHD task session
 */
public class InstrumentResult {
    
    
    public enum ResultStatus: String, CustomStringConvertible {
        
        public var description: String {
            get {
                switch self {
                case .readyToSubmit:
                    return "Ready"
                case .submitted:
                    return "Submitted"
                case .failedToSubmit:
                    return "Failed to Submit"
                case .discarded:
                    return "Discarded"
                }
            }
        }
        
        case readyToSubmit
        case submitted
        case failedToSubmit
        case discarded
    }
    
    /// User session task identifier
    public final let taskId: String
    
    /// `SMART.Bundle` generated from the task session
    public final var bundle: SMART.Bundle?
    
    /// Associated request identifier; (if any)
    public final let requestId: String?
    
    /// Boolean to indicate if "ok" to submit
    public var canSubmit: Bool = false
    
    /// Metrics (start time, end time and conclusion
    public var metric: TaskAttempt
    
    /// Submission status
    public var status: ResultStatus {
        for resource in resources() ?? [] {
            if resource.id == nil {
                return .readyToSubmit
            }
        }
        return .submitted
    }
    
    /**
     Designated Initializer
     
     - parameter taskId: User task session identifier
     - parameter bundle: `SMART.Bundle` generated from the task session
     - parameter requestId: Optional request identifier
     */
    public init(taskId: String, bundle: SMART.Bundle?, metric: TaskAttempt, requestId: String? = nil) {
        self.taskId = taskId
        self.bundle = bundle
        self.requestId = requestId
        self.metric = metric
       
        
    }
    
    /**
     Convinience methods
     */
    
    public func reports() -> [Report]? {
        bundle?.entry?.compactMap({ $0.resource as? Report })
    }
    
    public func resources() -> [DomainResource]? {
        bundle?.entry?.compactMap({ $0.resource as? DomainResource })
    }
    
    convenience public init?(serialized: [String: Any]) throws  {
        
        guard
            let taskId = serialized["taskId"] as? String,
            let metricsJson = serialized["metric"] as? [String: Any] else {
            throw SMError.undefined(description: "InstrumentResult cannot be initialized; invalid format")
        }
        
        let metr = try TaskAttempt(serialized: metricsJson)
        var context = FHIRInstantiationContext(strict: false)
        var bundl: SMART.Bundle?
        if let gD = serialized["generatedData"] as? [[String: Any]] {
            
            let generatedData = gD.compactMap({ (json) -> DomainResource? in
               FHIRAbstractResource.instantiate(from: json, owner: nil, context: &context) as? DomainResource
            })
            
            if !generatedData.isEmpty {
                bundl = SMART.Bundle.sm_with(generatedData)
            }
        }
       
        
        self.init(
            taskId: taskId,
            bundle: bundl,
            metric: metr,
            requestId: nil)
    }
    
    public func serialize(errors: inout [Error]?)  -> [String: Any]? {
        
        var json: [String: Any] = [
            "taskId": self.taskId
        ]
        var errors = [FHIRValidationError]()
        
        if let resources = self.resources()?
            .compactMap ({ $0.asJSON(errors: &errors) }) {
            json["generatedData"] = resources
        }
        
        json["metric"] = metric.serialize()
        
        return json
    }

}
