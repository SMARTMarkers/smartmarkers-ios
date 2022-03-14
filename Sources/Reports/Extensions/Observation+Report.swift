//
//  Observation+Report.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/12/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

extension Observation : Report {
    
    public var rp_code: Coding? {
        return code?.coding?.first
    }
    
    public var rp_resourceType: String {
        return "Observation"
    }
    
    public var rp_identifier: String? {
        return id?.string
    }
    
    public var rp_title: String? {
        
        if let code = code {
            return code.text?.string ?? rp_code!.display?.string ?? "Code: \(rp_code!.code!.string)"
        }
        
        return "Observation: #\(self.id?.string ?? "-")"
    }
    
    public var rp_description: String? {
        
        let meta = category?.first?.coding?.first?.display ?? category?.first?.coding?.first?.code ?? ""
        return "Observation [\(meta)]"
    }
    
    public var rp_date: Date {
        return effectiveDateTime?.nsDate ?? Date()
    }
    
    public var rp_observation: String? {
        return sm_observationValue()
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


extension Observation {
    
    func sm_observationValue() -> String? {
        
        // valueString
        if let v = valueString?.string { return v }
        
        // valueQuantity
        if let v = valueQuantity { return String(describing: v.value!) }

        // Components
        if let components = component {
            if let q = components.first?.valueQuantity?.value {
                return q.description
            }
        }
        return nil
    }
    
    func bloodPressureDescription() -> String? {
        
        guard let components = component else { return nil }
        let v = components.reduce(into: String()) { (output, component) in
            if let vq = valueQuantity {
                output += String(describing: vq.value!)
                output += " " + (vq.unit?.string ?? vq.code?.string ?? "")
                output += ";"
            }
        }
        return v
    }
}
