//
//  PROMeasure.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 28/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART





open class PROMeasure : Equatable {
    
    
    public enum Status {
        
        case completed
        case pending
        case failed
    }
    
    
    public static func ==(lhs: PROMeasure, rhs: PROMeasure) -> Bool {
        return (lhs.identifier == rhs.identifier)
    }
    
    
    open var measure: AnyObject?
    open var status : Status = .pending
    open var results : [DomainResource]?
    
    public init(measure: AnyObject) {
        self.measure = measure
    }
    
    open var title : String {
        get { return getTitle() }
    }
    
    open var identifier: String {
        get { return getIdentifier() }
    }
    
    open func getTitle() -> String {
        return measure?.description ?? "---"
    }
    
    open func getIdentifier() -> String {
        return "---"
    }
    
    
}


open class PROQuestionnaire: PROMeasure {
    
    override open func getTitle() -> String {
        if let measure = measure as? Questionnaire {
            return measure.ep_displayTitle()
        }
        else {
            return "FHIR Questionnaire"
        }
    }
    
    override open func getIdentifier() -> String {
        
        if let measure = measure as? Questionnaire {
            return measure.id!.string
        }
        else {
            return "FHIR Identifier"
        }
    }
}


extension Questionnaire {
    
    /// Best possible title for the Questionnaire
    public func ep_displayTitle() -> String {
        
        if let title = self.title {
            return title.string
        }
        
        if let identifier = self.identifier {
            for iden in identifier {
                if let value = iden.value {
                    return value.string
                }
            }
        }
        
        if let codes = self.code {
            for code in codes {
                if let display = code.display {
                    return display.string
                }
            }
        }
        
        return self.id!.string
    }
    
    
}
