//
//  Condition+Report.swift
//  Concord
//
//  Created by Alex Leighton on 11/6/20.
//  Copyright © 2020 Boston Children's Hospital. All rights reserved.
//

import SMARTMarkers
import Foundation
import SMART

extension Condition : Report {
    
    public var rp_code: Coding? {
        return code?.coding?.first
    }
    
    public var rp_resourceType: String {
        return "Condition"
    }
    
    public var rp_identifier: String? {
        return id?.string
    }
    
    public var rp_title: String? {
		
		if let cconcept = code {
			if let text = cconcept.text { return text.string }
			if let coding = cconcept.coding?.first {
				return coding.display?.string ??  "Code: \(coding.code!.string)"
			}
		}
		
		if let iden = identifier?.first {
			if let title = iden.value?.string { return title }
		}
		
        return "Condition: #\(self.id?.string ?? "-")"
    }
    
    public var rp_description: String? {
        
        let meta = category?.first?.coding?.first?.display ?? category?.first?.coding?.first?.code ?? ""
        return "Condition [\(meta)]"
    }
    
    public var rp_date: Date? {
        return onsetDateTime?.nsDate
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
