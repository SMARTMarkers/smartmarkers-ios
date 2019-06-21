//
//  QuestionnaireItemStep.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 5/23/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

public enum QuestionnaireItemExtensionType {
    
    case calculatedExpression
    
    case variable
}


public protocol QuestionnaireItemStepProtocol {
    
    /**
     Assigned Variable for Each Step: Defined in FHIR
     http://hl7.org/fhir/StructureDefinition/variable
    */
    
    var stepIdentifier: String { get }
    
    var type: String? { get set }
    
    
    var variable: String? { get set }
    
    /**
     Calculable Expression
    */
    var variableExpression: String? { get set }
    
    
    var calculatedExpression: String? { get set }
    
    
    var calculationResult: String? { get }
    
    
    var calculatedDescription: String? { get set }
    
    var isCalculationNeeded: Bool { get }
    
    
    var result: ORKResult? { get }
    
    func calculate(from result: ORKTaskResult, variables: [String: String]?) -> Decimal?
    
    init?(_ item: QuestionnaireItem) throws
    
}

public extension QuestionnaireItemStepProtocol where Self : ORKStep {
    
    
    init?(_ item: QuestionnaireItem) throws {
        
        let linkId = item.linkId!.string
        self.init(identifier: linkId)
        self.type = item.type?.rawValue
        
        if let _ = item.extension_fhir {
            do {
                try configureExtension(type: .calculatedExpression, item: item)
            }
            
        }
        
        if let slf = self as? ORKQuestionStep {
            
            if let q = item.rk_text() {
                slf.question = q
            }
            else {
                throw SMError.instrumentQuestionnaireMissingText(linkId: linkId)
            }
            
        }
        
        if let slf = self as? ORKInstructionStep {
            
            if let q = item.rk_InstructionText() {
                slf.text = q
            }
            else {
                throw SMError.instrumentQuestionnaireMissingText(linkId: linkId)
            }
        }
        
    }
    
    var stepIdentifier: String {
        return identifier
    }
    
    mutating func configureExtension(type: QuestionnaireItemExtensionType, item: QuestionnaireItem) throws {
        
        if let calculationExtension = item.extensions(forURI: kSD_QuestionnaireCalculatedExpression)?.first {
            guard let expression = calculationExtension.valueExpression, let expStr = expression.expression?.string else {
                throw SMError.instrumentQuestionnaireMissingCalculatedExpression(linkId: item.linkId!.string)
            }
            self.calculatedExpression = expStr
            self.calculatedDescription = expression.description_fhir?.string
        }
    }
    
    mutating func configureExtension(type: QuestionnaireItemExtensionType, extensions: [Extension]) {
        
    }
    
    mutating func assignVariable(variable: String) {
        self.variable = variable
    }
    
    var isCalculationNeeded: Bool {
        return calculatedExpression != nil
    }
    
    func calculate(from result: ORKTaskResult, variables: [String: String]?) -> Decimal? {
        
        guard let exp = calculatedExpression else {
            return nil
        }
        
        var stepResults = [String: String]()
        
        if let variables = variables {
            for (key, value) in variables {
                if let stepResult = result.stepResult(forStepIdentifier: value)?.results?.first as? ORKNumericQuestionResult {
                    if let decimalAnswer = stepResult.numericAnswer?.stringValue {
                        stepResults[key] = decimalAnswer
                    }
                }
                
            }
        }
        
        
        print(stepResults)
        
        let parser = FHIRPathParser(exp, .math)
        parser.calculate(stepResults)
        
        return nil
    }
}

public class QuestionnaireItemInstructionStep: ORKInstructionStep, QuestionnaireItemStepProtocol {
    public var type: String?
    
    public var calculatedDescription: String?
    
    public var variable: String?
    
    public var variableExpression: String?
    
    public var calculatedExpression: String?
    
    public var calculationResult: String?
    
    public var result: ORKResult?
    
    
}

public class QuestionnaireItemStep: ORKQuestionStep, QuestionnaireItemStepProtocol {
    public var type: String?

    public var calculatedDescription: String?
    
    public var variable: String?
    
    public var variableExpression: String?
    
    public var calculatedExpression: String?
    
    public var calculationResult: String?
    
    public var result: ORKResult?
    
    
    
}

public class QuestionnaireFormStep: ORKFormStep, QuestionnaireItemStepProtocol {
    
    public var type: String?
  
    public var calculatedDescription: String?
    
    public var variable: String?
    
    public var variableExpression: String?
    
    public var calculatedExpression: String?
    
    public var calculationResult: String?
    
    public var result: ORKResult?
    
    
}
