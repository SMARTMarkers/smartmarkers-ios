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


public extension FHIRPrimitive {
	
	func sm_xhtmlAttributedText() -> NSAttributedString? {
		
		guard let xhtmlData = extensions(forURI: kSD_QuestionnaireItemRenderingXhtml)?.first?.valueString?.string.data(using: .utf8) else {
			return nil
		}
		
		if let attributedString = try? NSAttributedString(data: xhtmlData,
														  options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
			return attributedString
		}

		return nil
	}
}
extension QuestionnaireItem {
    
    func sm_questionItem_instructions() -> String? {
        return extensions(forURI: kSD_QuestionnaireInstruction)?.first?.valueString?.localized
    }
    
    func sm_questionItem_Help() -> String? {
        return extensions(forURI: kSD_QuestionnaireHelp)?.first?.valueString?.localized
    }
	
	
	func sm_questionItem_RegexPattern() -> String? {
		return extensions(forURI: kSD_QuestionnaireItemRegex)?.first?.valueString?.string
	}

    
    func IfWeightItem() -> ORKAnswerFormat? {
        
        if code?.first?.code?.string == kBodyWeightLoinc && code?.first?.system?.absoluteString == kLoincSystemKey {
            
            if let unit = itemUnit() {
                
                if unit.lowercased() == "kg" {
                    return ORKWeightAnswerFormat(measurementSystem: .metric)
                }
                else {
                    return ORKWeightAnswerFormat(measurementSystem: .local)
                }
            }
            // TODO: Check other Units?
            else {
                return ORKWeightAnswerFormat(measurementSystem: .local)
            }
        }
        return nil
    }
    
    func IfHeightItem() -> ORKAnswerFormat? {
        
        if code?.first?.code?.string == kBodyHeightLoinc && code?.first?.system?.absoluteString == kLoincSystemKey {
            
            if let unit = itemUnit() {
                
                if unit.lowercased() == "[in_i]" {
                    return ORKHeightAnswerFormat(measurementSystem: .USC)
                }
                // TODO: Check other Units?
                else {
                    return ORKHeightAnswerFormat(measurementSystem: .local)
                }
            }
            else {
                return ORKHeightAnswerFormat(measurementSystem: .local)
            }
        }
        return nil
    }
    
    
    func itemUnit() -> String? {
		if let coding = extensions(forURI: kSD_QuestionnaireUnitExtension)?.first?.valueCoding {
			return coding.display?.string ?? coding.code?.string
        }
        return nil
    }
    
}

extension Coding {
    
	func sm_textAnswerChoice(style: ORKChoiceAnswerStyle) -> ORKTextChoice? {
        
        guard let code = code?.string else {
            return nil
        }
		
		return ORKTextChoice.sm_AnswerChoice(
			system: system?.absoluteString,
			code: code,
			display: display?.localized,
			displayText: nil,
			detailText: nil,
			style: style
		)
    }
}


extension ValueSet {

    public func rk_choiceAnswerFormat(style: ORKChoiceAnswerStyle = .singleChoice) -> ORKAnswerFormat? {
        
        var choices = [ORKTextChoice]()
        
        if let expansion = expansion?.contains {
            for option in expansion {
                if let textChoice = ORKTextChoice.sm_AnswerChoice(system: option.system?.absoluteString, code: option.code!.string, display: option.display?.string, displayText: option.display_localized, style: style) {
                    choices.append(textChoice)
                }
            }
        }
            
        else if let includes = compose?.include {
            for include in includes {
                include.concept?.forEach({ (concept) in
                    if let answerChoice = ORKTextChoice.sm_AnswerChoice(system: include.system?.absoluteString, code: concept.code!.string, display: concept.display?.string, displayText: concept.display_localized, style: style) {
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
