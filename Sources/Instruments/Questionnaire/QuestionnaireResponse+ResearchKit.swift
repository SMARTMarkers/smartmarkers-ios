//
//  QuestionnaireResponse+ResearchKit.swift
//  SMARTMarkers
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
        let allQuestionnaireItems = questionnaire?.allItemsRecursively()
        let questionnaireItemForStep = allQuestionnaireItems?.first(where: { $0.linkId?.string == identifier })

        //Create all `QuestionnaireResponseItems` for this stepResult
        var stepAnswerItems = [QuestionnaireResponseItem]()
        for result in results {
            if let res = result as? ORKQuestionResult {
                let resultStepIdentifer = res.identifier
                let type = allQuestionnaireItems?.filter({ $0.linkId?.string == resultStepIdentifer }).first?.type
                let answer = res.sm_FHIRQuestionResult(for: type)
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
            groupItem.extension_fhir = questionnaireItemForStep?.extension_fhir
            items.append(groupItem)
            return items
        }
        
        // Single Step: Has only One Item
        else if let question = step as? ORKQuestionStep, stepAnswerItems.count == 1 {
            stepAnswerItems.first?.text = question.question?.fhir_string
            return stepAnswerItems
        }
        

        return nil
    }
    
    

}


extension ORKQuestionResult {
    
    func sm_FHIRQuestionResult(for type: QuestionnaireItemType?) -> [QuestionnaireResponseItemAnswer]? {
        
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
        
        //Integer or Decimal
        if let slf = self as? ORKNumericQuestionResult {
            
            if let typ = type {
                if typ == .integer { return slf.sm_IntegerItemAnswer() }
                if typ == .decimal { return slf.sm_DecimalItemAnswer() }
            }
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
    
    func sm_DecimalItemAnswer() -> [QuestionnaireResponseItemAnswer]? {
        guard let numericAnswer = numericAnswer else {
            return nil
        }
        let answer = QuestionnaireResponseItemAnswer()
        answer.valueDecimal = FHIRDecimal(numericAnswer.decimalValue)
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
            return nil
        }
        
        var answers = [QuestionnaireResponseItemAnswer]()
        for choice in choices {
            let answer = QuestionnaireResponseItemAnswer()
            let components = choice.components(separatedBy: kDelimiter)
            
            
            if components.count < 2 {
                
                // valueString
                answer.valueString = components.first!.fhir_string
            }
            else {
                
                // valueCoding
                let system = components[0]
                let code = components[1]
                let display = (components.count > 2) ? components[2] : nil
                answer.valueCoding = Coding()
                answer.valueCoding!.system = FHIRURL(system)
                answer.valueCoding!.code = code.fhir_string
                answer.valueCoding!.display = display?.fhir_string
                
            }
            answers.append(answer)
        }
        return answers
    }
}



