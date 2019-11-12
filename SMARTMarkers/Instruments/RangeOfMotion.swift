//
//  RangeOfMotion.swift
//  EASIPRO
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
    
    required public init(limbOption: ORKPredefinedTaskLimbOption, usageDescription: String? = nil) {
        self.limbOption = limbOption
        self.usageDescription = usageDescription
        self.ip_title = (limbOption == .left) ? "Left Knee Range of Motion" : "Right Knee Range of Motion"
    }
    
    
    public var ip_title: String
    
    public var ip_identifier: String? {
        return "org.researchkit.knee.range.of.motion"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_Coding("knee.range.of.motion", "http://researchkit.org", "Range of Motion Knee")
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_publisher: String?
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? {
        
        return [FHIRSearchParamRelationship(Observation.self, ["code":ip_code!.sm_searchableToken()!])]
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        let task = ORKOrderedTask.kneeRangeOfMotionTask(withIdentifier: ip_title, limbOption: limbOption, intendedUseDescription: usageDescription, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.kneeRangeOfMotionTask(withIdentifier: ip_title, limbOption: limbOption, intendedUseDescription: usageDescription, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
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


open class ShoulderRangeOfMotion: ActiveInstrumentProtocol {
    
    var limbOption: ORKPredefinedTaskLimbOption!
    
    public var ip_taskDescription: String?
    
    required public init(limbOption: ORKPredefinedTaskLimbOption) {
        self.limbOption = limbOption
        self.ip_title = (limbOption == .left) ? "Left Shoulder Range of Motion" : "Right Should Range of Motion"
    }
    
    public var ip_title: String
    
    public var ip_identifier: String? {
        
        if limbOption == ORKPredefinedTaskLimbOption.left {
            return "org.researchkit.shoulder.left.rangeofmotion"
        }
        else {
            return "org.researchkit.shoulder.right.rangeofmotion"
        }
    }
    
    public var ip_code: Coding? {
        
        let code: String
        
        if limbOption == ORKPredefinedTaskLimbOption.left {
            
            code = "shoulder.left.rangeofmotion"
        }
        else {
            code = "shoulder.right.rangeofmotion"
        }
        
        return Coding.sm_Coding(code, "http://researchkit.org", "Range of Motion Shoulder")
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_publisher: String? {
        return "ResearchKit, Apple Inc"
    }
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? {
        
        return [
            FHIRSearchParamRelationship(Observation.self, ["code":ip_code!.code!.string])
        ]
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        let task = ORKOrderedTask.shoulderRangeOfMotionTask(withIdentifier: ip_title, limbOption: limbOption, intendedUseDescription: ip_taskDescription, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.shoulderRangeOfMotionTask(withIdentifier: ip_title, limbOption: limbOption, intendedUseDescription: ip_taskDescription, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
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

