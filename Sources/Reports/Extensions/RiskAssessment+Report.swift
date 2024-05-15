//
//  RiskAssessment+Report.swift
//  PPMG
//
//  Created by Raheel Sayeed on 04/08/21.
//



import SMART
import SMARTMarkers

extension RiskAssessment: Report {
	
	public var rp_identifier: String? {
		id?.string
	}
	
	public var rp_title: String? {
		let outcome = prediction?.first?.outcome
		return outcome?.text?.string ?? outcome?.coding?.first?.display?.string ?? rp_resourceType
	}
	
	public var rp_code: Coding? {
		code?.coding?.first
	}
	
	public var rp_description: String? {
		if let code = rp_code {
			return """
				RiskAssessment: #\(rp_identifier ?? "-")
				Code: \(code.code!.string) | \(code.system!.absoluteString)
				"""
		}
		return nil
	}
	
	public var rp_date: Date? {
		occurrenceDateTime?.nsDate ?? Date()
	}
	
	public var rp_observation: String? {
		if let prediction = prediction?.first?.probabilityDecimal?.decimal.description {
			return prediction
		}
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

/**
PPMG Specific Methods
*/
extension RiskAssessment {
	
	func ppmg_ASCVDScore() -> Double? {
		
		if let score = rp_observation {
			return Double(score)?.rounded(.toNearestOrAwayFromZero)
		}
		return nil
	}
	
	
}
