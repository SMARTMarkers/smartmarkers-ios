//
//  QuestionnaireResponse+ResearchKit.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 7/14/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//
/*
    Place for ORKTaskResult --> QuestionnaireResponse creation
 
 */
import Foundation
import ResearchKit
import SMART




/*
 Modified with Permission From C3-PRO
 Created by Pascal Pfiffner on 6/26/15.
 Copyright © 2015 Boston Children's Hospital. All rights reserved.
 https://github.com/C3-PRO
 */




extension ORKStepResult {
    
    
    func c3_responseItems(for task: ORKTask) -> [QuestionnaireResponseItem]? {
        
        guard let results = results else {
            return nil
        }
        
        var items = [QuestionnaireResponseItem]()
        for result in results {
            if let result = result as? ORKQuestionResult {
                if let question = task.step!(withIdentifier: result.identifier) as? ORKQuestionStep, let answers = result.c3_responseItemAnswers(from: question) {
                    
                    let responseItem = QuestionnaireResponseItem(linkId: result.identifier.fhir_string)
                    responseItem.text = question.title?.fhir_string
                    responseItem.answer = answers
                    items.append(responseItem)
                }
                
                
            }
        }
        
        return items.count > 0 ? items : nil
    }

}


extension ORKQuestionResult {
    
    func c3_responseItemAnswers(from step: ORKQuestionStep?) -> [QuestionnaireResponseItemAnswer]? {
        
        //Choice
        if let slf = self as? ORKChoiceQuestionResult {
            return slf.c3_responseItems()
        }
        
        //Boolean
        if let slf = self as? ORKBooleanQuestionResult {
            return slf.sm_BooleanItemAnswer()
        }
        
        //Date
        if let slf = self as? ORKDateQuestionResult {
            return slf.sm_DateItemAnswer()
        }
        
        //Text
        if let slf = self as? ORKTextQuestionResult {
            return slf.sm_TextItemAnswer()
        }
        
        //Integer
        if let slf = self as? ORKNumericQuestionResult {
            return slf.sm_IntegerItemAnswer()
        }
        
        
        return nil
    }
}

extension ORKNumericQuestionResult {
    
    func sm_IntegerItemAnswer() -> [QuestionnaireResponseItemAnswer]? {
        guard let numericAnswer = numericAnswer else {
            return nil
        }
        let answer = QuestionnaireResponseItemAnswer()
        answer.valueInteger = FHIRInteger(integerLiteral: numericAnswer.intValue)
        return [answer]
    }
}


// TextAnswer --> QuestionnaireResponseItemAnswer
extension ORKTextQuestionResult {
    
    func sm_TextItemAnswer() -> [QuestionnaireResponseItemAnswer]? {
        guard let text = textAnswer else {
            return nil
        }
        
        let answer = QuestionnaireResponseItemAnswer()
        answer.valueString = FHIRString(text)
        return [answer]
    }
}

// ORKDate --> QuestionnaireResponseItemAnswer

extension ORKDateQuestionResult {
    
    // TODO: Take Calendar into consideration.
    func sm_DateItemAnswer() -> [QuestionnaireResponseItemAnswer]? {
        guard let date = dateAnswer else {
            return nil
        }
        let answer = QuestionnaireResponseItemAnswer()
        answer.valueDate = date.fhir_asDate()
        return [answer]
    }
    
}

// Boolean Answer

extension ORKBooleanQuestionResult {
    
    func sm_BooleanItemAnswer() -> [QuestionnaireResponseItemAnswer]? {
        guard let answer = booleanAnswer else {
            return nil
        }
        let qrAnswer = QuestionnaireResponseItemAnswer()
        qrAnswer.valueBoolean = FHIRBool(answer.boolValue)
        return [qrAnswer]
    }
    
}


extension ORKChoiceQuestionResult {
    
    func c3_responseItems() -> [QuestionnaireResponseItemAnswer]? {
        
        guard let choices = choiceAnswers as? [String] else {
            if let _ = choiceAnswers {
                print("exp choice question results to be strings")
            }
            return nil
        }
        
        var answers = [QuestionnaireResponseItemAnswer]()
        for choice in choices {
            let answer = QuestionnaireResponseItemAnswer()
            let splat = choice.components(separatedBy: kDelimiter)
            let system = splat[0]
            let code = (splat.count > 1) ? splat[1] : kDefaultAnserCode
            let display = (splat.count > 2) ? splat[2] : nil
            answer.valueCoding = Coding()
            answer.valueCoding!.system = FHIRURL(system)
            answer.valueCoding!.code = code.fhir_string
            answer.valueCoding!.display = display?.fhir_string
            answers.append(answer)
        }
        return answers
    }
}



