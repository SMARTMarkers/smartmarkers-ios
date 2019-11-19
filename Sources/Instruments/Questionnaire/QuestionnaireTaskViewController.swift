//
//  QuestionnaireTaskViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 5/23/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit




open class QuestionnaireTaskViewController:  ORKTaskViewController {
    
    var variables: [String: String]?
        
    public class func GenerateController(for questionniare: Questionnaire, taskIdentifier: String? = nil, callback: @escaping ((QuestionnaireTaskViewController?, Error?) -> Void)) {
        
        questionniare.sm_genereteSteps { (steps, rulestupples, error) in
            
            if let steps = steps as? [QuestionnaireItemStepProtocol] {
                let uuid = UUID()
                let _taskIdentifier = taskIdentifier ?? uuid.uuidString
                let task = ORKNavigableOrderedTask(identifier: _taskIdentifier, steps: (steps as! [ORKStep]))
                rulestupples?.forEach({ (rule, linkId) in
                    task.setSkip(rule, forStepIdentifier: linkId)
                })
                let controller = QuestionnaireTaskViewController(task: task, taskRun: uuid)
                let variables = steps.filter({ $0.variable != nil})
                if !variables.isEmpty {
                    var vardict = [String: String]()
                    for v in variables {
                        vardict.updateValue(v.stepIdentifier, forKey: v.variable!)
                    }
                    controller.variables = vardict
                }
                callback(controller, nil)
            }
            else {
                callback(nil, nil)
            }
        }
    }
    
}
