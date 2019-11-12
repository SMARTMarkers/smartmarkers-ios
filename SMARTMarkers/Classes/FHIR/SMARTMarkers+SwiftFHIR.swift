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
            return codeConcept.sm_coding(for: system)
        }
        return nil
    }
	
	

}

public extension CodeableConcept {
    
    class func sm_ObservationCategorySurvey() -> CodeableConcept {
        return sm_From([Coding.sm_Coding("survey", "http://hl7.org/fhir/observation-category", "Survey")], text: "Survey")
    }
	
    func sm_coding(for systemURI: String) -> Coding? {
		return self.coding?.filter { $0.system?.absoluteString == systemURI }.first
	}
    
    class func sm_From(_ instrument: Instrument) -> CodeableConcept? {
        
        if let coding = instrument.sm_code {
            return sm_From([coding], text: instrument.sm_title)
        }
        return nil
    }
    
    class func sm_From(_ codings: [Coding], text: String?) -> CodeableConcept {
        let cc = CodeableConcept()
        cc.coding = codings
        cc.text = text != nil ? FHIRString(text!) : nil
        return cc
    }
    
    class func sm_Activity() -> CodeableConcept {
        
        let activity = Coding.sm_Coding("activity", kHL7ObservationCategory, "Activity")
        return CodeableConcept.sm_From([activity], text: "Activity")
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








extension SMART.Resource {
    
    public func sm_resourceType() -> String {
        return type(of: self).resourceType
    }
    
    @discardableResult
    public func sm_jsonString() throws -> String?  {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: try self.asJSON(), options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }
        catch {
            throw error
        }
        return nil
    }

}

extension SMART.Coding {
    
    class func sm_Coding(_ code: String, _ system: String, _ display: String?) -> Coding {
        let coding = Coding()
        coding.code = code.fhir_string
        coding.display = display?.fhir_string
        coding.system = FHIRURL(system)
        return coding
    }
    
    class func sm_SNOMED(_ code: String, _ display: String) -> Coding {
        return sm_Coding(code, "http://snomed.info/sct", display)
    }
    
    class func sm_LOINC(_ code: String, _ display: String) -> Coding {
        return sm_Coding(code, "http://loinc.org", display)
    }
    
    class func sm_ResearchKit(_ code: String, _ display: String?) -> Coding {
        return sm_Coding(code, "http://researchkit.org", display)
    }
    
    func sm_searchableToken() -> String? {
        
        guard let code = code else { return nil }
        return system != nil ? "\(system!.absoluteString)|\(code.string)" : code.string
    }
    
    
}

extension SMART.DomainResource {
    
    func sm_asBundleEntry() -> BundleEntry {
        let entry = BundleEntry()
        let uri = "urn:uuid:\(UUID().uuidString)"
        entry.fullUrl = FHIRURL(uri)
        entry.resource = self
        entry.request = BundleEntryRequest(method: .POST, url: FHIRURL(self.sm_resourceType())!)
        return entry
    }
}

extension SMART.BundleEntry {
    
    func sm_asReference() -> Reference {
        let reference = Reference()
        reference.reference = "\((self.resource as! DomainResource).sm_resourceType())/\(self.fullUrl!.absoluteString)".fhir_string
        return reference
    }
    
}



extension SMART.Bundle {
    
    class func sm_with(_ resources: [DomainResource]) -> SMART.Bundle {
        let bundle = SMART.Bundle()
        bundle.entry = resources.map { $0.sm_asBundleEntry() }
        bundle.type = BundleType.transaction
        return bundle
    }
}


