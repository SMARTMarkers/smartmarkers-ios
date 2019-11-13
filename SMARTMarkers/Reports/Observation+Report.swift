//
//  Observation+Report.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/12/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

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
        
        let meta = category?.first?.coding?.first?.display ?? category?.first?.coding?.first?.code ?? ""
        return "Observation [\(meta)]"
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
