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


open class KneeRangeOfMotion: InstrumentProtocol {
    
    var limbOption: ORKPredefinedTaskLimbOption!
    
    var usageDescription: String?
    
    required public init(limbOption: ORKPredefinedTaskLimbOption, usageDescription: String? = nil) {
        self.limbOption = limbOption
        self.usageDescription = usageDescription
    }
    
    
    public var ip_title: String {
        return "Knee Range of Motion"
    }
    
    public var ip_identifier: String {
        return "org.researchkit.knee.range.of.motion"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_Coding("knee.range.of.motion", "http://researchkit.org", "Range of Motion Knee")
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_resultingFhirResourceType: [PROFhirLinkRelationship]? {
        return nil
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        let task = ORKOrderedTask.kneeRangeOfMotionTask(withIdentifier: ip_title, limbOption: limbOption, intendedUseDescription: usageDescription, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let motionResult = result.stepResult(forStepIdentifier: "knee.range.of.motion")?.firstResult as? ORKRangeOfMotionResult {
            
            print(motionResult.startDate)
            print(motionResult.endDate)
            print(motionResult.start)
            print(motionResult.finish)
            print(motionResult.maximum)
            print(motionResult.range)
        
            let observation = Observation.sm_RangeOfMotion(start: motionResult.start, finish: motionResult.finish, range: motionResult.range, date: motionResult.endDate)
            
            if limbOption == ORKPredefinedTaskLimbOption.left {
                observation.code = CodeableConcept.sm_KneeLeftRangeOfMotion()
                observation.bodySite = CodeableConcept.sm_BodySiteKneeLeft()
            }
            else if limbOption == ORKPredefinedTaskLimbOption.right {
                observation.code = CodeableConcept.sm_KneeRightRangeOfMotion()
                observation.bodySite = CodeableConcept.sm_BodySiteKneeRight()
            }
            else if limbOption == ORKPredefinedTaskLimbOption.both {
                observation.bodySite = CodeableConcept.sm_BodySiteKneeBoth()
                observation.code = CodeableConcept.sm_KneeBothRangeOfMotion()
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
    }
    
    
    public var ip_title: String {
        return "Shoulder Range of Motion"
    }
    
    public var ip_identifier: String {
        return "org.researchkit.shoulder.range.of.motion"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_Coding("shoulder.range.of.motion", "http://researchkit.org", "Range of Motion Shoulder")
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_resultingFhirResourceType: [PROFhirLinkRelationship]? {
        return nil
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        let task = ORKOrderedTask.shoulderRangeOfMotionTask(withIdentifier: ip_title, limbOption: limbOption, intendedUseDescription: ip_taskDescription, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        
        if let motionResult = result.stepResult(forStepIdentifier: "shoulder.range.of.motion")?.firstResult as? ORKRangeOfMotionResult {
            
            let observation = Observation.sm_RangeOfMotion(start: motionResult.start, finish: motionResult.finish, range: motionResult.range, date: motionResult.endDate)
            
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

