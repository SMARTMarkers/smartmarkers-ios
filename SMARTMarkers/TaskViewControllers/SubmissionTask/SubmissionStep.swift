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
        
        if let r = taskViewController?.result.stepResult(forStepIdentifier: kSM_Submission_Review) {
            
            let selectedTasks = r.results?.compactMap({ (result) -> String? in
                let result = result as! ORKChoiceQuestionResult
                if let taskIds = result.answer as? [String] {
                    return taskIds.first
                }
                return nil
            })
            
            let submissionBundles = submissionTask.session.measures.compactMap { (measure) -> [SubmissionBundle]? in
                
                var b = [SubmissionBundle]()
                selectedTasks?.forEach({ (taskId) in
                    if let sb = measure.reports?.submissionBundle(for: taskId) {
                        sb.shouldSubmit = true
                        b.append(sb)
                    }
                })
                
                return b.isEmpty ? nil : b
            }
            
           
            
            
            
            let group = DispatchGroup()
            var nerrors = [Error]()
            
            for measure in submissionTask.session.measures {
                group.enter()
                measure.reports!.submit(to: submissionTask.session.server!, consent: true, patient: submissionTask.session.patient!, request: nil) { (success, errors) in
                    if let errors = errors {
                        nerrors.append(contentsOf: errors)
                    }
                    group.leave()
                }
                
            }
            
            group.notify(queue: .main) {
                let success = nerrors.isEmpty
                let succesResult = ORKBooleanQuestionResult(identifier: kSM_Submission_Result)
                succesResult.booleanAnswer = success ? 1 : 0
                self.addResult(succesResult)
                self.goForward()
            }
        }

    }
    
    
    
    
    
}



open class SMSubmissionErrorNotice: ORKInstructionStep {
    
    
    public override init(identifier: String) {
        
        super.init(identifier: identifier)
        self.title = "Submission Issue"
        self.text  = "Some errors were encountered while attempting to submit"
        self.detailText = "Try .."
    }
    
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}




open class SMSubmissionErrorNoticeModifier: ORKStepModifier {
    
    open override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
     
        //todo
        let task = step.task as! SubmissionTask
        
        if let result = taskResult.stepResult(forStepIdentifier: kSM_Submission_InProgress)?.firstResult as? ORKBooleanQuestionResult {
            let skip = result.booleanAnswer == 1
            if !skip {
                let rule = ORKDirectStepNavigationRule(destinationStepIdentifier: kSM_Submission_Review)
                task.setNavigationRule(rule, forTriggerStepIdentifier: step.identifier)
            }
        }
    }
    
}





extension PROMeasure {
    
    func sm_asFormItem() -> ORKFormItem {
        
        let reportChoices = reports?.sm_asTextChoiceAnswerFormat()
        let formItem = ORKFormItem(identifier: instrument?.ip_title ?? "PRO #", text: instrument?.ip_title, answerFormat: reportChoices)
        formItem.isOptional = true
        return formItem
    }
}

extension Reports {
    
    func sm_asTextChoiceAnswerFormat() -> ORKTextChoiceAnswerFormat? {
        
        guard !submissionBundle.isEmpty else {
            return nil
        }
        
        let choices = submissionBundle.map { (gr) -> ORKTextChoice in
            let content = gr.bundle.sm_ContentSummary()! + "\n\nStatus: \(gr.status)" + "\nTaskId: \(gr.taskId)"
                let count  = gr.bundle.sm_resourceCount()

            
            return ORKTextChoice(text: "#\(count) Resources", detailText: content, value: gr.taskId as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
        }
        
        return ORKTextChoiceAnswerFormat(style: .multipleChoice, textChoices: choices)
    }
}
