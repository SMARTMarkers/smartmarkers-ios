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
        self.text  = "New reports have been generated. Please select the ones to be generated."
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
        
        if let r = taskViewController?.result.stepResult(forStepIdentifier: ksm_step_review) {
            let selectedReports = r.results!.compactMap({ (result) -> Reports in
                let result = result as! ORKChoiceQuestionResult
                let taskId = (result.answer as! [String]).first!
              
                let selected_reports = submissionTask.session!.measures.filter ({
                    $0.reports!.newGeneratedReports.contains(where: { (gr) -> Bool in
                        return gr.taskId == taskId
                    })
                }).map({ (prom) -> Reports in
                    prom.reports!
                }).first!
                
                return selected_reports

            })
            
            

            
            
            let group = DispatchGroup()
            var errors = [Error]()
            
            for report in selectedReports {
                group.enter()
                report.submit(to: submissionTask.session!.server!, consent: true, patient: submissionTask.session!.patient!, request: nil) { (success, error) in
                    if let error = error {
                        errors.append(error)
                    }
                    group.leave()
                }
                
            }
            
            group.notify(queue: .main) {
                if errors.isEmpty {
                    self.goForward()
                }
                
            }
        }

    }
    
    
    
    
    
}


open class SubmissionConsentStep: ORKVisualConsentStep {
    
    
    public override convenience init(identifier: String) {
        
        let document = ORKConsentDocument()
        let section1 = ORKConsentSection(type: .dataUse)
        section1.title = "Usage Title"
        section1.summary = "Summary about this consent section"
        section1.content = "The content to show in learn more .."
        document.sections = [section1]
        self.init(identifier: identifier, document: document)
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
        
        guard !newGeneratedReports.isEmpty else {
            return nil
        }
        
        let choices = newGeneratedReports.map { (gr) -> ORKTextChoice in
            let content = gr.bundle.sm_ContentSummary()!
                let count  = gr.bundle.sm_resourceCount()
                return ORKTextChoice(text: "Resources: \(count)", detailText: content, value: gr.taskId as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
        }
        
        return ORKTextChoiceAnswerFormat(style: .multipleChoice, textChoices: choices)
    }
}
