//
//  TappingSpeedPRO.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 4/19/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class TappingSpeedPRO: ActiveInstrumentProtocol {
    
    var handOption: ORKPredefinedTaskHandOption!
    
    var duration: TimeInterval!

    public init(hand: ORKPredefinedTaskHandOption, duration: TimeInterval = 60) {
        self.handOption = hand
        self.duration = duration
    }
    
    public var ip_taskDescription: String?
    
    public var ip_title: String {
        return "Tapping Speed Task"
    }
    
    public var ip_identifier: String {
        return "tappingspeed"
    }
    
    public var ip_code: Coding? {
        return Coding.sm_ResearchKit(ip_identifier, "Tapping Speed Task")
    }
    
    public var ip_version: String?
    
    public var ip_resultingFhirResourceType: [PROFhirLinkRelationship]?
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let task = ORKOrderedTask.twoFingerTappingIntervalTask(withIdentifier: ip_identifier, intendedUseDescription: ip_taskDescription, duration: duration, handOptions: handOption, options: [])
        let taskViewController = ORKTaskViewController(task: task, taskRun: UUID())
        callback(taskViewController, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        if let tappingSpeedResults = result.stepResult(forStepIdentifier: ip_identifier)?.results {
            print(tappingSpeedResults)
        }
        return nil
    }
    
    
    
    
    
}
