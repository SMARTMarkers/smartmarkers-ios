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

public class HealthRecordResult: ORKResult {
    
    public var records: [HKClinicalRecord]?
    
    required convenience init(clinicalType: HKClinicalType, records: [HKClinicalRecord]) {
        self.init(identifier: clinicalType.identifier)
        self.records = records
    }
    
	public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(records as Any, forKey: "healthRecords")
    }
    
	public override func copy(with zone: NSZone? = nil) -> Any {
        let result = super.copy(with: zone) as! HealthRecordResult
        result.records = records
        return result
    }
	
	public class func From(taskResult: ORKTaskResult) -> [HealthRecordResult]? {
		
		return taskResult
			.stepResult(forStepIdentifier: ksm_healthrecord_step_authorization)?
			.results as? [HealthRecordResult]
	}
}

