//
//  Report+DocumentReference.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/12/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

extension DocumentReference: Report {
    
    public var rp_code: Coding? {
        return nil
    }
    
    public var rp_identifier: String? {
        return id?.string
    }
    
    public var rp_title: String? {
		return
			content?.compactMap({ $0.attachment?.title?.string }).first ??
			description_fhir?.string
			
		
    }
    
    public var rp_description: String? {
        return type?.coding?.reduce(into: "", { (str, coding) in
            str += "#\(coding.code!.string): \(coding.system!.absoluteString)\n"
        })
    }
    
    public var rp_date: Date? {
        return date?.nsDate ?? meta?.lastUpdated?.nsDate
    }
    
    public var rp_observation: String? {
        return nil
    }
	
	@discardableResult
	public func sm_assign(patient: Patient) -> Bool {
		
		if let patientReference = try? patient.asRelativeReference() {
			subject = patientReference
			return true
		}
		
		return false
	}
    
}
