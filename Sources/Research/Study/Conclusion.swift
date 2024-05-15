//
//  Conclusion.swift
//  SMARTMarkers
//
//  Created by raheel on 4/15/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART



public class StudyConclusion {

    public static func createTask(manager: StudyManger, message: String?, futureContactMessage: String?, endMessage: String, dismissalDelegate: ORKTaskViewControllerDelegate) -> ORKTaskViewController {
        let task = ConclusionTask(manager: manager, futureContactMessage: futureContactMessage, conclusionMessage: message, endMessage: endMessage)
        let view = InstrumentTaskViewController(task: task, taskRun: UUID())
        view.delegate = dismissalDelegate
        return view
    }
    
}


public class ConclusionTask: ORKOrderedTask {
    
    class ConclusionWaitStep: ORKWaitStep {
        override func stepViewControllerClass() -> AnyClass {
            ConclusionWaitViewController.self
        }
    }
    
    class ConclusionWaitViewController: ORKWaitStepViewController {
        
        override var cancelButtonItem: UIBarButtonItem? {
            get { nil }
            set {     }
        }
        var manager: StudyManger! {
            (self.step?.task as! ConclusionTask).manager
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            let dispatch = DispatchSemaphore(value: 0)
            
            manager.participant?.status = .offStudy
            manager.participant?.updateStatusIfNeeded1(to: manager.writeServer, callback: { error in
                if let error = error {
                    smLog("[ERROR]: cannot inform Server of studyCompletion \(error)")
                }
                dispatch.signal()
            })
            dispatch.wait()
           
            goForward()
        }
    }
    
    class FutureContactSubmitStep: ORKWaitStep {
        
        override var allowsBackNavigation: Bool {
            false
        }
        override func stepViewControllerClass() -> AnyClass {
            FutureContactSubmitStepViewController.self
        }
    }
    class FutureContactSubmitStepViewController: ORKWaitStepViewController {
        
        override var cancelButtonItem: UIBarButtonItem? {
            get { nil }
            set {     }
        }
        var manager: StudyManger! {
            (self.step?.task as! ConclusionTask).manager
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let contactResult = self.taskViewController?.result.stepResult(forStepIdentifier: "futureContact")?.firstResult else {
                goForward()
                return
            }
                
            let shouldContact: Bool
            let emailaddress: String?
            if let email = (contactResult as? ORKTextQuestionResult)?.textAnswer {
                shouldContact = true
                emailaddress = email
            }
            else if let shouldCon = (contactResult as? ORKBooleanQuestionResult)?.booleanAnswer?.boolValue {
                shouldContact = shouldCon
                emailaddress = nil
            }
            else {
                shouldContact = false
                emailaddress = nil
            }
            
            let dispatch = DispatchSemaphore(value: 0)
            
            guard 
                let srv = manager.writeServer,
                let flag = manager.createFlagForContact(preference: shouldContact, email: emailaddress) else {
                goForward()
                return
            }
            
            flag.createAndReturn(srv) { subErr in
                
                if let subErr = subErr {
                    smLog("[StudyCompleteTask]: Error flagging futureContact preference: \(subErr.localizedDescription)")
                }
                else {
                    smLog("[StudyCompleteTask]: FutureContact preference/Flag recorded")
                }
                dispatch.signal()
            }
            
            dispatch.wait()
            goForward()
        }
    }
    
    unowned var manager: StudyManger!
    
    public init(manager: StudyManger, futureContactMessage: String?, conclusionMessage: String?, endMessage:String?) {
        self.manager = manager
        
        var steps = [ORKStep]()
        
        let waitStep = ConclusionWaitStep(identifier: "study.conclusion.wait_step")
        waitStep.title = "Please wait"
        waitStep.text = "Study is complete, please keep the app open while we wrap up"
        steps.append(waitStep)

        
        if let futureContactMessage {
            let contactFuture = PPMGQuestionStep(identifier: "futureContact")
            contactFuture.title = "Thank you for participating in this study"
            contactFuture.showCancelButton = false
            var question = futureContactMessage
            if manager.participant?.contactEmail == nil {
                question += "\n\nIf yes, please enter your email address"
                contactFuture.answerFormat = ORKEmailAnswerFormat()
            }
            else {
                contactFuture.answerFormat = .booleanAnswerFormat()
            }
            contactFuture.question = question
            contactFuture.allowBackNav = false
            
            let contactFutureWait = FutureContactSubmitStep(identifier: "study.conclusion.futureContact")
            steps.append(contactFuture)
            steps.append(contactFutureWait)
        }
        
        if let conclusionMessage {
            let instructionStep = NoBackButtonCompletionStep(identifier: "study.conclusion.instruction_step")
            instructionStep.title = "All study tasks have been completed"
            instructionStep.text = conclusionMessage
            steps.append(instructionStep)
        }
        
        if let endMessage {
            let endStep = PPMGInstructionStep(identifier: "nextsteps")
            endStep.rightButtonType = .doneButton
            endStep.attributedBodyString = endMessage.sm_htmlToNSAttributedString()!
            endStep.bodyItems = [.init(horizontalRule: ())]
            steps.append(endStep)
        }
        
        super.init(identifier: "study.conclusion.task", steps: steps)
        self.steps.forEach({ $0.task = self })
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
