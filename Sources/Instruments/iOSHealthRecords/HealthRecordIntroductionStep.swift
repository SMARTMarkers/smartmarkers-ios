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
    
    public static func Create<T: ORKStep>(identifier: String, title: String?, text: String?, requestedClinicalRecordTypes: [HKClinicalTypeIdentifier]?) -> T {
        if requestedClinicalRecordTypes != nil && !requestedClinicalRecordTypes!.isEmpty {
            return HealthRecordIntroductionNoticeStep(identifier: identifier, title: title, text: text, requestedClinicalRecordTypes: requestedClinicalRecordTypes!) as! T
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
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

