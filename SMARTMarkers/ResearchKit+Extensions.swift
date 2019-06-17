//
//  ResearchKit+Extensions.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit


public extension ORKInstructionStep {
    
    convenience init(identifier: String, _title: String? = nil, _detailText: String? = nil) {
        self.init(identifier: identifier)
        title = _title
        detailText = _detailText

    }
    
}

public extension Array where Element == ORKStep {
    
    
    func hasDuplicates() -> Bool {
        
        let crossRef = Dictionary(grouping: self, by: {$0.identifier})
        if  crossRef.filter ({ $1.count > 1}).count > 1 {
            return true
        }
        
        return false
    }
    
}
