//
//  EligbilityTask.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public extension GroupCharacteristic {
    
    /// Create Eligibility Criterias
    func sm_asEligibilityCriteria() throws -> EligibilityCriteria {
        
        guard let eligibilityQuestion = code?.text else {
            throw SMError.undefined(description: "Group Characteristic Question missing")
        }
        
        let eligibilityDisplayTitle = code?.coding?.first?.display?.string
        
        var required_answer: EligibilityCriteriaAnswer!
        
        if let boolean = valueBoolean {
            required_answer = EligibilityCriteriaAnswer(boolean.bool)
        }
        else if let range = valueRange {
            required_answer = EligibilityCriteriaAnswer(range)
        }
        else {
            throw SMError.undefined(description: "Unrecognized eligibility group value")
        }
        
        var criteria: EligibilityCriteriaType = .inclusion
        if let should_exclude = self.exclude?.bool, should_exclude == true {
            criteria = .exclusion
        }
        
        
        let ec = EligibilityCriteria(UUID().uuidString, title: eligibilityDisplayTitle, question: eligibilityQuestion.string, criteriaType: criteria, requiredAnswer: required_answer)
        
        
        if let learnMoreExt = extensions(forURI: "http://dbmi.hms.harvard.edu/fhir/group-learnMore")?.first?.valueString?.string {
            ec.learnMore = learnMoreExt
        }
        
        return ec
    }
    
}

extension SMART.Range: EligibilityCriteriaAnswerTypeBase {
    
    /// Returns if Eligibility Matches
    public func sm_eligibilityMatches(given answer: EligibilityCriteriaAnswerTypeBase) -> Bool {
        
        if let answered = answer as? Decimal {
            if let low = self.low?.value?.decimal, let high = self.high?.value?.decimal {
                if answered.isLess(than: low) || high.isLess(than: answered) {
                    return false
                }
                else {
                    return true
                }
            }
            else if let low = self.low?.value?.decimal {
                if answered.isLess(than: low) {
                    return false
                }
                else {
                    return true
                }
            }
            else if let high = self.high?.value?.decimal {
                if high.isLess(than: answered) {
                    return false
                }
                else {
                    return true
                }
            }
        }
        
        return false
    }
}

