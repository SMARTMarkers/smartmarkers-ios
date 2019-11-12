//
//  Report+DocumentReference.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/12/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

extension DocumentReference: ReportProtocol {
    
    public var rp_identifier: String? {
        return nil
    }
    
    public var rp_title: String? {
        return "FHIR DocumentReference"
    }
    
    public var rp_description: String? {
        return nil
    }
    
    public var rp_date: Date {
        return Date()
    }
    
    public var rp_observation: String? {
        return nil
    }
    
    public static func searchParam(from: [DomainResource.Type]?) -> [String : String]? {
        return nil
    }
    
    
    
}
