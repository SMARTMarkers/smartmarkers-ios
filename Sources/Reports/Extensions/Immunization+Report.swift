//
//  Immunization+Report.swift
//  Concord
//
//  Created by Alex Leighton on 11/5/20.
//  Copyright © 2020 Boston Children's Hospital. All rights reserved.
//

import SMARTMarkers
import Foundation
import SMART

extension Immunization : Report {
    
    public var rp_code: Coding? {
        return vaccineCode?.coding?.first
    }
    
    public var rp_resourceType: String {
        return "Immunization"
    }
    
    public var rp_identifier: String? {
        return id?.string
    }
    
    public var rp_title: String? {
        
        if let vaccineCode = vaccineCode {
            return vaccineCode.text?.string ?? rp_code!.display?.string ?? "Code: \(rp_code!.code!.string)"
        }
        
        return "Immunization: #\(self.id?.string ?? "-")"
    }
    
    public var rp_description: String? {
        //Immunization doesn't really fit mold
        return "Immunization"
    }
    
    public var rp_date: Date? {
        return occurrenceDateTime?.nsDate
    }
    
    public var rp_observation: String? {
        return doseQuantity?.unit?.string
    }
	
	@discardableResult
	public func sm_assign(patient: Patient) -> Bool {
		
		if let patientReference = try? patient.asRelativeReference() {
			self.patient = patientReference
			return true
		}
		
		return false
	}
}
