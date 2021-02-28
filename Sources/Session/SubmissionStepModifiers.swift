//
//  StepModifiers.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 2/25/21.
//  Copyright © 2021 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit


class ReviewStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        let task = step.task as! SubmissionTask
        (step as! SMSubmissionPermitStep).formItems = task.session.tasks.map ({ $0.sm_asFormItem() })
    }
}

class ConsentStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let selected = taskResult.stepResult(forStepIdentifier: kSM_Submission_Review) else {
            return
        }
        let task = step.task as! SubmissionTask
        if let selectedTasksIdentifiers = selected.results?.compactMap({ (result) -> String? in
            let result = result as! ORKChoiceQuestionResult
            if let taskIds = result.answer as? [String] {
                return taskIds.first
            }
            return nil
        }) {
            let submissionNotice = "\(selectedTasksIdentifiers.count) Selected\n\nWill be submitted to: \(task.session.server!.name ?? "FHIR Server") at \(task.session.server!.baseURL.host ?? ""). Proceed?"
            step.text = submissionNotice
        }
    }
}

open class SMSubmissionErrorNoticeModifier: ORKStepModifier {
    
    open override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
     
        let task = step.task as! SubmissionTask
        if let result = taskResult.stepResult(forStepIdentifier: kSM_Submission_InProgress)?.results?.last as? ORKBooleanQuestionResult {
            let skip = result.booleanAnswer == 1
            if !skip {
                let rule = ORKDirectStepNavigationRule(destinationStepIdentifier: kSM_Submission_Review)
                task.setNavigationRule(rule, forTriggerStepIdentifier: step.identifier)
                
            }
        }
    }
    
}


extension TaskController {
    
    func sm_asFormItem() -> ORKFormItem {
        
        let reportChoices = reports?.sm_asTextChoiceAnswerFormat()
        let formItem = ORKFormItem(identifier: instrument?.sm_title ?? "#", text: instrument?.sm_title, answerFormat: reportChoices)
        formItem.isOptional = true
        return formItem
    }
}

extension Reports {
    
    func sm_asTextChoiceAnswerFormat() -> ORKTextChoiceAnswerFormat? {
        
        guard !submissionQueue.isEmpty else {
            return nil
        }
        
        let choices = submissionQueue.map { (gr) -> ORKTextChoice in
            let content = gr.bundle.sm_ContentSummary()! + "\n\nStatus: \(gr.status)" + "\nTaskId: \(gr.taskId)"
                let count  = gr.bundle.sm_resourceCount()

            
            return ORKTextChoice(text: "#\(count) Resources", detailText: content, value: gr.taskId as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
        }
        
        return ORKTextChoiceAnswerFormat(style: .multipleChoice, textChoices: choices)
    }
}
