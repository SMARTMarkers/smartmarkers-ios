//
//  ReportProtocol+FHIR.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/4/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART




extension QuestionnaireResponse : ReportProtocol {
    
    public var rp_resourceType: String {
        return "QuestionnaireResponse"
    }
    
    public var rp_identifier: String? {
        return id?.string ?? ""
    }
    
    
    
    public var rp_title: String? {
        return "Response #\(id?.string ?? "-")"
    }
    
    public var rp_description: String? {
        if let questionnaire = questionnaire {
            return "Response For  \(questionnaire.url?.lastPathComponent)"
        }
        return "QuestionnaireResponse"
    }
    
    public var rp_date: Date {
        return authored?.nsDate ?? Date()
    }
    
    public var rp_observation: String? {
        return nil
    }
    
    public static func searchParam(from: [DomainResource.Type]?) -> [String : String]? {
        return nil
    }
    
}




extension Observation : ReportProtocol {
    
    public var rp_resourceType: String {
        return "Observation"
    }
    
    
    
    public var rp_identifier: String? {
        return id?.string
    }
    
    
    
    public var rp_title: String? {
        if let code = code?.text?.string {
            return code
        }
        
        return "Observation: #\(self.id?.string ?? "-")"
    }
    
    public var rp_description: String? {
        return "Observation [Survey]"
    }
    
    public var rp_date: Date {
        return effectiveDateTime?.nsDate ?? Date()
    }
    
    public var rp_observation: String? {
        return observationValueString()
    }
    
    public static func searchParam(from: [DomainResource.Type]?) -> [String : String]? {
        return nil
    }
    
    func observationValueString() -> String? {
        if let v = valueString?.string { return v }
        if let v = valueQuantity { return String(describing: v.value!) }
        return nil
    }
    
    
    
}

extension Media: ReportProtocol {
    
    public var rp_resourceType: String {
        return sm_resourceType()
    }
    
    
    public var rp_identifier: String? {
        return id?.string
    }
    
    
    public var rp_title: String? {
        return "Response #\(id?.string ?? "-")"
    }
    
    
    public var rp_description: String? {
        return "Media"
    }
    
    public var rp_date: Date {
        return content!.creation!.nsDate
    }
    
    public var rp_observation: String? {
        return nil
    }
    
    public static func searchParam(from: [DomainResource.Type]?) -> [String : String]? {
        return nil
    }
    
    
    
}
