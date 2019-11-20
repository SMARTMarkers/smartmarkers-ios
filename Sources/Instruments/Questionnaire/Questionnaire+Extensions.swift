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



extension QuestionnaireItem {
    
    func sm_questionItem_instructions() -> String? {
        return extensions(forURI: kSD_QuestionnaireInstruction)?.first?.valueString?.localized
    }
    
    func sm_questionItem_Help() -> String? {
        return extensions(forURI: kSD_QuestionnaireHelp)?.first?.valueString?.localized
    }
    
}

extension Coding {
    
    func sm_textAnswerChoice() -> ORKTextChoice? {
        
        guard let code = code?.string else {
            return nil
        }
        return ORKTextChoice.sm_AnswerChoice(system: system?.absoluteString, code: code, display: display?.string, displayText: nil, detailText: nil)
    }
}


extension ValueSet {

    public func rk_choiceAnswerFormat(style: ORKChoiceAnswerStyle = .singleChoice) -> ORKAnswerFormat? {
        
        var choices = [ORKTextChoice]()
        
        if let expansion = expansion?.contains {
            for option in expansion {
                if let textChoice = ORKTextChoice.sm_AnswerChoice(system: option.system?.absoluteString, code: option.code!.string, display: option.display?.string, displayText: option.display_localized) {
                    choices.append(textChoice)
                }
            }
        }
            
        else if let includes = compose?.include {
            for include in includes {
                include.concept?.forEach({ (concept) in
                    if let answerChoice = ORKTextChoice.sm_AnswerChoice(system: include.system?.absoluteString, code: concept.code!.string, display: concept.display?.string, displayText: concept.display_localized) {
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
