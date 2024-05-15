//
//  MedicationStatement+Report.swift
//  PPMG
//
//  Created by Raheel Sayeed on 03/08/21.
//

import SMART
import SMARTMarkers


extension MedicationStatement: Report {
	
	public var rp_identifier: String? {
		id?.string
	}
	
	public var rp_title: String? {
        medicationCodeableConcept?.text?.string ??
        medicationCodeableConcept?.coding?.first?.display?.string
	}
	
	public var rp_code: Coding? {
		medicationCodeableConcept?.coding?.first
	}
	
	public var rp_description: String? {
		nil
	}
	
	public var rp_date: Date? {
        effectiveDateTime?.nsDate ?? effectivePeriod?.start?.nsDate
	}
	
	public var rp_observation: String? {
        nil
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
