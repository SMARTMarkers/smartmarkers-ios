//
//  SubmissionStep.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART



open class SMSubmissionPermitStep: ORKFormStep {
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        self.title = "Report Submission"
        self.text  = "New reports have been generated. Please select the ones to be generated.\nCaution: Unselected reports will be discarded."
        self.isOptional = false
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class SMSubmissionServerNotice: ORKQuestionStep {
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        self.title = "Report Submission"
        self.question = "Proceed?"
        self.answerFormat = ORKBooleanAnswerFormat()
        self.isOptional = false
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SMSubmissionInProgressStep: ORKWaitStep {
    
    
    override init(identifier: String) {
        super.init(identifier: identifier)
        self.title = "Submitting"
        self.text = "Please wait\nData is being submitted..."
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return SMSubmissionInProgressStepVeiwController.self
    }
}

class SMSubmissionInProgressStepVeiwController: ORKWaitStepViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateText("Please wait\nData is being submitted...")
        
        let submissionTask = taskViewController!.task as! SubmissionTask
        let session = submissionTask.session
        
        // Get the selected reports to submit from the review-step
        if let selected = taskViewController?.result.stepResult(forStepIdentifier: kSM_Submission_Review) {
            
            // Get selected tasks
            let selectedTasksIdentifiers = selected.results?.compactMap({ (result) -> String? in
                let result = result as! ORKChoiceQuestionResult
                if let taskIds = result.answer as? [String] {
                    return taskIds.first
                }
                return nil
            })
            
            //
            _ = session.tasks.compactMap { (taskController) -> [SubmissionBundle]? in
                var toSubmit = [SubmissionBundle]()
                selectedTasksIdentifiers?.forEach({ (taskId) in
                    if let sb = taskController.reports?.submissionBundle(for: taskId) {
                        sb.canSubmit = true
                        toSubmit.append(sb)
                    }
                })
                return toSubmit.isEmpty ? nil : toSubmit
            }
            
            let group = DispatchGroup()
            var submissionErrors = [Error]()
            for taskController in session.tasks {
                group.enter()
                taskController.reports!.submit(to: session.server!, patient: session.patient!, request: taskController.request) { (success, errors) in
                    if let errors = errors {
                        submissionErrors.append(contentsOf: errors)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let success = submissionErrors.isEmpty
                let submissionResult = ORKBooleanQuestionResult(identifier: kSM_Submission_Result)
                submissionResult.booleanAnswer = success ? 1 : 0
                self.addResult(submissionResult)
                self.goForward()
            }
        }
    }
}

open class SMSubmissionConclusionStep: ORKCompletionStep {
    
    public override var allowsBackNavigation: Bool {
        return false
    }
}



open class SMSubmissionErrorNotice: ORKInstructionStep {
    
    
    public override init(identifier: String) {
        
        super.init(identifier: identifier)
        self.title = "Submission Issue"
        self.text  = "Some errors were encountered while attempting to submit"
        self.detailText = "Please try again."
    }
    
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}




