//
//  RangeOfMotion.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 4/12/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class KneeRangeOfMotion: Instrument {
    
    var limbOption: ORKPredefinedTaskLimbOption!
    
    var usageDescription: String?
    
    public var sm_title: String
    
    public var sm_identifier: String?

    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?

    public var sm_resultingFhirResourceType: [FHIRSearchParamRelationship]?
    
    required public init(limbOption: ORKPredefinedTaskLimbOption, usageDescription: String? = nil) {
        
        self.sm_type = .ActiveTask
        self.limbOption = limbOption
        self.usageDescription = usageDescription
        self.sm_identifier = "org.researchkit.knee.range.of.motion"
        let i: Instruments.ActiveTasks = (limbOption == .right) ? .RangeOfMotion_knee_right : .RangeOfMotion_knee_left
        self.sm_title = i.description
        self.sm_code = i.coding
        sm_resultingFhirResourceType = [FHIRSearchParamRelationship(Observation.self, ["code":sm_code!.sm_searchableToken()!])]
    }
    
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.kneeRangeOfMotionTask(withIdentifier: sm_title, limbOption: limbOption, intendedUseDescription: usageDescription, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let motionResult = result.stepResult(forStepIdentifier: "knee.range.of.motion")?.firstResult as? ORKRangeOfMotionResult {
            
            if motionResult.flexed == 0.0 && motionResult.extended == 0.0 {
                return nil
            }
            
            let observation = Observation.sm_RangeOfMotion(flexed: motionResult.flexed, extended: motionResult.extended, date: motionResult.endDate)
            
            if limbOption == .both {
                
                observation.bodySite = CodeableConcept.sm_BodySiteShoulderBoth()
                observation.code = CodeableConcept.sm_ShoulderBothRangeOfMotion()
            }
                
            else if limbOption == .left {
                observation.bodySite = CodeableConcept.sm_BodySiteShoulderLeft()
                observation.code = CodeableConcept.sm_ShoulderLeftRangeOfMotion()
            }
            else if limbOption == .right {
                observation.bodySite = CodeableConcept.sm_BodySiteShoulderRight()
                observation.code = CodeableConcept.sm_ShoulderRightRangeOfMotion()
            }
            
            return SMART.Bundle.sm_with([observation])
        }
        
        
        return nil
    }
}


open class ShoulderRangeOfMotion: Instrument {
    
    var limbOption: ORKPredefinedTaskLimbOption!
    
    var usageDescription: String?
    
    public var sm_title: String
    
    public var sm_identifier: String?
    
    public var sm_code: Coding?
    
    public var sm_version: String?
    
    public var sm_publisher: String?
    
    public var sm_type: InstrumentCategoryType?
    
    public var sm_resultingFhirResourceType: [FHIRSearchParamRelationship]?
    
    required public init(limbOption: ORKPredefinedTaskLimbOption, usageDescription: String? = nil) {
        self.limbOption = limbOption
        self.usageDescription = usageDescription
        self.sm_identifier = (limbOption == .right) ? "org.researchkit.shoulder.left.rangeofmotion" : "org.researchkit.shoulder.right.rangeofmotion"
        self.sm_type = .ActiveTask
        let i: Instruments.ActiveTasks = (limbOption == .right) ? .RangeOfMotion_shoulder_right : .RangeOfMotion_shoulder_left
        self.sm_title = i.description
        self.sm_code = i.coding
        sm_resultingFhirResourceType = [FHIRSearchParamRelationship(Observation.self, ["code":sm_code!.sm_searchableToken()!])]
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.shoulderRangeOfMotionTask(withIdentifier: sm_title, limbOption: limbOption, intendedUseDescription: usageDescription, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
         if let motionResult = result.stepResult(forStepIdentifier: "shoulder.range.of.motion")?.firstResult as? ORKRangeOfMotionResult {
            
            if motionResult.flexed == 0.0 && motionResult.extended == 0.0 {
                return nil
            }

            let observation = Observation.sm_RangeOfMotion(flexed: motionResult.flexed, extended: motionResult.extended, date: motionResult.endDate)
            
            if limbOption == .both {
                
                observation.bodySite = CodeableConcept.sm_BodySiteShoulderBoth()
                observation.code = CodeableConcept.sm_ShoulderBothRangeOfMotion()
            }
                
            else if limbOption == .left {
                observation.bodySite = CodeableConcept.sm_BodySiteShoulderLeft()
                observation.code = CodeableConcept.sm_ShoulderLeftRangeOfMotion()
            }
            else if limbOption == .right {
                observation.bodySite = CodeableConcept  .sm_BodySiteShoulderRight()
                observation.code = CodeableConcept.sm_ShoulderRightRangeOfMotion()
            }
            
            return SMART.Bundle.sm_with([observation])
            
        }
        
        
        return nil
        
    }
}

