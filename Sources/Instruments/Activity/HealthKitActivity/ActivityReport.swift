//
//  ActivityReport.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 10/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import SMART
import HealthKit

public protocol Activity: class {
    
    var type: ActivityType { get set }
    
    var period: ActivityPeriod? { get set }
    
    var showDateSelector: Bool { get set }
    
    var value: Any? { get set }
            
    func fetch(_ _store: HKHealthStore?, callback: @escaping ((Any?, Error?) -> Void))
}


extension Activity  {
    
    var showDateStep: Bool {
        
        if showDateSelector == false && period?.start != nil && period?.end != nil {
            return false
        }
        
        return true
    }
}

public struct ActivityPeriod {
    
    var start: Date?
    
    var end:   Date?
    
}


