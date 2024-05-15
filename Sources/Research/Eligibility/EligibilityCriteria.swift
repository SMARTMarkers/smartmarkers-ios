//
//  EligibilityCriteria.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit

public enum EligibilityCriteriaType {
    case inclusion
    case exclusion
}

public protocol EligibilityCriteriaAnswerTypeBase  {

    func sm_eligibilityMatches(given answer: EligibilityCriteriaAnswerTypeBase) -> Bool
}


extension Bool: EligibilityCriteriaAnswerTypeBase {
    
    public func sm_eligibilityMatches(given answer: EligibilityCriteriaAnswerTypeBase) -> Bool {
        return self == answer as! Bool
    }
}

extension Decimal: EligibilityCriteriaAnswerTypeBase {
    
    public func sm_eligibilityMatches(given answer: EligibilityCriteriaAnswerTypeBase) -> Bool {
        return self == answer as! Decimal
    }
}


public class EligibilityCriteriaAnswer: Equatable {
   
    public let answer: EligibilityCriteriaAnswerTypeBase

    public static func == (lhs: EligibilityCriteriaAnswer, rhs: EligibilityCriteriaAnswer) -> Bool {
        return lhs.answer.sm_eligibilityMatches(given: rhs.answer)
    }
    
    public required init(_ answer: EligibilityCriteriaAnswerTypeBase) {
        self.answer = answer
    }
    
}

public class EligibilityCriteria {
    
    public let identifier: String
    
    public let title: String?
    
    public let criteriaType: EligibilityCriteriaType
    
    public let question: String
    
    public var learnMore: String?
    
    public let requiredAnswer: EligibilityCriteriaAnswer
   
    public var answered: EligibilityCriteriaAnswer?
    
    public func isSatistfied(by answer: EligibilityCriteriaAnswer) -> Bool {
        
        // Check answer type and compare
        var condition: Bool = false
        
        if requiredAnswer == answer {
            answered = answer
            condition = true
        }
        
        return (criteriaType == .inclusion) ? condition : !condition
    }
    
    public  init(_ identifier: String, title: String?, question: String, criteriaType: EligibilityCriteriaType, requiredAnswer: EligibilityCriteriaAnswer) {
        self.identifier = identifier
        self.question = question
        self.criteriaType = criteriaType
        self.requiredAnswer = requiredAnswer
        self.title = title
    }
    
 
}
