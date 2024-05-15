//
//  RK+Eligibility.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit


// Eligibility Steps
public extension Eligibility {
    
    
    func createSteps() throws -> (steps: [ORKStep], modifiers: [String: ORKStepModifier]) {
        
        var steps = try self.criterias.map { try $0.createStep() }
        guard steps.count > 0 else {
            throw SMError.undefined(description: "Eligbility >> Cannot generate criteria steps")
        }
        let eligibilityIntro = PPMGInstructionStep(identifier: Self.SMARTMarkersEligibilityTaskIdentifier + ".introduction_step")
        eligibilityIntro.title = eligibilityTaskTitle
        eligibilityIntro.rightButtonType = .cancelButton
        eligibilityIntro.attributedBodyString = self.introduction
        if #available(iOS 13.0, *) {
            eligibilityIntro.iconImage = UIImage(systemName: "person.crop.circle.badge.checkmark")
        } else {
            // Fallback on earlier versions
        }
        steps.insert(eligibilityIntro, at: 0)
        
        let completionStep = SMCompletionStep(identifier: Self.SMARTMarkersEligibilityTaskIdentifier + ".completion_step", _title: eligibilityTaskTitle, _detailText: nil)
        steps.append(completionStep)
        
        let modifiers = [completionStep.identifier: EligibilityCompletionStepModifier()]
        
        return (steps, modifiers)
        
    }
    
    func checkIfEligibile(from result: ORKTaskResult) -> Bool {
                
        var eligible = true
        
        for criteria in criterias {
            if let cresult = result.stepResult(forStepIdentifier: criteria.identifier) {
                if let res = cresult.results?.first as? ORKBooleanQuestionResult {
                    if criteria.isSatistfied(by: EligibilityCriteriaAnswer(res.booleanAnswer!.boolValue)) == false {
                        eligible = false
                        break
                    }
                }
                else if let res = cresult.results?.first as? ORKNumericQuestionResult {
                    if criteria.isSatistfied(by: EligibilityCriteriaAnswer(res.numericAnswer!.decimalValue)) == false {
                        eligible = false
                        break
                    }
                }
            }
        }
        
        return eligible
    }
}



class EligibilityCompletionStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        let stp = step as! SMCompletionStep
        let task = step.task as! EnrollmentTask
        let eligibilityController = task.enrollment.study.eligibility!
        let consentor = task.enrollment.consentController
        let isEligible = eligibilityController.checkIfEligibile(from: taskResult)
        let stepIds = consentor.consentStepIdentifiers + [EnrollmentTask.PASSCODEStep, EnrollmentTask.REGISTRATIONStep, EnrollmentTask.PERMISSIONStep]

        if isEligible {
            
            smLog("[ENROLLMENT] Is Eligible --> Can proceed to next steps")
            stp.detailText = eligibilityController.eligibleMessage
            stp.title = "Ready to Enroll"
            stp.imgColor = .systemGreen
        
            // do not skip consenting or enrollment steps
    
            stepIds.forEach({
                task.removeSkipNavigationRule(forStepIdentifier: $0)
            })
        }
        else {
            
            smLog("[ENROLLMENT] In-Eligible!: skip all Consent Steps")
            stp.imgColor = .clear
            stp.iconImage = nil
            stp.image = nil
            stp.title = "Not Eligible"
            stp.detailText = eligibilityController.inEligibleMessage
            
            stepIds.forEach({
                task.setSkip(SkipStepRule(), forStepIdentifier: $0)
            })
        }
    }
}
public class SEligibilityTask: ORKNavigableOrderedTask {
    
}
extension Eligibility: ORKTaskViewControllerDelegate {
    
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: (any Error)?) {
      
        taskViewController.dismiss(animated: true) {
            self.eligibilityCheckCompletion?(self.is_eligible)
            self.eligibilityCheckCompletion = nil
        }
        
    }
}

extension EligibilityCriteria {
    
    public func createFormItem() throws -> ORKFormItem {
        guard let answerFormat = answerStepFormat() else {
            throw SMError.undefined(description: "cannot create ORKStep; AnswerFormat missing")
        }
        let q = ORKFormItem(identifier: identifier,
                            text: question,
                            detailText: nil,
                            learnMoreItem: nil,
                            showsProgress: false,
                            answerFormat: answerFormat,
                            tagText: nil,
                            optional: false)
        return q
    }
    
    public func createStep() throws -> ORKStep {
        
        guard let answerFormat = answerStepFormat() else {
            throw SMError.undefined(description: "cannot create ORKStep; AnswerFormat missing")
        }
        
        
        
        let learnMoreItem: ORKLearnMoreItem?
        if let learnMore = learnMore { // },  let _ = learnMore.ppmg_htmlToNSAttributedString() {
            /*
            // REALLY BAD HACK
            // ORKLEARNMOREINSTRUCTIONSTEP ATTRIBUTED STRING DOES NOT WORK
            // NO MATTER WHAT THE HACKS
            // MANUALLY INSERTING INSTRUCTION STEP HERE.
            */
            let learnMoreItem1 = HealthRecords.linkInstructionsAsLearnMoreItem()
            if #available(iOS 13.0, *) {
                learnMoreItem1.learnMoreInstructionStep.iconImage = UIImage(systemName: "doc.on.clipboard")
            } else {
                // Fallback on earlier versions
            }
            learnMoreItem = learnMoreItem1
            
            
        }
        else {
            learnMoreItem = nil
        }
        
        let qstep = PPMGQuestionStep(identifier: identifier)
        qstep.title = "Eligibility"
        qstep.question = question
        qstep.answerFormat = answerFormat
        qstep.learnMoreItem = learnMoreItem
        qstep.isOptional = false
        qstep.showCancelButton = true
        if #available(iOS 13.0, *) {
            qstep.iconImage = UIImage(systemName: "person.crop.circle.badge.checkmark")
        } else {
            // Fallback on earlier versions
        }

        return qstep
    }
    
    public func answerStepFormat() -> ORKAnswerFormat? {
        
        let answertype = type(of: requiredAnswer.answer.self)
        
        if answertype == Bool.self {
            return ORKAnswerFormat.booleanAnswerFormat()
        }
        
        return ORKNumericAnswerFormat(style: .integer, unit: "Years", minimum: 18, maximum:120, maximumFractionDigits: nil)
    }
}
