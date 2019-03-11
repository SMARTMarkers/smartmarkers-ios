//
//  EASIPRO+SwiftFHIR.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 27/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension Appointment {
	
	public func ep_patientReferences() -> [String]? {
		
		guard let participant = participant else {
			return nil
		}
		
		var patientReferences = [String]()
		for p in participant {
			if let reference = p.actor, let referenceString = reference.reference, referenceString.string.contains("Patient/") {
				let fhirID = referenceString.string.components(separatedBy: "/")[1]
				patientReferences.append(fhirID)
			}
		}
		
		return (patientReferences.count > 0) ? patientReferences : nil
	}
}

extension ProcedureRequest {
	
    public func ep_coding(for system: String) -> Coding? {
        
        if let codeConcept = code {
            return codeConcept.ep_coding(for: system)
        }
        return nil
    }
	
	

}

extension CodeableConcept {
	
	public func ep_coding(for systemURI: String) -> Coding? {
		return self.coding?.filter { $0.system?.absoluteString == systemURI }.first
	}
}


extension Patient {
	
	public func ep_MRNumber() -> String {
		
		if let identifier = identifier {
			
			let filtered = identifier.filter({ (iden) -> Bool in
				if let mrCode = iden.type?.coding?.filter({ (coding) -> Bool in
					return coding.code?.string == "MR"
				}) {
					return mrCode.count > 0
				}
				return false
			})
			
			if filtered.count > 0, let mrIdentifier = filtered.first {
				return "MRN: \(mrIdentifier.value!.string.uppercased())"
			}
		}
		return "MRN: NA"
	}
	
}










extension SMART.DomainResource {
    
    public func prettyPrint() throws  {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: try self.asJSON(), options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        }
        catch {
            throw error
        }
    }
    
}
