//
//  QuestionnaireResponse+Report.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/4/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension QuestionnaireResponse : Report {
    
    public var rp_identifier: String? {
        return id?.string ?? ""
    }
    
    public var rp_code: Coding? {
        return nil
    }
    
    public var rp_title: String? {
        return "Response #\(id?.string ?? "-")"
    }
    
    public var rp_description: String? {
        return "QuestionnaireResponse ID: \(id?.string ?? "-")"
    }
    
    public var rp_date: Date {
        return authored?.nsDate ?? Date()
    }
    
    public var rp_observation: String? {
        return nil
    }
    
    public var rp_viewController: UIViewController? {
        return QuestionnaireResponseViewController(self)
    }
    
}
