//
//  SMARTMarkers+SwiftFHIR.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 27/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit



let kSD_Variable = "http://hl7.org/fhir/StructureDefinition/variable"


/// Coding Systems - LOINC
let kLoincSystemKey = "http://loinc.org"
let kHL7ConditionVerificationStatus = "http://terminology.hl7.org/CodeSystem/condition-ver-status"
let kHL7ConditionClinicalStatus = "http://terminology.hl7.org/CodeSystem/condition-clinical"
let kHL7ObservationCategory = "http://terminology.hl7.org/CodeSystem/observation-category"


extension ValueSet {
    
    func asResearchKitBodyItem() -> ORKBodyItem? {
        
        ORKBodyItem(text: self.title?.string ?? self.name?.string, detailText: self.description_fhir?.string, image: nil, learnMoreItem: nil, bodyItemStyle: .bulletPoint)
    }
    func describeInHtml() -> String? {
        return title?.string
    }
}


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
	
    public func sm_coding(for system: String) -> Coding? {
        
        if let codeConcept = code {
            return codeConcept.sm_coding(for: system)
        }
        return nil
    }
	
	

}

public extension CodeableConcept {
    
    class func sm_RequestCode_EvaluationProcedure() -> CodeableConcept {
        return sm_From([Coding.sm_Coding("386053000", "http://snowmed.info/sct", "Evaluation procedure (procedure)")], text: "Evaluation procedure (procedure)")
    }
    
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

public extension SMART.Coding {
    
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
    
    func sm_DisplayRepresentation() -> String? {
        
        guard let code = code else { return nil }
        return display?.string ?? (system != nil ? "\(system!.absoluteString): \(code.string)" : code.string)
    }
    
    
    
}

public extension SMART.DomainResource {
    
     func sm_asBundleEntry() -> BundleEntry {
        let entry = BundleEntry()
        let uri = "urn:uuid:\(UUID().uuidString)"
        entry.fullUrl = FHIRURL(uri)
        entry.resource = self
        entry.request = BundleEntryRequest(method: .POST, url: FHIRURL(self.sm_resourceType())!)
        return entry
    }
}

public extension Array where Element: DomainResource {
    

    func sm_filter<ResourceType: DomainResource>(codes: [String]?, system: String?, surveyCode:String? = nil, surveySystem: String? = nil, type: SMART.ResourceType) -> [ResourceType]? {
 
                
        let filtered = filter { (resource) -> Bool in
            
            
            if let codes = codes, let system = system {
                
                let coding: [Coding]?
                
                if type.rawValue == "Observation", let resource = resource as? Observation {
                    coding = resource.code?.coding
                }
                else if type.rawValue == "Condition", let resource = resource as? Condition {
                    coding = resource.code?.coding
                }
                else if type.rawValue == "MedicationRequest", let resource = resource as? MedicationRequest {
                    coding = resource.medicationCodeableConcept?.coding
                }
                else if type.rawValue == "MedicationStatement", let resource = resource as? MedicationStatement {
                    coding = resource.medicationCodeableConcept?.coding
                }
                else if type.rawValue == "MedicationDispense", let resource = resource as? MedicationDispense {
                    coding = resource.medicationCodeableConcept?.coding
                }
                else if type.rawValue == "Medication", let resource = resource as? Medication {
                    coding = resource.code?.coding
                }
                else if type.rawValue == "QuestionnaireResponse", let resource = resource as? QuestionnaireResponse {
                    
                    if let q = resource.contained?.first as? Questionnaire {
                        coding = q.code
                    }
                    else  if
                        let qcode =  resource.identifier?.value,
                        let qsys  = resource.identifier?.system {
                        let codng = Coding()
                        codng.code = qcode
                        codng.system = qsys
                        coding = [codng]
                    }
                    else {
                        coding = nil
                    }
                }
                else {
                    coding = nil
                }
                
                if surveyCode != nil && surveySystem != nil && type.rawValue == "QuestionnaireResponse" {
                    let count = coding?.filter({
                                                $0.system!.absoluteString == surveySystem! &&
                                                    surveyCode == $0.code!.string }).count ?? 0
                    return count > 0
                }
                else {
                    let count = coding?.filter({
                                                $0.system!.absoluteString == system &&
                                                    codes.contains($0.code!.string) }).count ?? 0
                    return count > 0
                }
            }
            
            return true
            
        } as! [ResourceType]
        
        return filtered.count > 0 ? filtered : nil
    }
    

    
    func sm_Filter<D: DomainResource>(_  ofTypes: [D.Type], codes: [String], system: String) -> [DomainResource]? {

        let filtered = filter { (report) -> Bool in
            for typ in ofTypes {
                if let rep = report as? Report, typ.resourceType == rep.sm_resourceType(), let code = rep.rp_code {
                    let match = ((codes.contains(code.code!.string)) && (system == code.system!.absoluteString))
                    if match {
//                        smLog(try? code.asJSON())
                    }
                    return match
                    
                }
            }
            return false
        }
    
        
        return filtered
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


