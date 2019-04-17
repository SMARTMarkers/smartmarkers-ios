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

public extension CodeableConcept {
	
	public func ep_coding(for systemURI: String) -> Coding? {
		return self.coding?.filter { $0.system?.absoluteString == systemURI }.first
	}
    
    public class func sm_From(_ codings: [Coding], text: String?) -> CodeableConcept {
        let cc = CodeableConcept()
        cc.coding = codings
        cc.text = text != nil ? FHIRString(text!) : nil
        return cc
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


public extension SMART.Coding {
    
    public class func sm_Coding(_ code: String, _ system: String, _ display: String) -> Coding {
        let coding = Coding()
        coding.code = FHIRString(code)
        coding.display = FHIRString(display)
        coding.system = FHIRURL(system)
        return coding
    }
    
    public class func sm_SNOMED(_ code: String, _ display: String) -> Coding {
        return sm_Coding(code, "http://snomed.info/sct", display)
    }
    
    public class func sm_LOINC(_ code: String, _ display: String) -> Coding {
        return sm_Coding(code, "http://loinc.org", display)
    }
    
    
    
}
