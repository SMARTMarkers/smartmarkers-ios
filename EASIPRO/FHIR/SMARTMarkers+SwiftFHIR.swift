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

extension ServiceRequest {
	
    public func ep_coding(for system: String) -> Coding? {
        
        if let codeConcept = code {
            return codeConcept.ep_coding(for: system)
        }
        return nil
    }
	
	

}

public extension CodeableConcept {
    
    class func sm_ObservationCategorySurvey() -> CodeableConcept {
        return sm_From([Coding.sm_Coding("survey", "http://hl7.org/fhir/observation-category", "Survey")], text: "Survey")
    }
	
    func ep_coding(for systemURI: String) -> Coding? {
		return self.coding?.filter { $0.system?.absoluteString == systemURI }.first
	}
    
    class func sm_From(_ instrument: InstrumentProtocol) -> CodeableConcept? {
        
        if let coding = instrument.ip_code {
            return sm_From([coding], text: instrument.ip_title)
        }
        return nil
    }
    
    class func sm_From(_ codings: [Coding], text: String?) -> CodeableConcept {
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
    
    public func sm_resourceType() -> String {
        return type(of: self).resourceType
    }
    
    public func sm_prettyPrint() throws  {
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
    
    class func sm_Coding(_ code: String, _ system: String, _ display: String) -> Coding {
        let coding = Coding()
        coding.code = FHIRString(code)
        coding.display = FHIRString(display)
        coding.system = FHIRURL(system)
        return coding
    }
    
    class func sm_SNOMED(_ code: String, _ display: String) -> Coding {
        return sm_Coding(code, "http://snomed.info/sct", display)
    }
    
    class func sm_LOINC(_ code: String, _ display: String) -> Coding {
        return sm_Coding(code, "http://loinc.org", display)
    }
    
    class func sm_ResearchKit(_ code: String, _ display: String) -> Coding {
        return sm_Coding(code, "http://researchkit.org", display)
    }
    
    
}



public extension SMART.Bundle {
    
    class func sm_with(_ resources: [DomainResource]) -> SMART.Bundle {
        var entries = [BundleEntry]()
        for resource in resources {
            let entry = BundleEntry()
            let bID = "urn:uuid:\(UUID().uuidString)"
            entry.fullUrl = FHIRURL(bID)
            entry.resource = resource
            entry.request = BundleEntryRequest(method: .POST, url: FHIRURL(resource.sm_resourceType())!)
            entries.append(entry)
        }
        let bundle = SMART.Bundle()
        bundle.entry = entries
        bundle.type = BundleType.transaction
        return bundle
    }
}


