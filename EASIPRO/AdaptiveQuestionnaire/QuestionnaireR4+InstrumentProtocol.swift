//
//  QuestionnaireR4+InstrumentProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


extension QuestionnaireR4 : InstrumentProtocol {
    
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        return nil
    }
    
    public var ip_title: String {
        return title?.string ?? id?.string ?? url?.url.lastPathComponent ?? "Missing Title"
    }
    
    public var ip_identifier: String {
        return id?.string ?? url?.url.absoluteString ?? UUID().uuidString
    }
    
    public var ip_code: Coding? {
        return nil
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public func ip_generateSteps(callback: @escaping (([ORKStep]?, Error?) -> Void)) {
        sm_generateResearchKitSteps { (steps, rules, error) in
                callback(steps, error)
        }
    }
    
    public func ip_navigableRules(for steps: [ORKStep]?, callback: (([ORKStepNavigationRule]?, Error?) -> Void)) {
        callback(nil, nil)
    }
    
    
    
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        sm_generateResearchKitSteps { (steps, rules, error) in
            if let steps = steps {
                
                let uuid = UUID()
                
//                let taskIdentifier = measure.prescribingResource?.resource?.pro_identifier ?? uuid.uuidString
                let taskIdentifier = measure.request?.rq_identifier ?? uuid.uuidString
                let base = "https://mss.fsm.northwestern.edu/AC_API/2018-10/"
                let usr  = "2F984419-5008-4E42-8210-68592B418233"
                let pass = "21A673E8-9498-4DC2-AAB6-07395029A778"
                let settings = [
                    "client_id" : usr,
                    "client_secret" : pass
                ]
                let server = AQServer(baseURL: URL(string: base)!, auth: settings)
                let taskViewController = AdaptiveQuestionnaireTaskViewController(questionnaire: self, server: server, _taskIdentifier: taskIdentifier, steps: steps)
                taskViewController.measure = measure
                callback(taskViewController, nil)
            }
            else {
                callback(nil, error)
            }
        }
    }
    
    public var ip_resultingFhirResourceType: [PROFhirLinkRelationship]? {
        return nil
    }
    
}



