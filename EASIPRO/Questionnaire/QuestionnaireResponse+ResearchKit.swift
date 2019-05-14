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
    
    func responseItems(for questionnaire: Questionnaire?, task: ORKTask) -> [QuestionnaireResponseItem]? {
        
        guard let results = results else {
            return nil
        }
        let stepIdentifer = identifier
        let step = task.step?(withIdentifier: stepIdentifer)
        var items = [QuestionnaireResponseItem]()
        
        var stepAnswerItems = [QuestionnaireResponseItem]()
        for result in results {
            if let res = result as? ORKQuestionResult, let answer = res.sm_FHIRQuestionResult() {
                let resultStepIdentifer = res.identifier
                let answerItem = QuestionnaireResponseItem(linkId: resultStepIdentifer.fhir_string)
                answerItem.answer = answer
                stepAnswerItems.append(answerItem)
            }
        }
        
        //Is this a FormStep?
        if let form = step as? ORKFormStep, stepAnswerItems.count > 0 {
            stepAnswerItems.forEach { (answerItem) in
                answerItem.text = form.formItems!.filter({ $0.identifier == answerItem.linkId!.string }).first!.text!.fhir_string
            }
            let groupItem = QuestionnaireResponseItem(linkId: identifier.fhir_string)
            groupItem.text = step?.title?.fhir_string
            groupItem.item = stepAnswerItems
            items.append(groupItem)
            return items
        }
        
            //Single Step: Has only One Item
        else if let question = step as? ORKQuestionStep, stepAnswerItems.count == 1 {
            stepAnswerItems.first?.text = question.question?.fhir_string
            return stepAnswerItems
        }
        

        return nil
    }
    
    

}


extension ORKQuestionResult {
    
    func sm_FHIRQuestionResult() -> [QuestionnaireResponseItemAnswer]? {
        
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



