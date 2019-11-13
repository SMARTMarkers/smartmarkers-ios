//
//  Media+Report.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/12/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension Media: ReportProtocol {
    
    public var rp_resourceType: String {
        return sm_resourceType()
    }
    
    
    public var rp_identifier: String? {
        return id?.string
    }
    
    
    public var rp_title: String? {
        return "Media #\(id?.string ?? "-")"
    }
    
    
    public var rp_description: String? {
        return type?.coding?.reduce(into: "", { (str, coding) in
            str += "#\(coding.code!.string): \(coding.system!.absoluteString)\n"
        })
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

