//
//  PROWaitStep.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/24/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

let kSubmission_step_waiting = "smartmarkers-submission-step-waiting"
let kSubmission_step_success = "smartmarkers-submission-step-success"
let kSubmission_step_fail = "smartmarkers-submission-step-fail"



class PROSubmissionWaitStep: ORKWaitStep {
    
    weak final var promeasure: PROMeasure!
    
    var settings: [String: String]? = nil
    
    convenience init(prom: PROMeasure, settings: [String:String]? = nil) {
        self.init(identifier: kSubmission_step_waiting)
        promeasure = prom
        self.settings = settings
        self.title = settings?["submission_title"] ?? "Submitting..."
        self.text =  settings?["submission_text"] ?? "Please wait while as result is submitted"
    }
    
    override func stepViewControllerClass() -> AnyClass {
        return PROSubmissionWaitStepViewController.self
    }
    
    
}

class PROSubmissionWaitStepViewController: ORKWaitStepViewController {
    
    var waitStep: PROSubmissionWaitStep {
        return step as! PROSubmissionWaitStep
    }
    
    var proMeasure: PROMeasure {
        return waitStep.promeasure
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        guard let task = self.taskViewController?.task, let result = self.taskViewController?.result else {
            return
        }
        
        if let bundle = proMeasure.instrument?.ip_generateResponse(from: result, task: task) {
            
        }
        
        
    }
    
    
    override func updateText(_ text: String) {
        self.taskViewController?.result
    }
    
    
    
}




public class TT {
    
    public class func VC() -> ORKTaskViewController {
        let steps = [
            PROSubmissionWaitStep(identifier: kSubmission_step_waiting)
        ]
        let task = ORKNavigableOrderedTask(identifier: "task", steps: steps)
        let tvc = ORKTaskViewController(task: task, taskRun: UUID())
        return tvc
    }
}
