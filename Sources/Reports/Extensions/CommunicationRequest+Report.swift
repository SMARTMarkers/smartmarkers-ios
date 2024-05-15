//
//  CommunicationRequest+Report.swift
//  PPMG
//
//  Created by Raheel Sayeed on 04/08/21.
//

import SMART
import SMARTMarkers

extension CommunicationRequest: Report {
	
	public var rp_identifier: String? {
		id?.string
	}
	
	public var rp_title: String? {
		"Discussion Communication"
	}
	
	public var rp_code: Coding? {
		
		reasonCode?.first?.coding?.first
	}
	
	public var rp_description: String? {
		nil
	}
	
	public var rp_date: Date? {
		occurrenceDateTime?.nsDate
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

/**
PPMG specific methods
*/
extension CommunicationRequest {
	
	/// Lists recommendations
	func ppmg_Recommendations() -> [String]? {
		return payload?.compactMap { $0.contentString?.string }
	}
}
