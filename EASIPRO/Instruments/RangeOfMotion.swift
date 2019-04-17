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
            
            let bID = "urn:uuid:\(UUID().uuidString)"
            let entry = BundleEntry()
            entry.fullUrl = FHIRURL(bID)
            entry.resource = observation
            entry.request = BundleEntryRequest(method: .POST, url: FHIRURL("Observation")!)
            let bundle = SMART.Bundle()
            bundle.entry = [entry]
            bundle.type = BundleType.transaction
            return bundle
        }
        
        
        return nil
    }
}


open class ShoulderRangeOfMotion: InstrumentProtocol {
    
    var limbOption: ORKPredefinedTaskLimbOption!
    
    var usageDescription: String?
    
    required public init(limbOption: ORKPredefinedTaskLimbOption, usageDescription: String? = nil) {
        self.limbOption = limbOption
        self.usageDescription = usageDescription
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
        let task = ORKOrderedTask.shoulderRangeOfMotionTask(withIdentifier: ip_title, limbOption: limbOption, intendedUseDescription: usageDescription, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        
        if let motionResult = result.stepResult(forStepIdentifier: "shoulder.range.of.motion")?.firstResult as? ORKRangeOfMotionResult {
            
            // TODO:
            // Account for BodySite location.
            let observation = Observation.sm_RangeOfMotion(start: motionResult.start, finish: motionResult.finish, range: motionResult.range, date: motionResult.endDate)
            observation.bodySite = CodeableConcept.sm_BodySiteShoulder()
            let bID = "urn:uuid:\(UUID().uuidString)"
            let entry = BundleEntry()
            entry.fullUrl = FHIRURL(bID)
            entry.resource = observation
            entry.request = BundleEntryRequest(method: .POST, url: FHIRURL("Observation")!)
            let bundle = SMART.Bundle()
            bundle.entry = [entry]
            bundle.type = BundleType.transaction
            return bundle
            
        }
        return nil
        
    }
}

