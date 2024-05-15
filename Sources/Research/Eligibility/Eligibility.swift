//
//  Eligibility.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


open class Eligibility: NSObject {
    
    public static let SMARTMarkersEligibilityTaskIdentifier = "smartmarkers.eligibilitytask"
    
    public static let SMARTMarkersEligibilityCompletionStep = "smartmarkers.eligibilitytask.completion_step"

    public let groups: [Group]
    
    open lazy var introduction: NSAttributedString? = {
        if let introduction_text_html {
            return introduction_text_html.sm_htmlToNSAttributedString()
        }
        return nil
    }()
    
    var introduction_text_html: String?
    
    open var criterias = [EligibilityCriteria]()
    
    open var eligibilityTaskTitle = "Eligibility"
    
    open var eligbilityIntroductionMessage = "To enroll in this study, you will be asked a set of questions to determine if you fit the eligible population"
    
    open var eligibleMessage = "You are eligibile to enroll in the study"
    
    open var inEligibleMessage = "You are not eligible to enroll in this study as per the criteria.\n\nThank you for your interest in this study."
    
    open var eligibilityCheckCompletion: ((_ is_eligible: Bool) -> Void)?

    private var eligible: Bool?
    
    public var is_eligible: Bool {
        eligible ?? false
    }
    
    public init?(_ groups: [Group]) throws {
        var groupDescriptions = [String]()
        self.groups = groups
        for group in groups {
            guard let characteristics = group.characteristic else {
                throw SMError.undefined(description: "Group Characteristics missing")
            }
            
            self.criterias = try characteristics.map { try $0.sm_asEligibilityCriteria() }
            if let description = group.sm_description() {
                groupDescriptions.append(description)
            }
            guard criterias.count > 0 else {
                throw SMError.undefined(description: "Cannot create task: EligbilityCriterias missing")
            }
            
            // Todo:
            // Move .ppmg_JOIN to Generic framework
            let _characteristics = groups.first?.characteristic?
                .compactMap({ $0.code?.coding?.first?.display?.string })
                .map { "<li>\($0)<br/></li>" }
                .joined()
            
            let eligibility_description = "<p>Individuals meeting the following criteria are eligible to enroll in this study.</p><ul>\(_characteristics!)</ul>"
            
            
            self.introduction_text_html = eligibility_description
        }
    }
    
}



extension Group {
    
    func sm_description() -> String? {
        
        guard let characters = characteristic else {
            return nil
        }
        
        var str = characters.reduce(into: String()) { (string, c) in
            if let range = c.valueRange {
                string += "\(c.code!.text!.string): \(String(describing: range.low?.value ?? "")) - \(String(describing: range.high?.value ?? ""))\n"
            }
            if let bool = c.valueBoolean {
                string += "\(c.code!.text!.string): \(bool.bool ? "Yes" : "No")\n"
            }
        }
        str.removeLast()
        return str
    }
}
