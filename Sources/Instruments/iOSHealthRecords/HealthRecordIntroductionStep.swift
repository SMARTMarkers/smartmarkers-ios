//
//  HealthRecordIntroductionStep.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 2/24/21.
//  Copyright © 2021 Boston Children's Hospital. All rights reserved.
//

import Foundation
import HealthKit
import ResearchKit


@available(iOS 12.0, *)
open class HealthRecordIntroductionStep {
    
	public static func Create<T: ORKStep>(identifier: String, title: String?, text: String?, learnMoreBulletText: String?, learnMoreText: String?, learnMoreTitle: String?, bodyItems: [ORKBodyItem]?, requestedClinicalRecordTypes: [HKClinicalTypeIdentifier]?) -> T {
        if requestedClinicalRecordTypes != nil && !requestedClinicalRecordTypes!.isEmpty {
			
            
            let requestedItems = bodyItems ?? requestedClinicalRecordTypes!.map { $0.asBodyItem }
			
            // main step
            let introductionStep = SMInstructionStep(identifier: identifier)
            introductionStep.title = title
			introductionStep.text = text
            
            // Learn more about data being requested
			let learnMoreStep: SMLearnMoreInstructionStep?
			learnMoreStep = SMLearnMoreInstructionStep(identifier: identifier+"_learnMore")
			learnMoreStep?.title = learnMoreTitle ?? title
			learnMoreStep?.text = learnMoreText
			learnMoreStep?.bodyItems = requestedItems
			/*
			TODO:
			iOS 15: Test out text, attributed string
			*/
			
			var stepBodyItems = [ORKBodyItem]()
//			if let learnMoreStep = learnMoreStep {
//				let learnMoreItem = ORKLearnMoreItem(text: learnMoreBulletText ?? "Learn more", learnMoreInstructionStep: learnMoreStep)
//
//				stepBodyItems.append(ORKBodyItem(text: nil, detailText: nil, image: nil, learnMoreItem: learnMoreItem, bodyItemStyle: .text))
//			}
            stepBodyItems.append(contentsOf: requestedItems)
			
			stepBodyItems.append(contentsOf: [
				ORKBodyItem.init(horizontalRule: ()),
				ORKBodyItem(text: nil, detailText: nil, image: nil, learnMoreItem: HealthRecords.linkInstructionsAsLearnMoreItem(), bodyItemStyle: .text)
			])
			
			introductionStep.bodyItems = stepBodyItems
			
			return introductionStep as! T			
        }
        else {
            return HealthRecordIntroductionRequestStep(identifier: identifier, title: title, text: text) as! T
        }
    }
}


@available(iOS 12.0, *)
class HealthRecordIntroductionRequestStep: ORKQuestionStep {
    
    public required init(identifier: String, title: String?, text: String?) {
        super.init(identifier: identifier)
        self.text = text
        self.title = title
        self.question = "Select the type for clinical record"
        self.isOptional = false
        let choices = [
            HKClinicalTypeIdentifier.vitalSignsChoice,
            HKClinicalTypeIdentifier.ImmunizationChoice,
            HKClinicalTypeIdentifier.AllergiesChoice,
            HKClinicalTypeIdentifier.LabRecordChoice,
            HKClinicalTypeIdentifier.ConditionsChoice,
            HKClinicalTypeIdentifier.MedicationsChoice,
            HKClinicalTypeIdentifier.ProceduresChoice
        ]
        let answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: .multipleChoice, textChoices: choices)
        self.answerFormat = answerFormat
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}


@available(iOS 12.0, *)



class HealthRecordIntroductionNoticeStep: ORKTableStep {
    
    public required init(identifier: String, title: String?, text: String?, requestedClinicalRecordTypes: [HKClinicalTypeIdentifier]) {
        super.init(identifier: identifier)
        self.title = title
        self.text = text
        self.bodyItems = requestedClinicalRecordTypes.map { $0.asBodyItem }
		self.bulletType = .number
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

