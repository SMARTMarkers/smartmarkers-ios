//
//  RK+Enrollment.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


class EnrollmentTask: ORKNavigableOrderedTask {
    
    static var REGISTRATIONStep = "enrollment.step.registration"
    static var CONCLUSIONStep   = "enrollment.step.conclusion"
    static var PASSCODEStep     = "enrollment.step.passcode"
    static var PERMISSIONStep   = "enrollment.step.permissions"
    static var TASKID           = "enrollment.task"
    
    unowned var enrollment: Enrollment
    
    init(enrollment: Enrollment) {
        self.enrollment = enrollment
        let consentController = self.enrollment.consentController
        let eligibilityController = self.enrollment.eligibility
        
        
        
        var steps = [ORKStep]()
        var modifiers = [[String: ORKStepModifier]]()
        
        // ------ ELIGIBILITY STEPS -----
        do {
            let eligibility_steps = try eligibilityController!.createSteps()
            steps.append(contentsOf: eligibility_steps.steps)
            modifiers.append(eligibility_steps.modifiers)
        }
        catch {
            fatalError(error.localizedDescription)
        }
        
        // ------ CONSENT STEPS -----
        let consentSteps = consentController.createSteps()
        steps.append(contentsOf: consentSteps)
        

        // ------ ENROLLMENT STEPS -----
        // 1. registration step
        let estep = EnrollmentWaitStep(identifier: Self.REGISTRATIONStep)
        // 2. completionMesager
        let completionstep = NoBackButtonCompletionStep(identifier: Self.CONCLUSIONStep)
        steps.append(contentsOf: [estep, completionstep])
        // 3. passcode
        let passcodestep = ORKPasscodeStep(identifier: Self.PASSCODEStep, passcodeFlow: .create)
        passcodestep.title = "Please setup a passcode to access this app"
        passcodestep.isOptional = true
        steps.append(passcodestep)
        
        let permissions = ORKRequestPermissionsStep(identifier: Self.PERMISSIONStep, permissionTypes: [.notificationPermissionType([.alert, .badge])])
        steps.append(permissions)
        
        
        
        super.init(identifier: Self.TASKID, steps: steps)
        for dict in modifiers {
            for (stepIdentifier, modifier) in dict {
                self.setStepModifier(modifier, forStepIdentifier: stepIdentifier)
            }
        }
        self.setStepModifier(EnrollmentConclusionStepModifier(), forStepIdentifier: completionstep.identifier)
        self.steps.forEach({ $0.task = self })
    }
    
    
    override func appendSteps(_ additionalSteps: [ORKStep]) {
        additionalSteps.forEach({ $0.task = self })
        super.appendSteps(additionalSteps)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

/// Enrollment conclusion step. Is shown after participant has registered
open class EnrollmentConclusionStepModifier: ORKStepModifier {
    
    open override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        let task = step.task as! EnrollmentTask
        let isconsented = task.enrollment.consentController.isConsented
        
        if task.enrollment.isEnrolled {
                step.title = "You are enrolled!"
                step.text = "You are ready to participate in this study.\n\nTo get started, tap \"Next\" to create a passcode to securely access this app"
            task.removeSkipNavigationRule(forStepIdentifier: EnrollmentTask.PASSCODEStep)
            task.removeSkipNavigationRule(forStepIdentifier: EnrollmentTask.PERMISSIONStep)

        }
        else if isconsented == false {
            step.title = "Enrollment Aborted"
            step.text = "Agreeing to the share & signing consent is required to enroll in this study"
            task.setSkip(SkipStepRule(), forStepIdentifier: EnrollmentTask.PASSCODEStep)
            task.setSkip(SkipStepRule(), forStepIdentifier: EnrollmentTask.PERMISSIONStep)
        }
        else {
            step.title = "Issue"
            step.text = "There was an issue enrolling you into the study. Please try again later or contact the research team at ppm@hms.harvard.edu"
            task.setSkip(SkipStepRule(), forStepIdentifier: EnrollmentTask.PASSCODEStep)
            task.setSkip(SkipStepRule(), forStepIdentifier: EnrollmentTask.PERMISSIONStep)
        }
    }
}

class EnrollmentWaitStep: ORKWaitStep {
        
    override init(identifier: String) {
        super.init(identifier: identifier)
        title = "Enrolling,\nPlease wait..."
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func stepViewControllerClass() -> AnyClass {
        EnrollmentWaitStepViewController.self
    }
}



class EnrollmentWaitStepViewController: ORKWaitStepViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        let task = (self.step?.task as! EnrollmentTask)
        let enrollment = task.enrollment
        let consentController = enrollment.consentController
        
        consentController.handleResultAndMakePDF(from: taskViewController!.result, pdfRenderer: enrollment.pdfRenderer ?? ORKHTMLPDFPageRenderer()) { completed in
            guard completed == true || consentController.isConsented == true else {
                smLog("[Enrolling] >> Abrorted, consented=\(consentController.isConsented) completed=\(completed)")
                task.setSkip(SkipStepRule(), forStepIdentifier: EnrollmentTask.PASSCODEStep)
                callOnMainThread {
                    self.goForward()
                }
                return
            }
            
            enrollment.EnrollParticipant(_server: nil) { participant, error in
                if let error {
                    smLog("[ENROLLMENT]: Did not enroll with error \n\(error.localizedDescription)")
                }
                else if let participant = participant {
                    enrollment.participant = participant
                    enrollment.onSuccessfulEnrollment?(participant, nil)
                }
                callOnMainThread {
                    self.goForward()
                }
            }
        }
    }
}
