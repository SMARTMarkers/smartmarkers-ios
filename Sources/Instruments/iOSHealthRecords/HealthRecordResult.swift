//
//  HKClinicalRecordResult.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import HealthKit
import ResearchKit

class HealthRecordResult: ORKResult {
    
    var records: [HKClinicalRecord]?
    
    required convenience init(clinicalType: HKClinicalType, records: [HKClinicalRecord]) {
        self.init(identifier: clinicalType.identifier)
        self.records = records
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(records as Any, forKey: "healthRecords")
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let result = super.copy(with: zone) as! HealthRecordResult
        result.records = records
        return result
    }
}

