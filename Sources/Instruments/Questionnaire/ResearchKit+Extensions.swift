//
//  ResearchKit+Extensions.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 1/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit



extension ORKTextChoice {
    
    class func sm_AnswerChoice(system: String?, code: String, display: String?, displayText: String? = nil, detailText: String? = nil) -> ORKTextChoice? {
        
        let displayStr = displayText ?? display ?? code
        let answer = (system ?? kDefaultSystem) + kDelimiter + code + kDelimiter + (display ?? "")
        let answerChoice = ORKTextChoice(text: displayStr, detailText: detailText, value: answer as NSCoding & NSCopying & NSObjectProtocol, exclusive: true)
        return answerChoice
    }

    
}
public extension ORKInstructionStep {
    
    convenience init(identifier: String, _title: String? = nil, _detailText: String? = nil) {
        self.init(identifier: identifier)
        title = _title
        detailText = _detailText

    }
    
}

public extension Array where Element == ORKStep {
    
    
    func sm_hasDuplicates() -> Bool {
        
        let crossRef = Dictionary(grouping: self, by: {$0.identifier})
        if  crossRef.filter ({ $1.count > 1}).count > 1 {
            return true
        }
        
        return false
    }
    
}
