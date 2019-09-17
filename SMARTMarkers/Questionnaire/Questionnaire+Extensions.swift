//
//  Questionnaire+Extensions.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/13/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit



public func sm_AnswerChoice(system: FHIRURL?, code: FHIRString, display: FHIRString?, displayText: String? = nil, detailText: String? = nil) -> ORKTextChoice? {
    
    let displayStr = displayText ?? display?.string ?? code.string
    let answer = system?.absoluteString ?? kDefaultSystem + kDelimiter + code.string
    let answerChoice = ORKTextChoice(text: displayStr, detailText: detailText, value: answer as NSCoding & NSCopying & NSObjectProtocol, exclusive: true)
    return answerChoice
}



extension Coding {
    
    public func sm_textAnswerChoice() -> ORKTextChoice? {
        
        return sm_AnswerChoice(system: system, code: code!, display: display)
    }
}


extension ValueSet {

    public func rk_choiceAnswerFormat(style: ORKChoiceAnswerStyle = .singleChoice) -> ORKAnswerFormat? {
        
        var choices = [ORKTextChoice]()
        
        if let expansion = expansion?.contains {
            for option in expansion {
                if let textChoice = sm_AnswerChoice(system: option.system, code: option.code!, display: option.display, displayText: option.display_localized) {
                    choices.append(textChoice)
                }
            }
        }
            
        else if let includes = compose?.include {
            for include in includes {
                include.concept?.forEach({ (concept) in
                    if let answerChoice = sm_AnswerChoice(system: include.system, code: concept.code!, display: concept.display, displayText: concept.display_localized) {
                        choices.append(answerChoice)
                    }
                })
            }
        }
        
        if choices.count > 0 {
            return ORKAnswerFormat.choiceAnswerFormat(with: style, textChoices: choices)
        }
        
        return nil
    }
}
